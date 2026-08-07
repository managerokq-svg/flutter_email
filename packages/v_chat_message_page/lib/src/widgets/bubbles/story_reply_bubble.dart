// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

import '../../theme/v_message_theme_exc.dart';

/// Story reply message bubble
///
/// Displays a story preview card with the reply text.
/// Tapping on the story preview navigates to view the full story.
class VStoryReplyBubble extends BaseBubble {
  /// Story data containing story info
  final VStoryReplyMsgData storyData;

  /// Reply text content
  final String replyContent;

  /// Base media URL for constructing full image URLs
  final String baseMediaUrl;

  /// Localized "Story" label text
  final String storyLabel;

  /// Localized "Story no longer available" text
  final String storyNotAvailableText;

  /// Callback when story preview is tapped
  final VoidCallback? onStoryTap;

  /// Whether story is currently loading
  final bool isLoading;

  @override
  String get messageType => 'story_reply';

  const VStoryReplyBubble({
    super.key,
    required super.messageId,
    required super.isMeSender,
    required super.time,
    required this.storyData,
    required this.replyContent,
    required this.baseMediaUrl,
    required this.storyLabel,
    required this.storyNotAvailableText,
    this.onStoryTap,
    this.isLoading = false,
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
    final theme = context.bubbleTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return VBubbleWrapper(
      isMeSender: isMeSender,
      showTail: showTail,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (header != null) header,
          _buildStoryPreview(context, isDark, theme),
          if (replyContent.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildReplyText(context),
          ],
          const SizedBox(height: 4),
          buildMeta(context),
        ],
      ),
    );
  }

  Widget _buildStoryPreview(
      BuildContext context, bool isDark, VBubbleTheme theme) {
    return GestureDetector(
      onTap: isLoading ? null : onStoryTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThumbnail(context, isDark),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOwnerRow(context, isDark),
                  const SizedBox(height: 3),
                  _buildStoryLabel(context, isDark),
                  if (storyData.isTextStory &&
                      storyData.storyContent != null) ...[
                    const SizedBox(height: 4),
                    _buildTextPreview(isDark),
                  ],
                ],
              ),
            ),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerRow(BuildContext context, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.pink.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(5),
          ),
          child: const Icon(
            Icons.auto_stories_rounded,
            size: 11,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            storyData.storyOwnerName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStoryLabel(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        storyLabel,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.white54 : Colors.black45,
        ),
      ),
    );
  }

  Widget _buildTextPreview(bool isDark) {
    return Text(
      storyData.storyContent!,
      style: TextStyle(
        fontSize: 11,
        fontStyle: FontStyle.italic,
        color: isDark ? Colors.white54 : Colors.black54,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildThumbnail(BuildContext context, bool isDark) {
    const double size = 52;
    final borderRadius = BorderRadius.circular(8);
    if (storyData.isImageStory && storyData.storyImageUrl != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: VPlatformImageBuilder.build(
          VPlatformFile.fromUrl(
            networkUrl: baseMediaUrl + storyData.storyImageUrl!,
          ),
          fit: BoxFit.cover,
          width: size,
          height: size,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder(isDark, size, borderRadius);
          },
          errorBuilder: (context, error, stack) =>
              _buildPlaceholder(isDark, size, borderRadius),
        ),
      );
    }
    if (storyData.isTextStory) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: borderRadius,
        ),
        child: const Center(
          child: Icon(
            Icons.format_quote_rounded,
            color: Colors.white70,
            size: 24,
          ),
        ),
      );
    }
    return _buildPlaceholder(isDark, size, borderRadius);
  }

  Widget _buildPlaceholder(bool isDark, double size, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: radius,
      ),
      child: Icon(
        Icons.auto_stories_outlined,
        color: isDark ? Colors.white30 : Colors.black26,
        size: 24,
      ),
    );
  }

  Widget _buildReplyText(BuildContext context) {
    final messageTheme = context.vMessageTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Text(
        replyContent,
        style: isMeSender
            ? messageTheme.senderTextStyle
            : messageTheme.receiverTextStyle,
      ),
    );
  }
}
