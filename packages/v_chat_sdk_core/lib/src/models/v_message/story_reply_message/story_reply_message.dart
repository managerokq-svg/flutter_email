// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:v_chat_sdk_core/src/local_db/tables/message_table.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

class VStoryReplyMessage extends VBaseMessage {
  final VStoryReplyMsgData data;

  VStoryReplyMessage({
    required super.id,
    required super.linkAtt,
    required super.senderId,
    required super.senderName,
    required super.contentTr,
    required super.emitStatus,
    required super.isEncrypted,
    required super.senderImageThumb,
    required super.platform,
    required super.roomId,
    required super.content,
    required super.messageType,
    required super.localId,
    required super.createdAt,
    required super.updatedAt,
    required super.replyTo,
    required super.seenAt,
    required super.deliveredAt,
    required super.forwardId,
    required super.allDeletedAt,
    required super.parentBroadcastId,
    required super.isStared,
    required this.data,
  });

  VStoryReplyMessage.fromRemoteMap(super.map)
      : data =
            VStoryReplyMsgData.fromMap(map['msgAtt'] as Map<String, dynamic>),
        super.fromRemoteMap();

  VStoryReplyMessage.fromLocalMap(super.map)
      : data = VStoryReplyMsgData.fromMap(
          jsonDecode(map[MessageTable.columnAttachment] as String)
              as Map<String, dynamic>,
        ),
        super.fromLocalMap();

  @override
  Map<String, dynamic> toLocalMap({
    bool withOutConTr = false,
    bool withOutIsDownload = false,
  }) {
    return {
      ...super.toLocalMap(),
      MessageTable.columnAttachment: jsonEncode(data.toMap()),
    };
  }
}
