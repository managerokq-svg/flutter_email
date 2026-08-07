// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart' as bubbles;
import 'package:v_chat_bubbles/v_chat_bubbles.dart';
import 'package:v_chat_message_page/v_chat_message_page.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

import '../../../../../v_chat_v2/translations.dart';
import '../../../../core/app_config/app_config_controller.dart';
import '../../../chat_settings/shared/media_item_actions.dart';
import '../controllers/chat_star_messages_controller.dart';

final _mentionRegex = RegExp(r"\[(@[^:]+):([^\]]+)\]");

class ChatStarMessagesPage extends StatefulWidget {
  final String? roomId;

  const ChatStarMessagesPage({
    super.key,
    this.roomId,
  });

  @override
  State<ChatStarMessagesPage> createState() => _ChatStarMessagesPageState();
}

class _ChatStarMessagesPageState extends State<ChatStarMessagesPage> {
  late final ChatStarMessagesController controller;

  @override
  void initState() {
    super.initState();
    controller = ChatStarMessagesController(widget.roomId);
    controller.onInit();
    AdsBannerWidget.loadAd(
      VPlatforms.isAndroid
          ? SConstants.androidInterstitialId
          : SConstants.iosInterstitialId,
      enableAds: VAppConfigController.appConfig.enableAds,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: context.vMessageTheme.scaffoldDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(S.of(context).starMessage),
        ),
        body: SafeArea(
          bottom: false,
          child: ValueListenableBuilder<SLoadingState<List<VBaseMessage>>>(
            valueListenable: controller,
            builder: (_, data, ___) => VAsyncWidgetsBuilder(
              loadingState: data.loadingState,
              onRefresh: controller.getData,
              successWidget: () {
                final value = data.data;
                return VBubbleScope(
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
                    onMenuItemSelected: (messageId, item) =>
                        _handleMenuItemSelected(messageId, item, value),
                    onReaction: (messageId, emoji, action) {
                      final message = _findMessageByLocalId(messageId, value);
                      if (message != null) {
                        ReactionController.toggleReaction(message, emoji);
                      }
                    },
                    onReactionTap: (messageId, emoji, position) {
                      final message = _findMessageByLocalId(messageId, value);
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
                    final message = _findMessageByLocalId(messageId, value);
                    if (message == null) return null;
                    return buildContextMenuItems(
                      message: message,
                      includeReply: false,
                      includeSelect: false,
                    );
                  },
                  style: VBubbleStyle.telegram,
                  child: Scrollbar(
                    interactive: true,
                    thickness: 5,
                    controller: controller.scrollController,
                    child: ListView.separated(
                      separatorBuilder: (context, index) => SizedBox(
                        height: VPlatforms.isWeb ? 12 : 10,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      controller: controller.scrollController,
                      // key: const PageStorageKey("VListViewItems"),
                      cacheExtent: 300,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final message = value[index];
                        final language = vMessageLocalizationPageModel(
                          context,
                        );
                        return Builder(
                          key: UniqueKey(),
                          builder: (context) {
                            if (message.isDeleted) {
                              return const SizedBox.shrink();
                            }
                            final isSameSender =
                                _isSameSenderAt(value, index);
                            final msgItem = VMessageItem(
                              language: language,
                              onLongTap: (message) =>
                                  controller.onLongTab(context, message),
                              roomType: VRoomType.s,
                              isSameSender: isSameSender,
                              message: message,
                              voiceController: (message) {
                                if (message is VVoiceMessage) {
                                  return controller.voiceControllers
                                      .getVoiceController(message);
                                }
                                return null;
                              },
                            );

                            final isTopMessage =
                                _isTopMessage(value.length, index);
                            final dividerDate = _getDateDiff(
                              bigDate: message.createdAtDate,
                              smallDate: isTopMessage
                                  ? message.createdAtDate
                                  : (index + 1 < value.length
                                      ? value[index + 1].createdAtDate
                                      : message.createdAtDate),
                            );
                            if (dividerDate != null || isTopMessage) {
                              //set date divider
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        );
                      },
                      itemCount: value.length,
                      // reverse: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.onClose();
    super.dispose();
  }

  bool _isTopMessage(int listLength, int index) {
    return listLength - 1 == index;
  }

  /// Check if next message (index+1) is from same sender (non-reversed list)
  /// Returns true if current bubble should NOT show tail (Telegram style: tail on LAST message of group)
  bool _isSameSenderAt(List<VBaseMessage> messages, int index) {
    if (index >= messages.length - 1) {
      return false; // Last message always shows tail
    }
    final currentMessage = messages[index];
    final nextMessage = messages[index + 1];
    if (currentMessage.messageType.isCenter ||
        nextMessage.messageType.isCenter) {
      return false;
    }
    return currentMessage.senderId == nextMessage.senderId;
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
      String messageId, List<VBaseMessage> messages) {
    try {
      return messages.firstWhere((m) => m.localId == messageId);
    } catch (_) {
      return null;
    }
  }

  void _handleMenuItemSelected(
    String messageId,
    VBubbleMenuItem item,
    List<VBaseMessage> messages,
  ) {
    final message = _findMessageByLocalId(messageId, messages);
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
