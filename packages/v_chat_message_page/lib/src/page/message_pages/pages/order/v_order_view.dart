// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_message_page/src/page/message_pages/pages/order/v_order_controller.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

import '../../../../../v_chat_message_page.dart';
import '../../../../v_chat/v_socket_status_widget.dart';
import '../../../../widgets/app_bare/v_message_app_bare.dart';
import '../../../../widgets/app_bare/v_selection_app_bar.dart';
import '../../providers/message_provider.dart';
import '../../states/input_state_controller.dart';
import '../../states/selection_state_controller.dart';
import '../../widget_states/input_widget_state.dart';
import 'order_app_bar_controller.dart';

class VOrderView extends StatefulWidget {
  const VOrderView({
    super.key,
    required this.vRoom,
    required this.language,
    required this.vMessageConfig,
  });
  final VRoom vRoom;
  final VMessageConfig vMessageConfig;
  final VMessageLocalization language;

  @override
  State<VOrderView> createState() => _VOrderViewState();
}

class _VOrderViewState extends State<VOrderView> {
  late final VOrderController controller;
  final _messageInputController = VMessageInputController();

  @override
  void initState() {
    super.initState();
    final provider = MessageProvider();
    controller = VOrderController(
      vRoom: widget.vRoom,
      language: widget.language,
      vMessageConfig: widget.vMessageConfig,
      messageProvider: provider,
      scrollController: AutoScrollController(
        axis: Axis.vertical,
        suggestedRowHeight: 200,
      ),
      inputStateController: InputStateController(widget.vRoom),
      orderAppBarController: OrderAppBarController(
        vRoom: widget.vRoom,
        messageProvider: provider,
      ),
    );
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
                return ValueListenableBuilder<OrderAppBarStateModel>(
                  valueListenable: controller.orderAppBarController,
                  builder: (_, value, __) {
                    if (value.isSearching) {
                      return VSearchAppBare(
                        searchLabel: widget.language.search,
                        onClose: controller.onCloseSearch,
                        onSearch: controller.onSearch,
                      );
                    }
                    return VMessageAppBare(
                      isCallAllowed: widget.vMessageConfig.isCallsAllowed,
                      room: widget.vRoom,
                      inTypingText: (context) => _inSingleText(value.typingModel),
                      lastSeenAt: value.lastSeenAt,
                      onUpdateBlock: controller.onUpdateBlock,
                      onCreateCall: controller.onCreateCall,
                      language: widget.language,
                      onTitlePress: controller.onTitlePress,
                    );
                  },
                );
              },
            ),
          ),
          body: Container(
            decoration: context.vMessageTheme.scaffoldDecoration,
            child: Stack(
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
    ),
    );
  }

  String? _inSingleText(VSocketRoomTypingModel value) {
    return _statusInText(value);
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

  @override
  void dispose() {
    controller.close();
    _messageInputController.dispose();
    super.dispose();
  }
}
