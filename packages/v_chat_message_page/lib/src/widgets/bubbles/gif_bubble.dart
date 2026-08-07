// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart';

/// GIF message bubble using v_chat_bubbles
///
/// Renders animated GIF content with proper aspect ratio and bubble styling.
class VGifBubble extends BaseBubble {
  /// GIF URL
  final String url;

  /// GIF aspect ratio (width/height)
  final double aspectRatio;
  @override
  String get messageType => 'gif';
  const VGifBubble({
    super.key,
    required super.messageId,
    required super.isMeSender,
    required super.time,
    required this.url,
    required this.aspectRatio,
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
    final theme = context.bubbleTheme;
    final header = buildBubbleHeader(context);
    final hasHeader = header != null;
    final gifContent = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: hasHeader
            ? BorderRadius.zero
            : const BorderRadius.all(Radius.circular(12)),
        child: CachedNetworkImage(
          imageUrl: url,
          placeholder: (context, url) => Container(
            color: isMeSender
                ? theme.outgoingBubbleColor.withValues(alpha: 0.3)
                : theme.incomingBubbleColor.withValues(alpha: 0.3),
            child: const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: isMeSender
                ? theme.outgoingBubbleColor.withValues(alpha: 0.3)
                : theme.incomingBubbleColor.withValues(alpha: 0.3),
            child: const Center(
              child: Icon(Icons.error_outline, size: 32),
            ),
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
    final overlayInfo = Positioned(
      right: 8,
      bottom: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GIF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            buildMeta(context, overrideColor: Colors.white),
          ],
        ),
      ),
    );
    if (!hasHeader) {
      return ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Stack(
          children: [
            gifContent,
            overlayInfo,
          ],
        ),
      );
    }
    final showTail = !isSameSender;
    return VBubbleWrapper(
      isMeSender: isMeSender,
      showTail: showTail,
      padding: EdgeInsets.zero,
      clipContent: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.all(8), child: header),
          Stack(
            children: [
              gifContent,
              overlayInfo,
            ],
          ),
        ],
      ),
    );
  }
}
