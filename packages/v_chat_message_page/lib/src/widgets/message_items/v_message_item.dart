// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart' as bubbles;
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:v_platform/v_platform.dart';

import '../../../v_chat_message_page.dart';
import '../../page/one_time_seen/one_time_seen_page.dart';
import '../../v_chat/v_message_constants.dart';
import '../bubbles/bubbles.dart';

/// Message item widget that routes VBaseMessage to appropriate v_chat_bubbles widgets
class VMessageItem extends StatelessWidget {
  final VBaseMessage message;
  final VMessageCallback? onSwipe;
  final VMessageCallback? onLongTap;
  final VVoiceMessageController? Function(VBaseMessage message)?
      voiceController;
  final VMessageCallback? onHighlightMessage;
  final VMessageCallback? onReSend;
  final VRoomType roomType;
  final VMessageLocalization language;
  final bool forceSeen;
  final void Function(VBaseMessage, String)? onReactionSelected;

  /// Whether the previous message (visually above) is from the same sender
  /// When true, the bubble will not show a tail
  final bool isSameSender;

  const VMessageItem({
    super.key,
    this.onLongTap,
    required this.roomType,
    this.voiceController,
    required this.message,
    required this.language,
    this.onSwipe,
    this.forceSeen = false,
    this.onReSend,
    this.onHighlightMessage,
    this.onReactionSelected,
    this.isSameSender = false,
  });

  bool get _isGroup => roomType.isGroup;

  @override
  Widget build(BuildContext context) {
    // Handle center/info messages separately
    if (message.messageType.isCenter) {
      return bubbles.VSystemBubble(
        text: VMessageConstants.getMessageBody(
          message,
          language.vMessagesInfoTrans,
        ),
      );
    }
    // Map common properties
    final commonProps = _buildCommonProps(context);
    // Handle deleted messages
    if (message.allDeletedAt != null) {
      return bubbles.VDeletedBubble(
        isMeSender: message.isMeSender,
        time: commonProps.time,
      );
    }
    // Handle one-seen messages for RECEIVER only
    // - Sender always sees actual content (bypasses this block)
    // - Receiver sees "click to see" until they view it
    // - After viewing, receiver sees "message has been viewed"
    // - forceSeen bypasses the one-seen bubble (used in OneTimeSeenPage)
    if (message.isOneSeen && !message.isMeSender && !forceSeen) {
      if (message.isOneSeenByMe) {
        // Receiver has already seen - show "message has been viewed" bubble
        return VOneSeenBubble(
          messageId: commonProps.messageId,
          isMeSender: message.isMeSender,
          time: commonProps.time,
          isSeenByMe: true,
          clickToSeeText: S.of(context).clickToSee,
          messageViewedText: S.of(context).messageHasBeenViewed,
          status: commonProps.status,
          avatar: commonProps.avatar,
          senderName: commonProps.senderName,
          reactions: commonProps.reactions,
          replyTo: commonProps.replyTo,
          forwardedFrom: commonProps.forwardedFrom,
          isStarred: message.isStared,
        );
      } else {
        // Receiver hasn't seen yet - show "click to see" bubble
        return VOneSeenBubble(
          messageId: commonProps.messageId,
          isMeSender: message.isMeSender,
          time: commonProps.time,
          isSeenByMe: false,
          clickToSeeText: S.of(context).clickToSee,
          messageViewedText: S.of(context).messageHasBeenViewed,
          onClickToSee: () {
            context.toPage(
              OneTimeSeenPage(
                message: message,
                language: language,
              ),
            );
          },
          status: commonProps.status,
          avatar: commonProps.avatar,
          senderName: commonProps.senderName,
          reactions: commonProps.reactions,
          replyTo: commonProps.replyTo,
          forwardedFrom: commonProps.forwardedFrom,
          isStarred: message.isStared,
        );
      }
    }
    // Route by message type
    final bubble = _buildMessageBubble(context, commonProps);
    // Add one-seen indicator for sender
    if (message.isOneSeen && message.isMeSender) {
      return _wrapWithOneSeenIndicator(context, bubble);
    }
    return bubble;
  }

