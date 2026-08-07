// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart';

/// One-time-seen message bubble
///
/// Shows either "Click to See" (if not yet viewed) or "Message has been viewed" (if already viewed).
/// Used for messages that can only be viewed once.
class VOneSeenBubble extends BaseBubble {
  /// Whether this message has been viewed by the current user
  final bool isSeenByMe;

  /// Localized text for "Click to See"
  final String clickToSeeText;

  /// Localized text for "Message has been viewed"
  final String messageViewedText;

  /// Callback when user taps "Click to See"
  final VoidCallback? onClickToSee;

  @override
  String get messageType => 'one-time-message';

  const VOneSeenBubble({
    super.key,
    required super.messageId,
    required super.isMeSender,
    required super.time,
    required this.isSeenByMe,
    required this.clickToSeeText,
    required this.messageViewedText,
    this.onClickToSee,
    super.status,
    super.isSameSender,
    super.avatar,
    super.senderName,
    super.senderColor,
    super.replyTo,
    super.forwardedFrom,
    super.reactions,
    super.isEdited,
    super.isPinned,
    super.isStarred,
    super.isHighlighted,
  });

  @override
  Widget buildContent(BuildContext context) {
    final header = buildBubbleHeader(context);
    final showTail = !isSameSender;
    Widget content;
    // Receiver who has already viewed the message sees "message has been viewed"
    // Note: Sender never reaches this bubble - they see actual content in v_message_item.dart
    if (isSeenByMe) {
      content = Text(
        "$messageViewedText 👁️",
        style: TextStyle(
          color: Colors.red,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
        ),
      );
    } else {
      content = GestureDetector(
        onTap: onClickToSee,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.visibility, color: Colors.red, size: 18),
              const SizedBox(width: 6),
              Text(
                clickToSeeText,
                style: TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return VBubbleWrapper(
      isMeSender: isMeSender,
      showTail: showTail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) header,
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(child: content),
              const SizedBox(width: 8),
              buildMeta(context),
            ],
          ),
        ],
      ),
    );
  }
}
