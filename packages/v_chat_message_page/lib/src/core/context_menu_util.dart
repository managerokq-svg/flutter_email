// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:open_filex/open_filex.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:share_plus/share_plus.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_bubbles/v_chat_bubbles.dart' hide VMessageType;
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

import '../page/message_pages/providers/message_provider.dart';

/// Custom menu items not available in VDefaultMenuItems
class VCustomMenuItems {
  VCustomMenuItems._();

  static const info = VBubbleMenuItem(
    id: 'info',
    label: 'Info',
    icon: CupertinoIcons.info,
  );
  static const share = VBubbleMenuItem(
    id: 'share',
    label: 'Share',
    icon: CupertinoIcons.share,
  );
  static const unStar = VBubbleMenuItem(
    id: 'unStar',
    label: 'Unstar',
    icon: CupertinoIcons.star_slash_fill,
  );
}

/// Builds context menu items based on message state and type
/// Set [includeReply] to false to exclude reply action (e.g., for secondary pages)
/// Set [includeSelect] to false to exclude select action (e.g., for secondary pages)
List<VBubbleMenuItem>? buildContextMenuItems({
  required VBaseMessage message,
  bool includeReply = true,
  bool includeSelect = true,
}) {
  final items = <VBubbleMenuItem>[];
  // If not server confirmed, only delete available
  if (!message.emitStatus.isServerConfirm) {
    items.add(VDefaultMenuItems.delete);
    return items;
  }
  // Special case: deleted message OR one-seen message
  // One-seen messages should only allow delete for both sender and receiver
  if (message.allDeletedAt != null || message.isOneSeen) {
    return [VDefaultMenuItems.delete];
  }
  // Special case: call messages
  if (message.messageType.isCall) {
    final callItems = <VBubbleMenuItem>[VDefaultMenuItems.delete];
    if (includeReply) callItems.insert(0, VDefaultMenuItems.reply);
    return callItems;
  }
  // Normal message items
  items.add(VDefaultMenuItems.forward);
  if (includeReply) {
    items.add(VDefaultMenuItems.reply);
  }
  items.add(VCustomMenuItems.share);
  if (message.isMeSender) {
    items.add(VCustomMenuItems.info);
  }
  if (message.messageType.isFile || message.messageType.isVoice) {
    items.add(VDefaultMenuItems.download);
  }
  if (message.isStared) {
    items.add(VCustomMenuItems.unStar);
  } else {
    items.add(VDefaultMenuItems.star);
  }
  if (includeSelect) {
    items.add(VDefaultMenuItems.select);
  }
  items.add(VDefaultMenuItems.delete);
  if (message.messageType.isText) {
    items.add(VDefaultMenuItems.copy);
  }
  return items;
}

/// Handles context menu action based on selected item
Future<void> handleContextMenuAction({
  required BuildContext context,
  required VBubbleMenuItem item,
  required VBaseMessage message,
  required VRoom room,
  required Function(VBaseMessage) onReply,
  required VoidCallback? onEnterSelectionMode,
  required MessageProvider messageProvider,
}) async {
  debugPrint('[handleContextMenuAction] Processing action: ${item.id}');
  debugPrint(
      '[handleContextMenuAction] Message ID: ${message.id}, LocalID: ${message.localId}');
  debugPrint(
      '[handleContextMenuAction] Room ID: ${room.id}, Room Type: ${room.roomType}');
  debugPrint('[handleContextMenuAction] Context mounted: ${context.mounted}');
  try {
    switch (item.id) {
      case 'forward':
        debugPrint('[handleContextMenuAction] Calling _handleForward');
        await _handleForward(context, message);
        break;
      case 'reply':
        debugPrint('[handleContextMenuAction] Calling onReply');
        onReply(message);
        break;
      case 'share':
        debugPrint('[handleContextMenuAction] Calling _handleShare');
        await _handleShare(message);
        break;
      case 'info':
        debugPrint('[handleContextMenuAction] Calling _handleInfo');
        await _handleInfo(context, message, room);
        break;
      case 'delete':
        debugPrint('[handleContextMenuAction] Calling _handleDelete');
        await _handleDelete(context, message, messageProvider);
        break;
      case 'copy':
        debugPrint('[handleContextMenuAction] Calling _handleCopy');
        await _handleCopy(message);
        break;
      case 'download':
        debugPrint('[handleContextMenuAction] Calling _handleDownload');
        await _handleDownload(context, message);
        break;
      case 'star':
        debugPrint('[handleContextMenuAction] Calling _handleStar');
        await _handleStar(message);
        break;
      case 'unStar':
        debugPrint('[handleContextMenuAction] Calling _handleUnStar');
        await _handleUnStar(message);
        break;
      case 'select':
        debugPrint('[handleContextMenuAction] Calling onEnterSelectionMode');
        onEnterSelectionMode?.call();
        break;
      default:
        debugPrint('[handleContextMenuAction] Unknown action: ${item.id}');
    }
    debugPrint('[handleContextMenuAction] Action completed successfully');
  } catch (e, stack) {
    debugPrint('[handleContextMenuAction] ERROR: $e');
    debugPrint('[handleContextMenuAction] Stack: $stack');
  }
}

