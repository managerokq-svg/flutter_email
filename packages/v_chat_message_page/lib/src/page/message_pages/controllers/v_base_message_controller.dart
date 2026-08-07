// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:uuid/uuid.dart';
import 'package:v_chat_media_editor/v_chat_media_editor.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:v_platform/v_platform.dart';

import '../../../../v_chat_message_page.dart';
import '../../../controllers/reaction_controller.dart';
import '../pasteboard/file_convertor.dart';
import '../pasteboard/pasteboard.dart';
import '../states/input_state_controller.dart';
import '../states/message_state/message_state_controller.dart';
import '../states/selection_state_controller.dart';

abstract class VBaseMessageController extends MessageStateController
    with StreamMix {
  final focusNode = FocusNode();
  final vConfig = VChatController.I.vChatConfig;
  final InputStateController inputStateController;
  final events = VEventBusSingleton.vEventBus;
  final VMessageConfig vMessageConfig;
  final uuid = const Uuid();

  /// Selection state controller for multi-selection mode
  final SelectionStateController selectionController =
      SelectionStateController();

  VBaseMessageController({
    required super.vRoom,
    required super.messageProvider,
    required super.scrollController,
    required this.inputStateController,
    required this.vMessageConfig,
  }) {
    messageProvider.setSeen(roomId);
    VRoomTracker.instance.addToOpenRoom(roomId: roomId);
    _removeAllNotifications();
    _setUpVoiceController();
    _initMessagesStreams();
    _setUpPasteboardStreamListener();
  }

  StreamSubscription? clipboardSubscription;
  late final VVoicePlayerController voiceControllers;

  String get roomId => vRoom.id;
  final IPasteboard pasteboard = Pasteboard(FileConvertor());

  void onTitlePress(BuildContext context);

  void _setUpPasteboardStreamListener() {
    if (kIsWeb) clipboardSubscription = pasteboard.pasteBoardListener(onPaste);
  }

  @override
  void close() {
    focusNode.dispose();
    inputStateController.close();
    voiceControllers.close();
    selectionController.dispose();
    clipboardSubscription?.cancel();
    VRoomTracker.instance.closeOpenedRoom(roomId);
    closeStreamMix();
    super.close();
  }

  void _removeAllNotifications() async {
    await VChatController.I.vChatConfig.cleanNotifications();
  }

  void onOpenSearch() {
    inputStateController.hide();
  }

  void onCloseSearch() {
    inputStateController.unHide();
    resetMessages();
  }

  void onSearch(String value) async {
    messageSearch(value);
  }

  /// Enter selection mode with the given message selected
  /// Does not allow selection of one-seen or all-deleted messages
  void enterSelectionMode(VBaseMessage message) {
    if (message.isOneSeen || message.isAllDeleted) return;
    selectionController.enterSelectionMode(message.localId);
  }

  /// Toggle selection of a message
  /// Does not allow selection of one-seen or all-deleted messages
  void toggleMessageSelection(String messageId) {
    final message = value.firstWhereOrNull((m) => m.localId == messageId);
    if (message == null || message.isOneSeen || message.isAllDeleted) return;
    selectionController.toggleSelection(messageId);
  }

  /// Exit selection mode
  void exitSelectionMode() {
    selectionController.exitSelectionMode();
  }

  /// Get all selected messages
  List<VBaseMessage> getSelectedMessages() {
    return value
        .where((m) => selectionController.selectedIds.contains(m.localId))
        .toList();
  }

  void onSubmitMedia(
    BuildContext context,
    List<VPlatformFile> files,
  ) async {
    final fileRes = await context.toPage(
      VMediaEditorView(
        files: files,
        config: VMediaEditorConfig(
          imageQuality: vMessageConfig.compressImageQuality,
        ),
      ),
    ) as List<VBaseMediaRes>?;
    if (fileRes == null) return;
    for (var media in fileRes) {
      if (media is VMediaImageRes) {
        final x = VMessageImageData.fromMap(media.data.toMap());
        final localMsg = VImageMessage.buildMessage(
          roomId: vRoom.id,
          data: x,
        );
        _onSubmitSendMessage(localMsg);
      } else if (media is VMediaVideoRes) {
        final localMsg = VVideoMessage.buildMessage(
          data: VMessageVideoData.fromMap(media.data.toMap()),
          roomId: vRoom.id,
        );
        _onSubmitSendMessage(localMsg);
      } else if (media is VMediaFileRes) {
        final localMsg = VFileMessage.buildMessage(
          data: VMessageFileData.fromMap(media.data.toMap()),
          roomId: vRoom.id,
        );
        _onSubmitSendMessage(localMsg);
      }
    }
    scrollDown();
  }

  Future<void> onPaste(List<VPlatformFile> files) async {
    final fileRes = await context.toPage(VMediaEditorView(
      files: files,
      config: VMediaEditorConfig(
        imageQuality: vMessageConfig.compressImageQuality,
      ),
    )) as List<VBaseMediaRes>?;

    if (fileRes == null || fileRes.isEmpty) return;
    for (final file in fileRes) {
      if (file is VMediaImageRes) {
        _onSubmitSendMessage(
          VImageMessage.buildMessage(
            roomId: roomId,
            data: VMessageImageData.fromMap(
              file.data.toMap(),
            ),
          ),
        );
      }
      if (file is VMediaFileRes) {
        _onSubmitSendMessage(
          VFileMessage.buildMessage(
            roomId: roomId,
            data: VMessageFileData.fromMap(file.data.toMap()),
          ),
        );
      }
    }
  }

  void onSubmitVoice(VMessageVoiceData data) {
    final localMsg = VVoiceMessage.buildMessage(
      data: data,
      roomId: vRoom.id,
      content: VStringUtils.printDuration(data.durationObj),
    );
    _onSubmitSendMessage(localMsg);
    scrollDown();
  }

  void onSubmitFiles(List<VPlatformFile> files) {
    for (var file in files) {
      final localMsg = VFileMessage.buildMessage(
        data: VMessageFileData.fromMap(file.toMap()),
        roomId: vRoom.id,
      );
      _onSubmitSendMessage(localMsg);
      scrollDown();
    }
  }

  void onSubmitLocation(VLocationMessageData data) {
    final localMsg = VLocationMessage.buildMessage(
      data: data,
      roomId: vRoom.id,
    );
    _onSubmitSendMessage(localMsg);
    scrollDown();
  }

  void onSubmitSticker(Map<String, dynamic> sticker) {
    // 'url' contains the key (relative path like 'stickers/media600-xxx.jpg')
    // not the full URL, so we can send it directly to the backend
    final localMsg = VStickerMessage.buildMessage(
      roomId: vRoom.id,
      url: sticker['url'],
      stickerId: sticker['id'],
    );
    _onSubmitSendMessage(localMsg);
    scrollDown();
  }

  void onSubmitGif(Map<String, dynamic> gif) {
    final localMsg = VGifMessage.buildMessage(
      roomId: vRoom.id,
      url: gif['url'],
      aspectRatio: gif['aspectRatio'],
    );
    _onSubmitSendMessage(localMsg);
    scrollDown();
  }

  void onSubmitContacts(VContactMessageData data) {
    final localMsg = VContactMessage.buildMessage(
      data: data,
      roomId: vRoom.id,
    );
    _onSubmitSendMessage(localMsg);
    scrollDown();
  }

  void onTypingChange(VRoomTypingEnum typing) {
    if (typing == VRoomTypingEnum.recording) {
      _stopVoicePlayer();
    }
    final model = VSocketRoomTypingModel(
      status: typing,
      roomId: vRoom.id,
    );
    messageProvider.emitTypingChanged(model);
  }

  Future<void> _onSubmitSendMessage(VBaseMessage localMsg) async {
    localMsg.replyTo = inputStateController.value.replyMsg;
    await VChatController.I.nativeApi.local.message.insertMessage(localMsg);
    VMessageUploaderQueue.instance.addToQueue(
      await MessageFactory.createUploadMessage(localMsg),
    );
    inputStateController.dismissReply();
  }

  void onSubmitText(String message, VLinkPreviewData? previewData) {
    final isEnable = vConfig.enableEndToEndMessageEncryption;
    final localMsg = VTextMessage.buildMessage(
      content: isEnable ? VMessageEncryption.encryptMessage(message) : message,
      isEncrypted: isEnable,
      linkAtt: previewData,
      roomId: vRoom.id,
    );
    scrollDown();
    _onSubmitSendMessage(localMsg);
  }

  void scrollDown() {
    scrollController.animateTo(
      0.0,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> onHighlightMessage(VBaseMessage message) async {
    final i = value.indexOf(message);
    if (i == -1) {
      final x = await loadMoreMessages();
      if (x == null || x.isEmpty) {
        return;
      }
      onHighlightMessage(message);
    } else {
      _highlightTo(i);
    }
  }

  void _highlightTo(int index) {
    scrollController.scrollToIndex(
      index,
      preferPosition: AutoScrollPosition.end,
      duration: const Duration(milliseconds: 500),
    );
    scrollController.highlight(index);
  }

  void setReply(VBaseMessage p1) {
    focusNode.requestFocus();
    if (p1.emitStatus.isServerConfirm) {
      inputStateController.setReply(p1);
    }
  }

  void dismissReply() {
    inputStateController.dismissReply();
  }

  void onReSend(VBaseMessage message) async {
    VMessageUploaderQueue.instance.addToQueue(
      await MessageFactory.createUploadMessage(message),
    );
  }

  ///set to each controller
  Future<List<MentionModel>> onMentionRequireSearch(
    BuildContext context,
    String query,
  );

  void _setUpVoiceController() {
    voiceControllers = VVoicePlayerController(
      (localId) {
        final index = value.indexWhere((e) => e.localId == localId);
        if (index == -1 || index == 0) {
          return null;
        }
        if (!value[index - 1].messageType.isVoice) {
          return null;
        }
        return value[index - 1].localId;
      },
    );
  }

  ///----------------------------- Messages streams -----------------------------------------------------
  void _initMessagesStreams() {
    ///messages events
    streamsMix.addAll([
      events
          .on<VInsertMessageEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleOnNewMessage),
      events
          .on<VUpdateMessageEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleOnUpdateMessage),
      events
          .on<VDeleteMessageEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleOnDeleteMessage),
      events
          .on<VUpdateMessageDeliverEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleOnDeliverMessage),
      events
          .on<VUpdateMessageSeenEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleOnSeenMessage),
      events
          .on<VUpdateProgressMessageEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleUpdateProgress),
      events
          .on<VUpdateIsDownloadMessageEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleUpdateIsDownloading),
      events
          .on<VUpdateMessageStatusEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleOnUpdateMessageStatus),
      events
          .on<VUpdateMessageOneSeenEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleOnUpdateOneSeen),
      events
          .on<VUpdateMessageStarEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleUpdateStar),
      events
          .on<VUpdateMessageAllDeletedEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleOnAllDeleted),
      events
          .on<VUpdateMessageReactionsEvent>()
          .where((event) => event.roomId == vRoom.id)
          .listen(_handleUpdateMessageReactions),
    ]);
  }

  void _handleOnNewMessage(VInsertMessageEvent event) async {
    emitSeenFor(event.roomId);
    insertMessage(event.messageModel);
  }

  void _handleOnUpdateMessage(VUpdateMessageEvent event) async {
    updateMessage(event.messageModel);
  }

  void _handleOnDeleteMessage(VDeleteMessageEvent event) async {
    deleteMessage(event.localId);
  }

  void _handleOnDeliverMessage(VUpdateMessageDeliverEvent event) async {
    deliverAll(event.model);
  }

  void _handleOnSeenMessage(VUpdateMessageSeenEvent event) async {
    seenAll(event.model);
  }

  void _handleOnUpdateMessageStatus(VUpdateMessageStatusEvent event) async {
    updateMessageStatus(event.localId, event.emitState);
  }

  void _handleOnAllDeleted(VUpdateMessageAllDeletedEvent event) {
    updateMessageAllDeletedAt(event.localId, event.message.allDeletedAt);
  }

  void onGetClipboardImageBytes(Uint8List imageBytes) async {
    final fileRes = await context.toPage(VMediaEditorView(
      files: [
        VPlatformFile.fromBytes(
            bytes: imageBytes.toList(), name: "${uuid.v4()}.png")
      ],
      config: VMediaEditorConfig(
        imageQuality: vMessageConfig.compressImageQuality,
      ),
    )) as List<VBaseMediaRes>?;

    if (fileRes == null || fileRes.isEmpty) return;
    for (final e in fileRes) {
      if (e is VMediaImageRes) {
        _onSubmitSendMessage(
          VImageMessage.buildMessage(
            roomId: roomId,
            data: VMessageImageData.fromMap(e.data.toMap()),
          ),
        );
      }
    }
  }

  void _stopVoicePlayer() {
    voiceControllers.pauseAll();
  }

  void _handleUpdateStar(VUpdateMessageStarEvent event) {
    updateMessageStar(event.localId, event);
  }

  void _handleOnUpdateOneSeen(VUpdateMessageOneSeenEvent event) {
    updateMessageOneSeen(event.localId, event);
  }

  void _handleUpdateProgress(VUpdateProgressMessageEvent event) {
    updateDownloadProgress(event.localId, event.progress);
  }

  void _handleUpdateIsDownloading(VUpdateIsDownloadMessageEvent event) {
    updateIsDownloading(event.localId, event.isDownloading);
  }

  void handleMessageReaction(VBaseMessage message, String emoji) {
    ReactionController.toggleReaction(message, emoji);
  }

  void _handleUpdateMessageReactions(VUpdateMessageReactionsEvent event) {
    updateMessageReactions(event.localId, event);
  }
}
