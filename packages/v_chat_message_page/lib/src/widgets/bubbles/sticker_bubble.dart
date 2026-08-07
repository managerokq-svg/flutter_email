// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart';

/// Custom sticker bubble with proper time chip background color.
/// Uses semi-transparent dark background for time chip instead of
/// yellow system message background.
class VCustomStickerBubble extends BaseBubble {
  final VPlatformFile stickerFile;
  final double size;
  @override
  String get messageType => 'sticker';
  const VCustomStickerBubble({
    super.key,
    required super.messageId,
    required super.isMeSender,
    required super.time,
    required this.stickerFile,
    this.size = 160,
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
    final stickerContent = Column(
      crossAxisAlignment:
          isMeSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStickerImage(context),
        const SizedBox(height: 4),
        _buildTimeChip(context),
      ],
    );
    if (header == null) return stickerContent;
    return Column(
      crossAxisAlignment:
          isMeSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        VBubbleWrapper(
          isMeSender: isMeSender,
          showTail: false,
          child: header,
        ),
        const SizedBox(height: 4),
        stickerContent,
      ],
    );
  }

  Widget _buildStickerImage(BuildContext context) {
    final theme = context.bubbleTheme;
    final shimmerBase = isMeSender
        ? theme.outgoingBubbleColor.withValues(alpha: 0.3)
        : theme.incomingBubbleColor.withValues(alpha: 0.3);
    final shimmerHighlight = isMeSender
        ? theme.outgoingBubbleColor.withValues(alpha: 0.1)
        : theme.incomingBubbleColor.withValues(alpha: 0.1);
    return SizedBox(
      width: size,
      height: size,
      child: VPlatformImageBuilder.build(
        stickerFile,
        fit: BoxFit.contain,
        config: const VImageRenderConfig(
          filterQuality: FilterQuality.high,
          fadeInDuration: Duration(milliseconds: 200),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: shimmerBase,
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Center(child: CircularProgressIndicator.adaptive()),
          );
        },
        errorBuilder: (context, error, stack) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: shimmerHighlight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Icon(Icons.error_outline, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(BuildContext context) {
    final theme = context.bubbleTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            time,
            style: theme.timeTextStyle.copyWith(color: Colors.white),
          ),
          if (isMeSender) ...[
            const SizedBox(width: 4),
            VMessageStatusIcon(
              status: status,
              color: Colors.white,
              size: 14,
              readColor: theme.readIconColor,
            ),
          ],
        ],
      ),
    );
  }
}