Future<void> _handleForward(
    BuildContext context, VBaseMessage baseMessage) async {
  debugPrint('[_handleForward] Starting forward action');
  debugPrint('[_handleForward] Context mounted: ${context.mounted}');
  // Small delay to ensure context menu fully closes (fixes release mode issue)
  await Future.delayed(const Duration(milliseconds: 50));
  if (!context.mounted) {
    debugPrint('[_handleForward] Context unmounted after delay, aborting');
    return;
  }
  final localStorage = VChatController.I.nativeApi.local;
  debugPrint('[_handleForward] Calling toForwardPage...');
  final ids = await VChatController.I.vNavigator.roomNavigator
      .toForwardPage(context, baseMessage.roomId);
  debugPrint('[_handleForward] toForwardPage returned: $ids');
  if (ids != null) {
    for (final roomId in ids) {
      VBaseMessage? message;
      switch (baseMessage.messageType) {
        case VMessageType.text:
          message = VTextMessage.buildMessage(
            content: baseMessage.realContent,
            roomId: roomId,
            linkAtt: baseMessage.linkAtt,
            forwardId: baseMessage.localId,
            isEncrypted: baseMessage.isEncrypted,
          );
          break;
        case VMessageType.image:
          message = VImageMessage.buildMessage(
            data: (baseMessage as VImageMessage).data,
            roomId: roomId,
            forwardId: baseMessage.localId,
          );
          break;
        case VMessageType.file:
          message = VFileMessage.buildMessage(
            data: (baseMessage as VFileMessage).data,
            roomId: roomId,
            forwardId: baseMessage.localId,
          );
          break;
        case VMessageType.video:
          message = VVideoMessage.buildMessage(
            data: (baseMessage as VVideoMessage).data,
            roomId: roomId,
            forwardId: baseMessage.localId,
          );
          break;
        case VMessageType.voice:
          message = VVoiceMessage.buildMessage(
            data: (baseMessage as VVoiceMessage).data,
            roomId: roomId,
            content: baseMessage.realContent,
            forwardId: baseMessage.localId,
          );
          break;
        case VMessageType.location:
          message = VLocationMessage.buildMessage(
            data: (baseMessage as VLocationMessage).data,
            roomId: roomId,
            forwardId: baseMessage.localId,
          );
          break;
        case VMessageType.custom:
          message = VCustomMessage.buildMessage(
            data: (baseMessage as VCustomMessage).data,
            content: baseMessage.realContent,
            roomId: roomId,
          );
          break;
        case VMessageType.call:
        case VMessageType.info:
        case VMessageType.bug:
        case VMessageType.reaction:
        case VMessageType.storyReply:
        case VMessageType.sticker:
        case VMessageType.gif:
          break;
      }
      if (message != null) {
        await localStorage.message.insertMessage(message);
        VMessageUploaderQueue.instance.addToQueue(
          await MessageFactory.createForwardUploadMessage(message),
        );
      }
    }
  }
}