  /// Wraps a bubble with a small eye icon to indicate one-time-seen message
  Widget _wrapWithOneSeenIndicator(BuildContext context, Widget bubble) {
    return IntrinsicWidth(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          bubble,
          Positioned(
            top: -4,
            right: -4,
            child: GestureDetector(
              onTap: () => _showOneSeenExplanationDialog(context),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.isDark ? Colors.black : Colors.white,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.visibility,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Shows a dialog explaining the one-time-seen feature
  void _showOneSeenExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.visibility, color: Colors.red.shade400),
            const SizedBox(width: 8),
            Text(S.of(context).oneTimeSeen),
          ],
        ),
        content: Text(S.of(context).oneTimeSeenExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(S.of(context).ok),
          ),
        ],
      ),
    );
  }

  _CommonBubbleProps _buildCommonProps(BuildContext context) {
    return _CommonBubbleProps(
      messageId: message.localId,
      time: MessageToBubbleMapper.formatTime(message.createdAtDate),
      status: MessageToBubbleMapper.mapStatus(message),
      reactions: MessageToBubbleMapper.mapReactions(message),
      replyTo: MessageToBubbleMapper.mapReplyTo(message.replyTo),
      forwardedFrom: MessageToBubbleMapper.mapForwardedFrom(message),
      avatar: MessageToBubbleMapper.getAvatar(message, _isGroup, isSameSender),
      senderName: MessageToBubbleMapper.getSenderName(message, _isGroup, isSameSender),
      linkPreview: MessageToBubbleMapper.mapLinkPreview(message.linkAtt),
    );
  }

  Widget _buildMessageBubble(BuildContext context, _CommonBubbleProps props) {
    switch (message.messageType) {
      case VMessageType.text:
        return _buildTextBubble(context, props);
      case VMessageType.image:
        return _buildImageBubble(context, props);
      case VMessageType.video:
        return _buildVideoBubble(context, props);
      case VMessageType.voice:
        return _buildVoiceBubble(context, props);
      case VMessageType.file:
        return _buildFileBubble(context, props);
      case VMessageType.location:
        return _buildLocationBubble(context, props);
      case VMessageType.call:
        return _buildCallBubble(context, props);
      case VMessageType.sticker:
        return _buildStickerBubble(context, props);
      case VMessageType.gif:
        return _buildGifBubble(context, props);
      case VMessageType.storyReply:
        return _buildStoryReplyBubble(context, props);
      case VMessageType.custom:
        return _buildCustomBubble(context, props);
      case VMessageType.contact:
        return _buildContactBubble(context, props);
      case VMessageType.reaction:
      case VMessageType.bug:
        return const SizedBox.shrink();
      case VMessageType.info:
        throw 'MessageType.info should be handled as center message';
    }
  }

  Widget _buildTextBubble(BuildContext context, _CommonBubbleProps props) {
    return bubbles.VTextBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      text: message.realContent,
      linkPreview: props.linkPreview,
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildImageBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VImageMessage) return const SizedBox.shrink();
    final imageMessage = message as VImageMessage;
    final fileSource = imageMessage.data.fileSource;
    final imageData = imageMessage.data;
    final aspectRatio =
        imageData.height > 0 ? imageData.width / imageData.height : 1.0;
    // Use fullNetworkUrl for network images (includes base media URL)

    return bubbles.VImageBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      imageFile: fileSource,
      aspectRatio: aspectRatio,
      progress: message.progress,
      transferState: _mapTransferState(),
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildVideoBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VVideoMessage) return const SizedBox.shrink();
    final videoMessage = message as VVideoMessage;
    final data = videoMessage.data;
    final thumbImage = data.thumbImage;
    double? aspectRatio;
    if (thumbImage != null && thumbImage.height > 0) {
      aspectRatio = thumbImage.width / thumbImage.height;
    }
    // Use fullNetworkUrl for network files (includes base media URL)
    final videoSource = data.fileSource;
    final videoFile =
        videoSource.isFromUrl && videoSource.fullNetworkUrl != null
            ? VPlatformFile.fromUrl(networkUrl: videoSource.fullNetworkUrl!)
            : videoSource;
    VPlatformFile? thumbnailFile;
    if (thumbImage != null) {
      final thumbSource = thumbImage.fileSource;
      thumbnailFile =
          thumbSource.isFromUrl && thumbSource.fullNetworkUrl != null
              ? VPlatformFile.fromUrl(networkUrl: thumbSource.fullNetworkUrl!)
              : thumbSource;
    }
    return bubbles.VVideoBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      videoFile: videoFile,
      thumbnailFile: thumbnailFile,
      duration: Duration(milliseconds: data.duration ?? 0),
      aspectRatio: aspectRatio,
      progress: message.progress,
      transferState: _mapTransferState(),
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildVoiceBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VVoiceMessage) return const SizedBox.shrink();
    final voiceMessage = message as VVoiceMessage;
    final controller = voiceController?.call(voiceMessage);
    if (controller == null) return const SizedBox.shrink();
    return bubbles.VVoiceBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      controller: controller,
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildFileBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VFileMessage) return const SizedBox.shrink();
    final fileMessage = message as VFileMessage;
    final fileSource = fileMessage.data.fileSource;
    // Use fullNetworkUrl for network files (includes base media URL)
    final file = fileSource.isFromUrl && fileSource.fullNetworkUrl != null
        ? VPlatformFile.fromUrl(networkUrl: fileSource.fullNetworkUrl!)
        : fileSource;
    return bubbles.VFileBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      file: file,
      progress: message.progress,
      transferState: _mapTransferState(),
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildLocationBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VLocationMessage) return const SizedBox.shrink();
    final locationMessage = message as VLocationMessage;
    final data = locationMessage.data;
    return bubbles.VLocationBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      locationData: bubbles.VLocationData(
        latitude: data.latLng.latitude,
        longitude: data.latLng.longitude,
        address: data.linkPreviewData.title,
        staticMapUrl: data.linkPreviewData.image,
      ),
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildCallBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VCallMessage) return const SizedBox.shrink();
    final callMessage = message as VCallMessage;
    final callData = callMessage.data;
    Duration? callDuration;
    if (callData.duration != null) {
      final seconds = int.tryParse(callData.duration!);
      if (seconds != null) {
        callDuration = Duration(seconds: seconds);
      }
    }
    return bubbles.VCallBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      callData: bubbles.VCallData(
        type: callData.withVideo
            ? bubbles.VCallType.video
            : bubbles.VCallType.voice,
        status: MessageToBubbleMapper.mapCallStatus(callData.callStatus),
        duration: callDuration,
      ),
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildStickerBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VStickerMessage) return const SizedBox.shrink();
    final stickerMessage = message as VStickerMessage;
    return VCustomStickerBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      stickerFile: VPlatformFile.fromUrl(networkUrl: stickerMessage.url),
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildGifBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VGifMessage) return const SizedBox.shrink();
    final gifMessage = message as VGifMessage;
    return VGifBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      url: gifMessage.url,
      aspectRatio: gifMessage.aspectRatio,
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildStoryReplyBubble(
      BuildContext context, _CommonBubbleProps props) {
    if (message is! VStoryReplyMessage) return const SizedBox.shrink();
    final storyReplyMessage = message as VStoryReplyMessage;
    final theme = context.vMessageTheme;
    final storyTapHandler = theme.storyReplyTapHandler;
    final baseMediaUrl = theme.baseMediaUrl ?? '';
    return VStoryReplyBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      storyData: storyReplyMessage.data,
      replyContent: message.realContent,
      baseMediaUrl: baseMediaUrl,
      storyLabel: S.of(context).story,
      storyNotAvailableText: S.of(context).storyNoLongerAvailable,
      onStoryTap: storyTapHandler == null
          ? null
          : () => storyTapHandler(context, storyReplyMessage.data),
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  Widget _buildCustomBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VCustomMessage) return const SizedBox.shrink();
    final customMessage = message as VCustomMessage;
    final customBuilder = context.vMessageTheme.customMessageItem;
    if (customBuilder != null) {
      return customBuilder(
        context,
        message.isMeSender,
        customMessage.data.data,
      );
    }
    return const Text(
      'Custom message not implemented. Add customMessageItem to VInheritedMessageTheme.',
    );
  }

  Widget _buildContactBubble(BuildContext context, _CommonBubbleProps props) {
    if (message is! VContactMessage) return const SizedBox.shrink();
    final contactMessage = message as VContactMessage;
    return VContactBubble(
      messageId: props.messageId,
      isMeSender: message.isMeSender,
      time: props.time,
      contactData: contactMessage.data,
      status: props.status,
      isSameSender: isSameSender,
      avatar: props.avatar,
      senderName: props.senderName,
      reactions: props.reactions,
      replyTo: props.replyTo,
      forwardedFrom: props.forwardedFrom,
      isStarred: message.isStared,
    );
  }

  bubbles.VTransferState _mapTransferState() {
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
}

/// Helper class to hold common bubble properties
class _CommonBubbleProps {
  final String messageId;
  final String time;
  final bubbles.VMessageStatus status;
  final List<bubbles.VBubbleReaction> reactions;
  final bubbles.VReplyData? replyTo;
  final bubbles.VForwardData? forwardedFrom;
  final VPlatformFile? avatar;
  final String? senderName;
  final bubbles.VLinkPreviewData? linkPreview;

  const _CommonBubbleProps({
    required this.messageId,
    required this.time,
    required this.status,
    required this.reactions,
    this.replyTo,
    this.forwardedFrom,
    this.avatar,
    this.senderName,
    this.linkPreview,
  });
}
