// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:v_chat_input_ui/src/input/widgets/telegram_glass_container.dart';
import '../../models/mention_model.dart';
import '../../v_widgets/v_circle_avatar.dart';

/// Telegram-style mention list with glass effect
class TelegramMentionList extends StatelessWidget {
  final List<MentionModel> mentions;
  final Function(MentionModel mention) onMentionTap;
  final Widget Function(MentionModel)? mentionItemBuilder;

  const TelegramMentionList({
    super.key,
    required this.mentions,
    required this.onMentionTap,
    this.mentionItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.telegramColors;
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: colors.glassBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: mentions.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 56,
            color: colors.secondaryText.withOpacity(0.1),
          ),
          itemBuilder: (context, index) {
            final mention = mentions[index];
            if (mentionItemBuilder != null) {
              return GestureDetector(
                onTap: () => onMentionTap(mention),
                child: mentionItemBuilder!(mention),
              );
            }
            return _TelegramMentionItem(
              mention: mention,
              onTap: () => onMentionTap(mention),
            );
          },
        ),
      ),
    );
  }
}

class _TelegramMentionItem extends StatelessWidget {
  final MentionModel mention;
  final VoidCallback onTap;

  const _TelegramMentionItem({
    required this.mention,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.telegramColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Avatar
              VCircleAvatar(
                fullUrl: mention.imageS3,
                radius: 20,
              ),
              const SizedBox(width: 12),
              // Name and username
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      mention.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: colors.primaryText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (mention.peerId.isNotEmpty)
                      Text(
                        '@${mention.peerId}',
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
