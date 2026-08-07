// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart' as bubbles;
import 'package:v_chat_bubbles/v_chat_bubbles.dart';
import 'package:v_chat_message_page/src/core/core.dart';
import 'package:v_chat_message_page/src/page/message_pages/controllers/v_base_message_controller.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

import '../../../widgets/arrow_down.dart';
import '../../../widgets/drag_drop_if_web_desk.dart';
import '../../../widgets/message_items/v_message_item.dart';
import '../../message_pages/utils/date_format_utils.dart';
import '../states/selection_state_controller.dart';
import 'v_bubble_theme.dart';

class MessageBodyStateWidget extends StatelessWidget {
  final VBaseMessageController controller;
  final VRoomType roomType;
  final VMessageLocalization language;

  const MessageBodyStateWidget({
    super.key,
    required this.controller,
    required this.roomType,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        DragDropIfWeb(
          onDragDone: (files) => controller.onSubmitMedia(context, files),
          child: ValueListenableBuilder<List<VBaseMessage>>(
            valueListenable: controller,
            builder: (_, value, __) {
              return ValueListenableBuilder<SelectionState>(
                valueListenable: controller.selectionController,
                builder: (_, selectionState, __) {
                  return ValueListenableBuilder<AppearanceSettings>(
                    valueListenable: VAppearanceListener.I,
                    builder: (_, appearanceSettings, __) {
                      return Scrollbar(
                        interactive: true,
                        thickness: 5,
                        controller: controller.scrollController,
                        child: VBubbleScope(
                          menuItemsBuilder:
                              (messageId, messageType, isMeSender) {
                            final message = _findMessageByLocalId(messageId);
                            if (message == null) return null;
                            return buildContextMenuItems(message: message);
                          },
                          style: VBubbleStyle.telegram,
                          theme: context.isDark
                              ? VBubbleThemeUtil.dark(appearanceSettings)
                              : VBubbleThemeUtil.light(appearanceSettings),
                          config: VBubbleConfig(
                            media: const bubbles.VMediaConfig(
                              imageMaxHeight: 400,
                            ),
                            spacing: bubbles.VSpacingConfig(
                              sameSenderSpacing: 1,
                              differentSenderSpacing: 2,
                            ),
                            translations: VTranslationConfig(
                              actionReply: language.reply,
                              actionForward: language.forward,
                              actionCopy: language.copy,
                              actionDownload: language.download,
                              actionDelete: language.delete,
                              actionStar: language.star,
                              deletedMessage: language.messageHasBeenDeleted,
                              callVideo: language.areYouWantToMakeVideoCall,
                              callVoice: language.audioCall,
                              callMissed: language.timeout,
                              callDeclined: language.rejected,
                              callCancelled: language.canceled,
                            ),
                            patterns: VPatternConfig(
                                enableLinks: true,
                                enableEmails: true,
                                enablePhones: true,
                                enableMentions: true,
                                enableBlockquotes: true,
                                enableBulletLists: true,
                                enableCodeBlocks: true,
                                enableFormatting: true,
                                enableHashtags: false,
                                enableNumberedLists: true,
                                customPatterns: [_buildMentionPattern()]),
                            gestures: const VGestureConfig(
                              enableSwipeToReply: true,
                              enableLongPress: true,
                              enableHapticFeedback: true,
                              enableDoubleTapToReact: false,
                            ),
                            contextMenu: const VContextMenuConfig(
                              availableActions: [
                                VMessageAction.reply,
                                VMessageAction.forward,
                                VMessageAction.copy,
                                VMessageAction.download,
                                VMessageAction.delete,
                                VMessageAction.star,
                                VMessageAction.select,
                                VMessageAction.share,
                                VMessageAction.info,
                              ],
                            ),
                            avatar: roomType.isGroup
                                ? VAvatarConfig.visible
                                : VAvatarConfig.hidden,
                          ),
                          callbacks: bubbles.VBubbleCallbacks(
                            onSwipeReply: (messageId) {
                              final message = _findMessageByLocalId(messageId);
                              if (message != null && !message.canNotSwipe) {
                                controller.setReply(message);
                              }
                            },
                            onPatternTap: (match) =>
                                _handlePatternTap(context, match),
                            onTap: (messageId) {
                              final message = _findMessageByLocalId(messageId);
                              if (message != null) {
                                handleMessageTap(context, message);
                              }
                            },
                            onMediaTap: (data) {
                              final message =
                                  _findMessageByLocalId(data.messageId);
                              if (message != null) {
                                handleMessageTap(context, message);
                              }
                            },
                            onTransferStateChanged: (messageId, action) {
                              final message = _findMessageByLocalId(messageId);
                              if (message == null) return;
                              switch (action) {
                                case bubbles.VMediaTransferAction.download:
                                  VDownloaderService.instance
                                      .addToMobileQueue(message);
                                  break;
                                case bubbles.VMediaTransferAction.cancel:
                                  FileDownloader()
                                      .cancelTaskWithId(message.localId);
                                  break;
                                case bubbles.VMediaTransferAction.retry:
                                  VDownloaderService.instance
                                      .addToMobileQueue(message);
                                  break;
                              }
                            },
                            onReactionTap: (messageId, emoji, position) {
                              final message = _findMessageByLocalId(messageId);
                              if (message != null) {
                                showReactionsDialog(
                                  context: context,
                                  roomId: controller.vRoom.id,
                                  messageId: message.id,
                                );
                              }
                            },
                            onReaction: (messageId, emoji, action) {
                              final message = _findMessageByLocalId(messageId);
                              if (message != null) {
                                controller.handleMessageReaction(
                                    message, emoji);
                              }
                            },
                            onMenuItemSelected: (messageId, item) {
                              debugPrint(
                                  '[ContextMenu] Item selected: ${item.id} for message: $messageId');
                              final message = _findMessageByLocalId(messageId);
                              if (message == null) {
                                debugPrint(
                                    '[ContextMenu] ERROR: Message not found for localId: $messageId');
                                debugPrint(
                                    '[ContextMenu] Available messages: ${controller.stateMessages.map((m) => m.localId).toList()}');
                                return;
                              }
                              debugPrint(
                                  '[ContextMenu] Message found, calling handleContextMenuAction');
                              handleContextMenuAction(
                                context: context,
                                item: item,
                                message: message,
                                room: controller.vRoom,
                                onReply: controller.setReply,
                                onEnterSelectionMode: () =>
                                    controller.enterSelectionMode(message),
                                messageProvider: controller.messageProvider,
                              );
                            },
                            onReplyPreviewTap: (originalMessageId) {
                              final originalMessage =
                                  _findMessageByLocalId(originalMessageId);
                              if (originalMessage != null) {
                                controller.onHighlightMessage(originalMessage);
                              }
                            },
                            onAvatarTap: (senderId) {
                              VChatController.I.vNavigator.messageNavigator
                                  .toUserProfilePage
                                  ?.call(context, senderId);
                            },
                            onSelectionChanged: (messageId, isSelected) {
                              controller.toggleMessageSelection(messageId);
                            },
                          ),
                          isSelectionMode: selectionState.isSelectionMode,
                          selectedIds: selectionState.selectedIds,
                          child: ListView.separated(
                            separatorBuilder: (context, index) {
                              final isSameSender =
                                  _isSameSenderAt(value, index);
                              return SizedBox(
                                  height: isSameSender
                                      ? 2
                                      : (VPlatforms.isWeb ? 8 : 4));
                            },
                            // Bottom padding for floating input bar (Telegram style)
                            padding: const EdgeInsets.only(
                              left: 10,
                              right: 10,
                              top: 10,
                              bottom: 80,
                            ),
                            controller: controller.scrollController,
                            cacheExtent: 300,
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              final message = value[index];
                              final isSameSender =
                                  _isSameSenderAt(value, index);
                              final msgItem = StreamBuilder<VBaseMessage>(
                                key: ValueKey(message.localId),
                                stream:
                                    controller.messageStateStream.stream.where(
                                  (e) => e.localId == message.localId,
                                ),
                                initialData: message,
                                builder: (context, snapshot) {
                                  if (message.isDeleted) {
                                    return const SizedBox.shrink();
                                  }
                                  return AutoScrollTag(
                                    key: ValueKey('scroll_${message.localId}'),
                                    controller: controller.scrollController,
                                    index: index,
                                    highlightColor: context.isDark
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Colors.black.withValues(alpha: 0.2),
                                    child: VMessageItem(
                                      language: language,
                                      roomType: roomType,
                                      isSameSender: isSameSender,
                                      message: snapshot.data!,
                                      onReactionSelected: (m, emoji) {
                                        controller.handleMessageReaction(
                                            m, emoji);
                                      },
                                      voiceController: (message) {
                                        if (message is VVoiceMessage) {
                                          return controller.voiceControllers
                                              .getVoiceController(message);
                                        }
                                        return null;
                                      },
                                      onSwipe: controller.setReply,
                                      onHighlightMessage:
                                          controller.onHighlightMessage,
                                      onReSend: controller.onReSend,
                                    ),
                                  );
                                },
                              );
                              final isTopMessage =
                                  _isTopMessage(value.length, index);
                              final dividerDate = _getDateDiff(
                                bigDate: message.createdAtDate,
                                smallDate: isTopMessage
                                    ? value[index].createdAtDate
                                    : value[index + 1].createdAtDate,
                              );
                              if (dividerDate != null || isTopMessage) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    bubbles.VDateChip(
                                      date: DateFormatUtils.formatDateDivider(
                                        dividerDate ?? message.createdAtDate,
                                        today: language.today,
                                        yesterday: language.yesterday,
                                      ),
                                    ),
                                    msgItem,
                                  ],
                                );
                              }
                              return msgItem;
                            },
                            itemCount: value.length,
                            reverse: true,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        PositionedDirectional(
          bottom: 90,
          end: 10,
          child: ListViewArrowDown(
            scrollController: controller.scrollController,
            onPress: controller.scrollDown,
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(),
        ),
      ],
    );
  }

  bool _isTopMessage(int listLength, int index) {
    return listLength - 1 == index;
  }

  /// Check if message at index-1 (visually below in reversed list) is from same sender
  /// Returns true if current bubble should NOT show tail (Telegram style: tail on LAST message of group)
  bool _isSameSenderAt(List<VBaseMessage> messages, int index) {
    if (index == 0) {
      return false; // Bottom message (newest) always shows tail
    }
    final currentMessage = messages[index];
    final messageBelow = messages[index - 1];
    // Don't group if either message is a center/system message
    if (currentMessage.messageType.isCenter ||
        messageBelow.messageType.isCenter) {
      return false;
    }
    return currentMessage.senderId == messageBelow.senderId;
  }

  DateTime? _getDateDiff({
    required DateTime bigDate,
    required DateTime smallDate,
  }) {
    final difference = bigDate.difference(smallDate);
    if (difference.isNegative) {
      return null;
    }
    if (difference.inHours < 24) {
      final d1 = bigDate.day;
      final d2 = smallDate.day;
      if (d1 == d2) {
        return null;
      } else {
        return bigDate;
      }
    }
    return bigDate;
  }

  VBaseMessage? _findMessageByLocalId(
    String messageLocalId,
  ) {
    try {
      return controller.stateMessages
          .firstWhere((m) => m.localId == messageLocalId);
    } catch (_) {
      return null;
    }
  }

  bubbles.VCustomPattern _buildMentionPattern() {
    return bubbles.VCustomPattern(
      id: 'custom_mention',
      pattern: RegExp(r"\[(@[^:]+):([^\]]+)\]"),
      style: TextStyle(
        color: Colors.blue,
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
      valueTransformer: (match) {
        final regex = RegExp(r"\[(@[^:]+):([^\]]+)\]");
        final result = regex.firstMatch(match);
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
        final regex = RegExp(r'\[(@[^:]+):([^\]]+)\]');
        final result = regex.firstMatch(match.rawText);
        final userId = result?.group(2);
        if (userId != null) {
          VChatController.I.vNavigator.messageNavigator.toUserProfilePage
              ?.call(context, userId);
        }
        break;
    }
  }
}
