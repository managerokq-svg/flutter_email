// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_message_page/src/page/message_pages/pages/group/group_controller.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:v_platform/v_platform.dart';

import '../../../../../v_chat_message_page.dart';
import '../../../../v_chat/v_socket_status_widget.dart';
import '../../../../widgets/app_bare/v_message_app_bare.dart';
import '../../../../widgets/app_bare/v_selection_app_bar.dart';
import '../../providers/message_provider.dart';
import '../../states/input_state_controller.dart';
import '../../states/selection_state_controller.dart';
import '../../widget_states/input_widget_state.dart';
import 'group_app_bar_controller.dart';

class VGroupView extends StatefulWidget {
  const VGroupView({
    super.key,
    required this.vRoom,
    required this.language,
    required this.vMessageConfig,
  });
  final VRoom vRoom;
  final VMessageConfig vMessageConfig;
  final VMessageLocalization language;

  @override
  State<VGroupView> createState() => _VGroupViewState();
}

class _VGroupViewState extends State<VGroupView> {
  late final VGroupController controller;
  StreamSubscription? _wallpaperSub;
  final _messageInputController = VMessageInputController();

  @override
  void initState() {
    super.initState();
    final provider = MessageProvider();
    controller = VGroupController(
      vRoom: widget.vRoom,
      vMessageConfig: widget.vMessageConfig,
      messageProvider: provider,
      scrollController: AutoScrollController(
        axis: Axis.vertical,
        suggestedRowHeight: 200,
      ),
      inputStateController: InputStateController(widget.vRoom),
      groupAppBarController: GroupAppBarController(
        messageProvider: provider,
        vRoom: widget.vRoom,
      ),
    );
    _wallpaperSub = VEventBusSingleton.vEventBus
        .on<VUpdateRoomWallpaperEvent>()
        .where((e) => e.roomId == widget.vRoom.id)
        .listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    controller.close();
    _wallpaperSub?.cancel();
    _messageInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roomSpecificTheme = isDark
        ? VMessageTheme.darkWithRoomId(widget.vRoom.id)
        : VMessageTheme.lightWithRoomId(widget.vRoom.id);

    return ListenableBuilder(
      listenable: _messageInputController,
      builder: (context, _) => PopScope(
        canPop: !_messageInputController.isEmojiShowing,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _messageInputController.isEmojiShowing) {
            _messageInputController.closeEmoji();
          }
        },
        child: Container(
        decoration: roomSpecificTheme.scaffoldDecoration,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: ObstructingBarWrapper(
            child: ValueListenableBuilder<SelectionState>(
              valueListenable: controller.selectionController,
              builder: (_, selectionState, __) {
                if (selectionState.isSelectionMode) {
                  return VSelectionAppBar(
                    selectedCount: selectionState.selectedIds.length,
                    onClose: controller.exitSelectionMode,
                    onDelete: () => _handleBatchDelete(context),
                    onForward: () => _handleBatchForward(context),
                  );
                }
                return ValueListenableBuilder<GroupAppBarStateModel>(
                  valueListenable: controller.groupAppBarController,
                  builder: (_, value, __) {
                    if (value.isSearching) {
                      return VSearchAppBare(
                        onClose: controller.onCloseSearch,
                        onSearch: controller.onSearch,
                        searchLabel: widget.language.search,
                      );
                    }
                    return VMessageAppBare(
                      room: widget.vRoom,
                      isCallAllowed: widget.vMessageConfig.isCallsAllowed,
                      memberCount: value.myGroupInfo.membersCount,
                      onCreateCall: (isVideo) {
                        controller.onCreateCall(context, isVideo);
                      },
                      totalOnline: value.myGroupInfo.totalOnline,
                      inTypingText: (context) => _inGroupText(value.typingModel),
                      language: widget.language,
                      onTitlePress: controller.onTitlePress,
                    );
                  },
                );
              },
            ),
          ),
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.vMessageConfig.showDisconnectedWidget)
                      VSocketStatusWidget(
                        connectingLabel: widget.language.connecting,
                        delay: Duration.zero,
                      ),
                    AdsBannerWidget(
                      isEnableAds: widget.vMessageConfig.isEnableAds,
                      adsId: VPlatforms.isAndroid
                          ? SConstants.androidBannerAdsUnitId
                          : SConstants.iosBannerAdsUnitId,
                    ),
                    Expanded(
                      child: MessageBodyStateWidget(
                        language: widget.language,
                        controller: controller,
                        roomType: widget.vRoom.roomType,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: InputWidgetState(
                  controller: controller,
                  language: widget.language,
                  isAllowSendMedia: widget.vMessageConfig.isSendMediaAllowed,
                  messageInputController: _messageInputController,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  /// Returns a string representation of the typing status in a group.
  String? _inGroupText(VSocketRoomTypingModel value) {
    if (_statusInText(value) == null) return null;
    return "${value.userName} ${_statusInText(value)!}";
  }

  /// Converts the typing status to a localized text.
  String? _statusInText(VSocketRoomTypingModel value) {
    switch (value.status) {
      case VRoomTypingEnum.stop:
        return null;
      case VRoomTypingEnum.typing:
        return widget.language.typing;
      case VRoomTypingEnum.recording:
        return widget.language.recording;
    }
  }

  void _handleBatchDelete(BuildContext context) async {
    final messages = controller.getSelectedMessages();
    if (messages.isEmpty) return;
    final l = <ModelSheetItem>[];
    final canDeleteFromAll = messages.every(
      (m) => m.isMeSender && !m.isAllDeleted && m.emitStatus.isServerConfirm,
    );
    if (canDeleteFromAll) {
      l.add(ModelSheetItem(title: widget.language.deleteFromAll, id: 1));
    }
    l.add(ModelSheetItem(title: widget.language.deleteFromMe, id: 2));
    final res = await VAppAlert.showModalSheetWithActions(
      content: l,
      context: context,
      cancelLabel: widget.language.cancel,
    );
    if (res == null) return;
    final provider = MessageProvider();
    for (final message in messages) {
      if (res.id == 1) {
        await provider.deleteMessageFromAll(message.roomId, message.id);
      } else {
        await provider.deleteMessageFromMe(message);
      }
    }
    controller.exitSelectionMode();
  }

  void _handleBatchForward(BuildContext context) async {
    final messages = controller.getSelectedMessages();
    if (messages.isEmpty) return;
    final roomIds = await VChatController.I.vNavigator.roomNavigator
        .toForwardPage(context, messages.first.roomId);
    if (roomIds == null) return;
    for (final roomId in roomIds) {
      for (final message in messages) {
        await forwardMessageToRoom(message, roomId);
      }
    }
    controller.exitSelectionMode();
  }
}
