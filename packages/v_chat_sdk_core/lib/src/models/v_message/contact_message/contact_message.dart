// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:v_chat_sdk_core/src/local_db/tables/message_table.dart';
import 'package:v_chat_sdk_core/src/utils/v_message_constants.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

import 'v_contact_message_data.dart';

class VContactMessage extends VBaseMessage {
  final VContactMessageData data;

  VContactMessage({
    required super.id,
    required super.senderId,
    required super.linkAtt,
    required super.emitStatus,
    required super.senderName,
    required super.senderImageThumb,
    required super.platform,
    required super.roomId,
    required super.content,
    required super.contentTr,
    required super.messageType,
    required super.localId,
    required super.createdAt,
    required super.isEncrypted,
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

  VContactMessage.fromRemoteMap(super.map)
      : data = VContactMessageData.fromMap(
          map['msgAtt'] as Map<String, dynamic>,
        ),
        super.fromRemoteMap();

  VContactMessage.fromLocalMap(super.map)
      : data = VContactMessageData.fromMap(
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

  @override
  List<PartValue> toListOfPartValue() {
    return [
      ...super.toListOfPartValue(),
      PartValue(
        'attachment',
        jsonEncode(data.toMap()),
      ),
    ];
  }

  VContactMessage.buildMessage({
    required super.roomId,
    required this.data,
    super.forwardId,
    super.broadcastId,
    super.replyTo,
  }) : super.buildMessage(
          isEncrypted: false,
          linkAtt: null,
          content: "${VMessageConstants.thisContentIsContact} ${data.displayName}",
          messageType: VMessageType.contact,
        );
}
