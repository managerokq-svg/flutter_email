// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:intl/intl.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart' as bubbles;
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:v_platform/v_platform.dart';

/// Utility class to map VBaseMessage to v_chat_bubbles widget props
class MessageToBubbleMapper {
  MessageToBubbleMapper._();

  /// Format message time (e.g., "12:30 PM")
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Map VMessageEmitStatus to VMessageStatus
  static bubbles.VMessageStatus mapStatus(VBaseMessage message) {
    if (message.emitStatus == VMessageEmitStatus.sending) {
      return bubbles.VMessageStatus.sending;
    }
    if (message.emitStatus == VMessageEmitStatus.error) {
      return bubbles.VMessageStatus.error;
    }
    // Server confirmed - check delivery/seen status
    if (message.seenAt != null) {
      return bubbles.VMessageStatus.read;
    }
    if (message.deliveredAt != null) {
      return bubbles.VMessageStatus.delivered;
    }
    return bubbles.VMessageStatus.sent;
  }

  /// Map reaction samples to VBubbleReaction list
  static List<bubbles.VBubbleReaction> mapReactions(VBaseMessage message) {
    if (message.reactionSample.isEmpty) return const [];
    return message.reactionSample.map((sample) {
      return bubbles.VBubbleReaction(
        emoji: sample.emoji,
        count: sample.count,
        isSelected: message.currentUserEmoji == sample.emoji,
      );
    }).toList();
  }

  /// Map reply message to VReplyData
  static bubbles.VReplyData? mapReplyTo(VBaseMessage? replyTo) {
    if (replyTo == null) return null;
    VPlatformFile? previewImage;
    if (replyTo.messageType == VMessageType.image && replyTo is VImageMessage) {
      previewImage = replyTo.data.fileSource;
    }
    return bubbles.VReplyData(
      senderId: replyTo.senderId,
      senderName: replyTo.senderName,
      previewText: _getReplyPreviewText(replyTo),
      previewImage: previewImage,
      originalType: _mapMessageType(replyTo.messageType),
      originalMessageId: replyTo.id,
    );
  }

  /// Get preview text for reply based on message type
  static String _getReplyPreviewText(VBaseMessage message) {
    switch (message.messageType) {
      case VMessageType.text:
        return message.realContent;
      case VMessageType.image:
        return 'Photo';
      case VMessageType.video:
        return 'Video';
      case VMessageType.voice:
        return 'Voice message';
      case VMessageType.file:
        return 'File';
      case VMessageType.location:
        return 'Location';
      case VMessageType.sticker:
        return 'Sticker';
      case VMessageType.gif:
        return 'GIF';
      case VMessageType.call:
        return 'Call';
      default:
        return message.realContent;
    }
  }

  /// Map SDK VMessageType to bubbles VMessageType
  static bubbles.VMessageType _mapMessageType(VMessageType type) {
    switch (type) {
      case VMessageType.text:
        return bubbles.VMessageType.text;
      case VMessageType.image:
        return bubbles.VMessageType.image;
      case VMessageType.video:
        return bubbles.VMessageType.video;
      case VMessageType.voice:
        return bubbles.VMessageType.voice;
      case VMessageType.file:
        return bubbles.VMessageType.file;
      case VMessageType.location:
        return bubbles.VMessageType.location;
      case VMessageType.sticker:
        return bubbles.VMessageType.sticker;
      case VMessageType.gif:
        return bubbles.VMessageType.gif;
      case VMessageType.call:
        return bubbles.VMessageType.call;
      default:
        return bubbles.VMessageType.text;
    }
  }

  /// Map forward status to VForwardData
  static bubbles.VForwardData? mapForwardedFrom(VBaseMessage message) {
    if (!message.isForward) return null;
    return bubbles.VForwardData(
      originalMessageId: message.localId,
      originalSenderName: message.senderName,
    );
  }

  /// Map link attachment to VLinkPreviewData
  static bubbles.VLinkPreviewData? mapLinkPreview(VLinkPreviewData? linkAtt) {
    if (linkAtt == null) return null;
    final x = bubbles.VLinkPreviewData(
      url: linkAtt.link,
      title: linkAtt.title,
      description: linkAtt.description,
      image: linkAtt.image != null
          ? VPlatformFile.fromUrl(networkUrl: linkAtt.image!)
          : null,
    );
    return x;
  }

  /// Map call status to VCallStatus
  static bubbles.VCallStatus mapCallStatus(VMessageCallStatus status) {
    switch (status) {
      case VMessageCallStatus.ring:
        return bubbles.VCallStatus.incoming;
      case VMessageCallStatus.finished:
        return bubbles.VCallStatus.outgoing;
      case VMessageCallStatus.rejected:
        return bubbles.VCallStatus.declined;
      case VMessageCallStatus.canceled:
        return bubbles.VCallStatus.cancelled;
      case VMessageCallStatus.timeout:
        return bubbles.VCallStatus.missed;
      case VMessageCallStatus.inCall:
        return bubbles.VCallStatus.outgoing;
      case VMessageCallStatus.sessionEnd:
        return bubbles.VCallStatus.outgoing;
    }
  }

  /// Get avatar VPlatformFile for group messages
  /// Only shows avatar on the last message of a consecutive group (when isSameSender is false)
  static VPlatformFile? getAvatar(
      VBaseMessage message, bool isGroup, bool isSameSender) {
    if (!isGroup || message.isMeSender) return null;
    if (isSameSender) return null; // Hide avatar for grouped messages
    if (message.senderImageThumb.isEmpty) return null;
    return VPlatformFile.fromUrl(networkUrl: message.senderImageThumb);
  }

  /// Get sender name for group messages
  /// Only shows name on the last message of a consecutive group (when isSameSender is false)
  static String? getSenderName(
      VBaseMessage message, bool isGroup, bool isSameSender) {
    if (!isGroup || message.isMeSender) return null;
    if (isSameSender) return null; // Hide name for grouped messages
    return message.senderName;
  }
}
