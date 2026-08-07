// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

class VStoryReplyMsgData {
  final String storyId;
  final String storyOwnerId;
  final String storyOwnerName;
  final String storyOwnerImage;
  final String storyType;
  final String? storyContent;
  final Map<String, dynamic>? storyAtt;
  final String? storyCaption;

  VStoryReplyMsgData({
    required this.storyId,
    required this.storyOwnerId,
    required this.storyOwnerName,
    required this.storyOwnerImage,
    required this.storyType,
    this.storyContent,
    this.storyAtt,
    this.storyCaption,
  });

  @override
  String toString() {
    return 'VStoryReplyMsgData{storyId: $storyId, storyOwnerId: $storyOwnerId, storyType: $storyType}';
  }

  Map<String, dynamic> toMap() {
    return {
      'storyId': storyId,
      'storyOwnerId': storyOwnerId,
      'storyOwnerName': storyOwnerName,
      'storyOwnerImage': storyOwnerImage,
      'storyType': storyType,
      'storyContent': storyContent,
      'storyAtt': storyAtt,
      'storyCaption': storyCaption,
    };
  }

  factory VStoryReplyMsgData.fromMap(Map<String, dynamic> map) {
    return VStoryReplyMsgData(
      storyId: map['storyId'] as String,
      storyOwnerId: map['storyOwnerId'] as String,
      storyOwnerName: map['storyOwnerName'] as String,
      storyOwnerImage: map['storyOwnerImage'] as String,
      storyType: map['storyType'] as String,
      storyContent: map['storyContent'] as String?,
      storyAtt: map['storyAtt'] as Map<String, dynamic>?,
      storyCaption: map['storyCaption'] as String?,
    );
  }

  bool get isTextStory => storyType == 'text';

  bool get isImageStory => storyType == 'image';

  String? get storyImageUrl => storyAtt?['url'] as String?;
}