Future<void> _handleShare(VBaseMessage message) async {
  if (!message.emitStatus.isServerConfirm) return;
  if (message is VTextMessage) {
    await SharePlus.instance.share(ShareParams(text: message.realContent));
    return;
  }
  if (message is VLocationMessage) {
    await SharePlus.instance
        .share(ShareParams(text: message.data.linkPreviewData.link.toString()));
    return;
  }
  late final VPlatformFile pFile;
  if (message is VImageMessage) {
    pFile = message.data.fileSource;
  } else if (message is VVoiceMessage) {
    pFile = message.data.fileSource;
  } else if (message is VFileMessage) {
    pFile = message.data.fileSource;
  } else if (message is VVideoMessage) {
    pFile = message.data.fileSource;
  } else {
    return;
  }
  final file = await DefaultCacheManager().getSingleFile(
    pFile.fullNetworkUrl!,
  );
  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}

Future<void> _handleInfo(BuildContext context, VBaseMessage message, VRoom room) async {
  debugPrint('[_handleInfo] Starting info action');
  debugPrint('[_handleInfo] Context mounted: ${context.mounted}');
  debugPrint('[_handleInfo] Room type: ${room.roomType}');
  // Small delay to ensure context menu fully closes (fixes release mode issue)
  await Future.delayed(const Duration(milliseconds: 50));
  if (!context.mounted) {
    debugPrint('[_handleInfo] Context unmounted after delay, aborting');
    return;
  }
  FocusScope.of(context).unfocus();
  if (room.roomType.isSingleOrOrder) {
    debugPrint('[_handleInfo] Navigating to SingleChatMessageInfo');
    VChatController.I.vNavigator.messageNavigator.toSingleChatMessageInfo(
      context,
      message,
    );
  } else if (room.roomType.isGroup) {
    debugPrint('[_handleInfo] Navigating to GroupChatMessageInfo');
    VChatController.I.vNavigator.messageNavigator.toGroupChatMessageInfo(
      context,
      message,
    );
  } else if (room.roomType.isBroadcast) {
    debugPrint('[_handleInfo] Navigating to BroadcastChatMessageInfo');
    VChatController.I.vNavigator.messageNavigator.toBroadcastChatMessageInfo(
      context,
      message,
    );
  } else {
    debugPrint('[_handleInfo] No matching room type for navigation');
  }
}

Future<void> _handleDelete(
  BuildContext context,
  VBaseMessage message,
  MessageProvider messageProvider,
) async {
  debugPrint('[_handleDelete] Starting delete action');
  debugPrint('[_handleDelete] Context mounted: ${context.mounted}');
  debugPrint(
      '[_handleDelete] isMeSender: ${message.isMeSender}, isAllDeleted: ${message.isAllDeleted}');
  // Small delay to ensure context menu fully closes (fixes release mode issue)
  await Future.delayed(const Duration(milliseconds: 50));
  if (!context.mounted) {
    debugPrint('[_handleDelete] Context unmounted after delay, aborting');
    return;
  }
  final l = <ModelSheetItem>[];
  if (message.isMeSender &&
      !message.isAllDeleted &&
      message.emitStatus.isServerConfirm) {
    l.add(ModelSheetItem(title: S.current.deleteFromAll, id: 1));
  }
  l.add(ModelSheetItem(title: S.current.deleteFromMe, id: 2));
  debugPrint('[_handleDelete] Showing modal with ${l.length} options');
  final res = await VAppAlert.showModalSheetWithActions(
    content: l,
    context: context,
    cancelLabel: S.current.cancel,
  );
  debugPrint('[_handleDelete] Modal result: $res');
  if (res == null) return;
  if (res.id == 1) {
    await vSafeApiCall(
      request: () async {
        return messageProvider.deleteMessageFromAll(
          message.roomId,
          message.id,
        );
      },
      onSuccess: (response) {},
    );
  }
  if (res.id == 2) {
    await vSafeApiCall(
      request: () async {
        return messageProvider.deleteMessageFromMe(message);
      },
      onSuccess: (response) {},
    );
  }
}

