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
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:v_platform/v_platform.dart';

/// Builds action menu items for media/starred message views
List<ModelSheetItem<String>> buildMediaItemActions(
  BuildContext context,
  VBaseMessage message,
) {
  final items = <ModelSheetItem<String>>[];
  // If not server confirmed or deleted, only delete available
  if (!message.emitStatus.isServerConfirm || message.allDeletedAt != null) {
    items.add(ModelSheetItem(title: S.of(context).delete, id: 'delete'));
    return items;
  }
  // Forward action
  items.add(ModelSheetItem(
    title: S.of(context).forward,
    id: 'forward',
    iconData: const Icon(CupertinoIcons.arrowshape_turn_up_right),
  ));
  // Share action
  items.add(ModelSheetItem(
    title: S.of(context).share,
    id: 'share',
    iconData: const Icon(CupertinoIcons.share),
  ));
  // Copy for text messages
  if (message.messageType.isText) {
    items.add(ModelSheetItem(
      title: S.of(context).copy,
      id: 'copy',
      iconData: const Icon(CupertinoIcons.doc_on_doc),
    ));
  }
  // Download for file/voice messages
  if (message.messageType.isFile || message.messageType.isVoice) {
    items.add(ModelSheetItem(
      title: S.of(context).download,
      id: 'download',
      iconData: const Icon(CupertinoIcons.cloud_download),
    ));
  }
  // Star/Unstar toggle
  if (message.isStared) {
    items.add(ModelSheetItem(
      title: S.of(context).unStar,
      id: 'unstar',
      iconData: const Icon(CupertinoIcons.star_slash_fill),
    ));
  } else {
    items.add(ModelSheetItem(
      title: S.of(context).star,
      id: 'star',
      iconData: const Icon(CupertinoIcons.star),
    ));
  }
  // Info action (only for sender)
  if (message.isMeSender) {
    items.add(ModelSheetItem(
      title: S.of(context).info,
      id: 'info',
      iconData: const Icon(CupertinoIcons.info),
    ));
  }
  // Delete action
  items.add(ModelSheetItem(
    title: S.of(context).delete,
    id: 'delete',
    iconData: const Icon(CupertinoIcons.trash),
  ));
  return items;
}

/// Shows action menu and handles selected action for media/starred views
Future<void> showMediaItemActions({
  required BuildContext context,
  required VBaseMessage message,
  required VoidCallback onRefresh,
}) async {
  final actions = buildMediaItemActions(context, message);
  final result = await VAppAlert.showModalSheetWithActions<String>(
    content: actions,
    context: context,
    cancelLabel: S.of(context).cancel,
  );
  if (result == null || !context.mounted) return;
  await handleMediaItemAction(
    context: context,
    action: result.id,
    message: message,
    onRefresh: onRefresh,
  );
}

/// Handles selected action for media/starred message views
Future<void> handleMediaItemAction({
  required BuildContext context,
  required String action,
  required VBaseMessage message,
  required VoidCallback onRefresh,
}) async {
  switch (action) {
    case 'forward':
      await _handleForward(context, message);
      break;
    case 'share':
      await _handleShare(message);
      break;
    case 'copy':
      await _handleCopy(context, message);
      break;
    case 'download':
      await _handleDownload(context, message);
      break;
    case 'star':
      await _handleStar(message);
      onRefresh();
      break;
    case 'unstar':
    case 'unStar':
      await _handleUnStar(message);
      onRefresh();
      break;
    case 'info':
      await _handleInfo(context, message);
      break;
    case 'delete':
      await _handleDelete(context, message, onRefresh);
      break;
  }
}

