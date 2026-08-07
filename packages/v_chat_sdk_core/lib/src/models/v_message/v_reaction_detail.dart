// Copyright 2025, the hatemragab project.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

/// Model representing detailed reaction info with user data
@immutable
class VReactionDetail {
  final String emoji;
  final VReactionUser user;
  final DateTime createdAt;

  const VReactionDetail({
    required this.emoji,
    required this.user,
    required this.createdAt,
  });

  factory VReactionDetail.fromMap(Map<String, dynamic> map) {
    return VReactionDetail(
      emoji: map['emoji'] as String,
      user: VReactionUser.fromMap(map['user'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emoji': emoji,
      'user': user.toMap(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VReactionDetail &&
        other.emoji == emoji &&
        other.user == user &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => emoji.hashCode ^ user.hashCode ^ createdAt.hashCode;

  @override
  String toString() =>
      'VReactionDetail(emoji: $emoji, user: $user, createdAt: $createdAt)';
}

/// Model representing user info in a reaction
@immutable
class VReactionUser {
  final String id;
  final String fullName;
  final String userImage;

  const VReactionUser({
    required this.id,
    required this.fullName,
    required this.userImage,
  });

  factory VReactionUser.fromMap(Map<String, dynamic> map) {
    return VReactionUser(
      id: map['_id'] as String,
      fullName: map['fullName'] as String,
      userImage: map['userImage'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'fullName': fullName,
      'userImage': userImage,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VReactionUser &&
        other.id == id &&
        other.fullName == fullName &&
        other.userImage == userImage;
  }

  @override
  int get hashCode => id.hashCode ^ fullName.hashCode ^ userImage.hashCode;

  @override
  String toString() =>
      'VReactionUser(id: $id, fullName: $fullName, userImage: $userImage)';
}
