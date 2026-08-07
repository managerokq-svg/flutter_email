import 'dart:convert';
import 'package:chopper/chopper.dart';
import 'package:uuid/uuid.dart';
import 'package:v_chat_sdk_core/src/local_db/tables/message_table.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

class VGifMessage extends VBaseMessage {
  final String url;
  final double aspectRatio;

  VGifMessage({
    required this.url,
    required this.aspectRatio,
    required String id,
    required String roomId,
    required String content,
    required String senderId,
    required String senderName,
    required String senderImageThumb,
    required VMessageType messageType,
    required String platform,
    required String localId,
    required String createdAt,
    required String updatedAt,
    required VMessageEmitStatus emitStatus,
    required bool isEncrypted,
    required bool isStared,
    String? replyTo,
    String? seenAt,
    String? deliveredAt,
    String? forwardId,
    String? allDeletedAt,
    String? parentBroadcastId,
    String? contentTr,
    VLinkPreviewData? linkAtt,
    int reactionNumber = 0,
    List<ReactionSample> reactionSample = const [],
    String? currentUserEmoji,
  }) : super(
          id: id,
          senderId: senderId,
          senderName: senderName,
          senderImageThumb: senderImageThumb,
          platform: platform,
          roomId: roomId,
          content: content,
          messageType: messageType,
          localId: localId,
          createdAt: createdAt,
          updatedAt: updatedAt,
          emitStatus: emitStatus,
          replyTo: null,
          seenAt: seenAt,
          isOneSeenByMe: false,
          isOneSeen: false,
          isDownloading: false,
          deliveredAt: deliveredAt,
          forwardId: forwardId,
          allDeletedAt: allDeletedAt,
          parentBroadcastId: parentBroadcastId,
          isStared: isStared,
          isEncrypted: isEncrypted,
          contentTr: contentTr,
          linkAtt: linkAtt,
          reactionNumber: reactionNumber,
          reactionSample: reactionSample,
          currentUserEmoji: currentUserEmoji,
        );

  VGifMessage.fromRemoteMap(Map<String, dynamic> map)
      : url = map['msgAtt']['url'] as String,
        aspectRatio = (map['msgAtt']['aspectRatio'] as num).toDouble(),
        super.fromRemoteMap(map);

  VGifMessage.fromLocalMap(Map<String, dynamic> map)
      : url = (jsonDecode(map[MessageTable.columnAttachment] as String)
            as Map<String, dynamic>)['url'] as String,
        aspectRatio = ((jsonDecode(map[MessageTable.columnAttachment] as String)
            as Map<String, dynamic>)['aspectRatio'] as num).toDouble(),
        super.fromLocalMap(map);

  @override
  Map<String, Object?> toLocalMap({
    bool withOutConTr = false,
    bool withOutIsDownload = false,
  }) {
    final map = super.toLocalMap(
      withOutConTr: withOutConTr,
      withOutIsDownload: withOutIsDownload,
    );
    map[MessageTable.columnAttachment] = jsonEncode({'url': url, 'aspectRatio': aspectRatio});
    return map;
  }

  @override
  Map<String, dynamic> toRemoteMap() {
    final map = super.toRemoteMap();
    map['msgAtt'] = {'url': url, 'aspectRatio': aspectRatio};
    return map;
  }

  @override
  List<PartValue> toListOfPartValue() {
    return [
      ...super.toListOfPartValue(),
      PartValue(
        'attachment',
        jsonEncode({'url': url, 'aspectRatio': aspectRatio}),
      ),
    ];
  }

  static VGifMessage buildMessage({
    required String roomId,
    required String url,
    required double aspectRatio,
  }) {
    return VGifMessage.fromRemoteMap({
      '_id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sId': VAppConstants.myProfile.id,
      'sName': VAppConstants.myProfile.fullName,
      'sImg': VAppConstants.myProfile.userImage,
      'plm': 'flutter',
      'rId': roomId,
      'c': 'GIF',
      'mT': 'gif',
      'createdAt': DateTime.now().toUtc().toString(),
      'updatedAt': DateTime.now().toUtc().toString(),
      'lId': const Uuid().v4(),
      'isEncrypted': false,
      'msgAtt': {
        'url': url,
        'aspectRatio': aspectRatio,
      },
    });
  }
}