Future<void> _handleForward(BuildContext context, VBaseMessage baseMessage) async {
  // Small delay to ensure context menu fully closes (fixes release mode issue)
  await Future.delayed(const Duration(milliseconds: 50));
  if (!context.mounted) return;
  final localStorage = VChatController.I.nativeApi.local;
  final ids = await VChatController.I.vNavigator.roomNavigator
      .toForwardPage(context, baseMessage.roomId);
  if (ids == null) return;
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
      case VMessageType.contact:
        message = VContactMessage.buildMessage(
          data: (baseMessage as VContactMessage).data,
          roomId: roomId,
          forwardId: baseMessage.localId,
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

Future<void> _handleShare(VBaseMessage message) async {
  if (!message.emitStatus.isServerConfirm) return;
  if (message is VTextMessage) {
    await SharePlus.instance.share(ShareParams(text: message.realContent));
    return;
  }
  if (message is VLocationMessage) {
    await SharePlus.instance.share(
      ShareParams(text: message.data.linkPreviewData.link.toString()),
    );
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

Future<void> _handleCopy(BuildContext context, VBaseMessage message) async {
  await Clipboard.setData(
    ClipboardData(text: message.realContentMentionParsedWithAt),
  );
  if (!context.mounted) return;
  VAppAlert.showSuccessSnackBar(
    context: context,
    message: S.of(context).success,
  );
}

Future<void> _handleDownload(BuildContext context, VBaseMessage message) async {
  if (!message.emitStatus.isServerConfirm) return;
  await vSafeApiCall<String>(
    onLoading: () {
      VAppAlert.showSuccessSnackBar(
        message: S.of(context).downloading,
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
      if (!context.mounted) return;
      VAppAlert.showSuccessSnackBar(
        message: S.of(context).fileHasBeenSavedTo + url,
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
    onSuccess: (_) {},
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
    onSuccess: (_) {},
  );
}

Future<void> _handleInfo(BuildContext context, VBaseMessage message) async {
  // Small delay to ensure context menu fully closes (fixes release mode issue)
  await Future.delayed(const Duration(milliseconds: 50));
  if (!context.mounted) return;
  // Get room to determine type
  final room = await VChatController.I.nativeApi.local.room
      .getOneWithLastMessageByRoomId(message.roomId);
  if (room == null) return;
  if (!context.mounted) return;
  FocusScope.of(context).unfocus();
  if (room.roomType.isSingleOrOrder) {
    VChatController.I.vNavigator.messageNavigator.toSingleChatMessageInfo(
      context,
      message,
    );
  } else if (room.roomType.isGroup) {
    VChatController.I.vNavigator.messageNavigator.toGroupChatMessageInfo(
      context,
      message,
    );
  } else if (room.roomType.isBroadcast) {
    VChatController.I.vNavigator.messageNavigator.toBroadcastChatMessageInfo(
      context,
      message,
    );
  }
}

Future<void> _handleDelete(
  BuildContext context,
  VBaseMessage message,
  VoidCallback onRefresh,
) async {
  // Small delay to ensure context menu fully closes (fixes release mode issue)
  await Future.delayed(const Duration(milliseconds: 50));
  if (!context.mounted) return;
  final l = <ModelSheetItem>[];
  if (message.isMeSender &&
      !message.isAllDeleted &&
      message.emitStatus.isServerConfirm) {
    l.add(ModelSheetItem(title: S.of(context).deleteFromAll, id: 1));
  }
  l.add(ModelSheetItem(title: S.of(context).deleteFromMe, id: 2));
  final res = await VAppAlert.showModalSheetWithActions(
    content: l,
    context: context,
    cancelLabel: S.of(context).cancel,
  );
  if (res == null) return;
  if (res.id == 1) {
    await vSafeApiCall(
      request: () async {
        await VChatController.I.nativeApi.remote.message.deleteMessageFromAll(
          message.roomId,
          message.id,
        );
      },
      onSuccess: (_) => onRefresh(),
    );
  }
  if (res.id == 2) {
    await vSafeApiCall(
      request: () async {
        await VChatController.I.nativeApi.local.message
            .deleteMessageByLocalId(message);
      },
      onSuccess: (_) => onRefresh(),
    );
  }
}
