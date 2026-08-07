// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:v_platform/v_platform.dart';

/// Handles tap on file message - downloads and opens the file
Future<void> handleFileTap(BuildContext context, VBaseMessage message) async {
  if (!message.emitStatus.isServerConfirm) return;
  await vSafeApiCall<String>(
    onLoading: () {
      VAppAlert.showSuccessSnackBar(
        context: context,
        message: S.of(context).downloading,
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
        message: S.of(context).success,
        context: context,
      );
    },
    onError: (exception) {},
  );
}

/// Handles tap on location message - opens map app
Future<void> handleLocationTap(VLocationMessage message) async {
  await VStringUtils.lunchMap(
    latitude: message.data.latLng.latitude,
    longitude: message.data.latLng.longitude,
    title: message.data.linkPreviewData.title,
    description: message.data.linkPreviewData.description,
  );
}

/// Handles tap on any tappable message type
void handleMessageTap(BuildContext context, VBaseMessage message) {
  if (message is VImageMessage) {
    VChatController.I.vNavigator.messageNavigator.toImageViewer(
      context,
      message.data.fileSource,
      true,
    );
  } else if (message is VVideoMessage) {
    VChatController.I.vNavigator.messageNavigator.toVideoPlayer(
      context,
      message.data.fileSource,
      true,
    );
  } else if (message is VFileMessage) {
    handleFileTap(context, message);
  } else if (message is VLocationMessage) {
    handleLocationTap(message);
  }
}
