// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/modules/chat_settings/chat_media_docs_voice/controllers/chat_media_controller.dart';
import 'package:super_up/app/modules/chat_settings/shared/media_item_actions.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart' as bubbles;
import 'package:v_chat_bubbles/v_chat_bubbles.dart';
import 'package:v_chat_message_page/v_chat_message_page.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

final _mentionRegex = RegExp(r"\[(@[^:]+):([^\]]+)\]");

class ChatMediaView extends StatefulWidget {
  const ChatMediaView({super.key, required this.roomId});

  final String roomId;

  @override
  State<ChatMediaView> createState() => _ChatMediaViewState();
}

class _ChatMediaViewState extends State<ChatMediaView> {
  late final ChatMediaController controller;

  @override
  void initState() {
    super.initState();
    controller = ChatMediaController(widget.roomId);
    controller.onInit();
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  int sharedValue = 0;
  final Map<int, Widget> logoWidgets = <int, Widget>{
    0: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(S.current.media),
    ),
    1: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(S.current.docs),
    ),
    2: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(S.current.links),
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SegmentedButton<int>(
          segments: [
            ButtonSegment<int>(
              value: 0,
              label: Text(S.current.media),
            ),
            ButtonSegment<int>(
              value: 1,
              label: Text(S.current.docs),
            ),
            ButtonSegment<int>(
              value: 2,
              label: Text(S.current.links),
            ),
          ],
          selected: {sharedValue},
          onSelectionChanged: (Set<int> newSelection) {
            setState(() {
              sharedValue = newSelection.first;
            });
          },
        ),
      ),
      body: SafeArea(
        child: VBubbleScope(
          config: bubbles.VBubbleConfig(
            translations: bubbles.VTranslationConfig(
              actionReply: S.current.reply,
              actionForward: S.current.forward,
              actionCopy: S.current.copy,
              actionDownload: S.current.download,
              actionDelete: S.current.delete,
              actionStar: S.current.star,
              deletedMessage: S.current.messageHasBeenDeleted,
            ),
            patterns: bubbles.VPatternConfig(
              enableLinks: true,
              enableEmails: true,
              enablePhones: true,
              enableMentions: true,
              customPatterns: [_buildMentionPattern()],
            ),
          ),
          callbacks: bubbles.VBubbleCallbacks(
            onPatternTap: (match) => _handlePatternTap(context, match),
            onTap: (messageId) => _handleFileTap(messageId),
            onTransferStateChanged: (messageId, action) =>
                _handleTransferAction(messageId, action),
            onMenuItemSelected: (messageId, item) =>
                _handleMenuItemSelected(messageId, item),
            onReaction: (messageId, emoji, action) {
              final message = _findMessageByLocalId(messageId);
              if (message != null) {
                ReactionController.toggleReaction(message, emoji);
              }
            },
            onReactionTap: (messageId, emoji, position) {
              final message = _findMessageByLocalId(messageId);
              if (message != null) {
                showReactionsDialog(
                  context: context,
                  roomId: message.roomId,
                  messageId: message.id,
                );
              }
            },
          ),
          menuItemsBuilder: (messageId, messageType, isMeSender) {
            final message = _findMessageByLocalId(messageId);
            if (message == null) return null;
            return buildContextMenuItems(
              message: message,
              includeReply: false,
              includeSelect: false,
            );
          },
          style: VBubbleStyle.telegram,
          child: ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) => VAsyncWidgetsBuilder(
              loadingState: controller.loadingState,
              successWidget: () {
                if (sharedValue == 0) {
                  //create grid view builder
                  return GridView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: controller.data.media.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: 1.1,
                    ),
                    itemBuilder: (context, index) {
                      final message = controller.data.media[index];
                      if (message.messageType.isImage) {
                        final imgMsg = message as VImageMessage;
                        final fileSource = imgMsg.data.fileSource;
                        final aspectRatio = imgMsg.data.height > 0
                            ? imgMsg.data.width / imgMsg.data.height
                            : 1.0;
                        return bubbles.VImageBubble(
                          messageId: imgMsg.localId,
                          isMeSender: imgMsg.isMeSender,
                          time: "",
                          imageFile: fileSource,
                          aspectRatio: aspectRatio,
                          progress: imgMsg.progress,
                          transferState: _mapTransferState(imgMsg),
                          status: MessageToBubbleMapper.mapStatus(imgMsg),
                          reactions: [],
                          replyTo:
                              MessageToBubbleMapper.mapReplyTo(imgMsg.replyTo),
                          forwardedFrom:
                              MessageToBubbleMapper.mapForwardedFrom(imgMsg),
                          isStarred: imgMsg.isStared,
                        );
                      }
                      final videoMsg = message as VVideoMessage;
                      final videoData = videoMsg.data;
                      final thumbImage = videoData.thumbImage;
                      double? aspectRatio;
                      if (thumbImage != null && thumbImage.height > 0) {
                        aspectRatio = thumbImage.width / thumbImage.height;
                      }
                      final videoSource = videoData.fileSource;
                      final videoFile = videoSource.isFromUrl &&
                              videoSource.fullNetworkUrl != null
                          ? VPlatformFile.fromUrl(
                              networkUrl: videoSource.fullNetworkUrl!)
                          : videoSource;
                      VPlatformFile? thumbnailFile;
                      if (thumbImage != null) {
                        final thumbSource = thumbImage.fileSource;
                        thumbnailFile = thumbSource.isFromUrl &&
                                thumbSource.fullNetworkUrl != null
                            ? VPlatformFile.fromUrl(
                                networkUrl: thumbSource.fullNetworkUrl!)
                            : thumbSource;
                      }
                      return bubbles.VVideoBubble(
                        messageId: videoMsg.localId,
                        isMeSender: videoMsg.isMeSender,
                        time: MessageToBubbleMapper.formatTime(
                            videoMsg.createdAtDate),
                        videoFile: videoFile,
                        thumbnailFile: thumbnailFile,
                        duration:
                            Duration(milliseconds: videoData.duration ?? 0),
                        aspectRatio: aspectRatio,
                        progress: videoMsg.progress,
                        transferState: _mapTransferState(videoMsg),
                        status: MessageToBubbleMapper.mapStatus(videoMsg),
                        reactions: MessageToBubbleMapper.mapReactions(videoMsg),
                        replyTo:
                            MessageToBubbleMapper.mapReplyTo(videoMsg.replyTo),
                        forwardedFrom:
                            MessageToBubbleMapper.mapForwardedFrom(videoMsg),
                        isStarred: videoMsg.isStared,
                      );
                    },
                  );
                } else if (sharedValue == 1) {
                  return ListView.separated(
                    padding: const EdgeInsets.all(10.0),
                    itemBuilder: (context, index) {
                      final message =
                          controller.data.files[index] as VFileMessage;
                      final fileSource = message.data.fileSource;
                      final file = fileSource.isFromUrl &&
                              fileSource.fullNetworkUrl != null
                          ? VPlatformFile.fromUrl(
                              networkUrl: fileSource.fullNetworkUrl!)
                          : fileSource;
                      return bubbles.VFileBubble(
                        messageId: message.localId,
                        isMeSender: message.isMeSender,
                        time: MessageToBubbleMapper.formatTime(
                            message.createdAtDate),
                        file: file,
                        progress: message.progress,
                        transferState: _mapTransferState(message),
                        status: MessageToBubbleMapper.mapStatus(message),
                        reactions: MessageToBubbleMapper.mapReactions(message),
                        replyTo:
                            MessageToBubbleMapper.mapReplyTo(message.replyTo),
                        forwardedFrom:
                            MessageToBubbleMapper.mapForwardedFrom(message),
                        isStarred: message.isStared,
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.grey),
                    itemCount: controller.data.files.length,
                  );
                } else {
                  return ListView.separated(
                    padding: const EdgeInsets.all(10.0),
                    itemBuilder: (context, index) {
                      final message = controller.data.links[index];
                      return LinkViewerWidget(
                        data: message.linkAtt,
                        isMeSender: message.isMeSender,
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const Divider(color: Colors.grey),
                    itemCount: controller.data.links.length,
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  bubbles.VTransferState _mapTransferState(VBaseMessage message) {
    if (message.isDownloading) {
      return bubbles.VTransferState.downloading;
    }
    if (message.emitStatus == VMessageEmitStatus.sending) {
      return bubbles.VTransferState.uploading;
    }
    if (message.emitStatus == VMessageEmitStatus.error) {
      return bubbles.VTransferState.error;
    }
    return bubbles.VTransferState.completed;
  }

  VFileMessage? _findFileByMessageId(String messageId) {
    try {
      return controller.data.files
          .whereType<VFileMessage>()
          .firstWhere((m) => m.localId == messageId);
    } catch (_) {
      return null;
    }
  }

  void _handleFileTap(String messageId) {
    final message = _findFileByMessageId(messageId);
    if (message == null) return;
    if (!message.emitStatus.isServerConfirm) return;
    if (VPlatforms.isMobile) {
      _handleDownloadForMobile(message);
    } else {
      _handleDownloadForWeb(message);
    }
  }

  void _handleTransferAction(
      String messageId, bubbles.VMediaTransferAction action) {
    final message = _findFileByMessageId(messageId);
    if (message == null) return;
    switch (action) {
      case bubbles.VMediaTransferAction.download:
        if (VPlatforms.isMobile) {
          VDownloaderService.instance.addToMobileQueue(message);
        } else {
          _handleDownloadForWeb(message);
        }
        break;
      case bubbles.VMediaTransferAction.cancel:
        // Cancel not implemented for now
        break;
      case bubbles.VMediaTransferAction.retry:
        if (VPlatforms.isMobile) {
          VDownloaderService.instance.addToMobileQueue(message);
        } else {
          _handleDownloadForWeb(message);
        }
        break;
    }
  }

  void _handleDownloadForMobile(VFileMessage message) async {
    if (message.isFileDownloaded) {
      await OpenFilex.open(
        VFileUtils.getLocalPath(message.localFilePathWithExt),
      );
      return;
    }
    VDownloaderService.instance.addToMobileQueue(message);
  }

  void _handleDownloadForWeb(VBaseMessage message) async {
    await vSafeApiCall<String>(
      onLoading: () {
        VAppAlert.showSuccessSnackBar(
          context: context,
          message: S.of(context).downloading,
        );
      },
      request: () async {
        return VDownloaderService.instance.addToQueue(message);
      },
      onSuccess: (url) async {
        VAppAlert.showSuccessSnackBar(
          message: S.of(context).success,
          context: context,
        );
      },
      onError: (exception) {},
    );
  }

  VBaseMessage? _findMessageByLocalId(String messageId) {
    try {
      // Search in media
      final mediaMatch = controller.data.media
          .where((m) => m.localId == messageId)
          .firstOrNull;
      if (mediaMatch != null) return mediaMatch;
      // Search in files
      final fileMatch = controller.data.files
          .where((m) => m.localId == messageId)
          .firstOrNull;
      if (fileMatch != null) return fileMatch;
      // Search in links
      final linkMatch = controller.data.links
          .where((m) => m.localId == messageId)
          .firstOrNull;
      return linkMatch;
    } catch (_) {
      return null;
    }
  }

  void _handleMenuItemSelected(String messageId, VBubbleMenuItem item) {
    final message = _findMessageByLocalId(messageId);
    if (message == null) return;
    handleMediaItemAction(
      context: context,
      action: item.id,
      message: message,
      onRefresh: controller.getData,
    );
  }

  bubbles.VCustomPattern _buildMentionPattern() {
    return bubbles.VCustomPattern(
      id: 'custom_mention',
      pattern: _mentionRegex,
      style: const TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
      valueTransformer: (match) {
        final result = _mentionRegex.firstMatch(match);
        return result?.group(1) ?? match;
      },
    );
  }

  void _handlePatternTap(BuildContext context, bubbles.VPatternMatch match) {
    switch (match.patternId) {
      case 'url':
        VStringUtils.lunchLink(match.matchedText);
        break;
      case 'email':
        VStringUtils.lunchEmail(match.matchedText);
        break;
      case 'phone':
        VStringUtils.lunchLink('tel:${match.matchedText}');
        break;
      case 'custom_mention':
        final result = _mentionRegex.firstMatch(match.rawText);
        final userId = result?.group(2);
        if (userId != null) {
          VChatController.I.vNavigator.messageNavigator.toUserProfilePage
              ?.call(context, userId);
        }
        break;
    }
  }
}