Future<void> _handleCopy(VBaseMessage message) async {
  await Clipboard.setData(
    ClipboardData(
      text: message.realContentMentionParsedWithAt,
    ),
  );
}

Future<void> _handleDownload(BuildContext context, VBaseMessage message) async {
  if (!message.emitStatus.isServerConfirm) return;
  await vSafeApiCall<String>(
    onLoading: () {
      VAppAlert.showSuccessSnackBar(
        message: S.current.downloading,
        context: context,
      );
    },
    request: () async {
      return VDownloaderService.instance.addToQueue(message);
    },
    onSuccess: (url) async {
      if (VPlatforms.isMobile) {
        await OpenFilex.open(url);
      }
      VAppAlert.showSuccessSnackBar(
        message: S.current.fileHasBeenSavedTo + url,
        context: context,
      );
    },
    onError: (exception) {},
  );
}

Future<void> _handleStar(VBaseMessage message) async {
  await vSafeApiCall<void>(
    request: () async {
      await VChatController.I.nativeApi.remote.message.starMessage(
        message.roomId,
        message.id,
      );
      await VChatController.I.nativeApi.local.message.updateMessageStar(
        VUpdateMessageStarEvent(
          roomId: message.roomId,
          localId: message.localId,
          isStar: true,
        ),
      );
    },
    onSuccess: (url) async {},
  );
}

Future<void> _handleUnStar(VBaseMessage message) async {
  await vSafeApiCall<void>(
    request: () async {
      await VChatController.I.nativeApi.remote.message.unStarMessage(
        message.roomId,
        message.id,
      );
      await VChatController.I.nativeApi.local.message.updateMessageStar(
        VUpdateMessageStarEvent(
          roomId: message.roomId,
          localId: message.localId,
          isStar: false,
        ),
      );
    },
    onSuccess: (url) async {},
  );
}

/// Forward message to a specific room (used externally)
Future<void> forwardMessageToRoom(
    VBaseMessage baseMessage, String roomId) async {
  final localStorage = VChatController.I.nativeApi.local;
  VBaseMessage? message;
  switch (baseMessage.messageType) {
    case VMessageType.text:
      message = VTextMessage.buildMessage(
        content: baseMessage.realContent,
        roomId: roomId,
        linkAtt: baseMessage.linkAtt,
        forwardId: baseMessage.localId,
        isEncrypted: baseMessage.isEncrypted,
      );
      break;
    case VMessageType.image:
      message = VImageMessage.buildMessage(
        data: (baseMessage as VImageMessage).data,
        roomId: roomId,
        forwardId: baseMessage.localId,
      );
      break;
    case VMessageType.file:
      message = VFileMessage.buildMessage(
        data: (baseMessage as VFileMessage).data,
        roomId: roomId,
        forwardId: baseMessage.localId,
      );
      break;
    case VMessageType.video:
      message = VVideoMessage.buildMessage(
        data: (baseMessage as VVideoMessage).data,
        roomId: roomId,
        forwardId: baseMessage.localId,
      );
      break;
    case VMessageType.voice:
      message = VVoiceMessage.buildMessage(
        data: (baseMessage as VVoiceMessage).data,
        roomId: roomId,
        content: baseMessage.realContent,
        forwardId: baseMessage.localId,
      );
      break;
    case VMessageType.location:
      message = VLocationMessage.buildMessage(
        data: (baseMessage as VLocationMessage).data,
        roomId: roomId,
        forwardId: baseMessage.localId,
      );
      break;
    case VMessageType.custom:
      message = VCustomMessage.buildMessage(
        data: (baseMessage as VCustomMessage).data,
        content: baseMessage.realContent,
        roomId: roomId,
      );
      break;
    case VMessageType.call:
    case VMessageType.info:
    case VMessageType.bug:
    case VMessageType.reaction:
    case VMessageType.storyReply:
    case VMessageType.sticker:
    case VMessageType.gif:
      break;
  }
  if (message != null) {
    await localStorage.message.insertMessage(message);
    VMessageUploaderQueue.instance.addToQueue(
      await MessageFactory.createForwardUploadMessage(message),
    );
  }
}
