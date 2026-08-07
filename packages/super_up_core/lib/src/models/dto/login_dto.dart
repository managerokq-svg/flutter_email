// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import '../../../super_up_core.dart';

class LoginDto {
  final String email;
  final Map<String, dynamic> deviceInfo;
  final String deviceId;
  final String language;
  String? pushKey;
  final RegisterMethod method;
  final String platform;
  final String password;

  LoginDto({
    required this.email,
    required this.deviceId,
    required this.language,
    required this.method,
    required this.platform,
    required this.password,
    required this.deviceInfo,
    this.pushKey,
  });

  Map<String, dynamic> toMap() {
    return {
      "email": email,
      "deviceId": deviceId,
      "deviceInfo": deviceInfo,
      "language": language,
      "pushKey": pushKey,
      "password": password,
      "method": method.name,
      "platform": platform,
    };
  }
}
