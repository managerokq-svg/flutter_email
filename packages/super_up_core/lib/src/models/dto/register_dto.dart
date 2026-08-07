// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:super_up_core/src/utils/enums.dart';
import 'package:v_platform/v_platform.dart';

class RegisterDto {
  final String email;
  final String fullName;
  final String deviceId;
  final RegisterMethod method;
  final String language;
  final Map<String, dynamic> deviceInfo;
  String? pushKey;
  final String platform;
  final String password;
  final VPlatformFile? image;

//<editor-fold desc="Data Methods">

  RegisterDto({
    required this.email,
    required this.method,
    required this.fullName,
    required this.deviceId,
    required this.language,
    required this.pushKey,
    required this.deviceInfo,
    required this.platform,
    required this.password,
    this.image,
  });

  List<PartValue> toListOfPartValue() {
    return [
      PartValue('email', email),
      PartValue('method', method.name),
      PartValue('fullName', fullName),
      PartValue('deviceId', deviceId),
      PartValue('password', password),
      PartValue('language', language),
      PartValue('pushKey', pushKey),
      PartValue('deviceInfo', jsonEncode(deviceInfo)),
      PartValue('platform', platform),
    ];
  }

//</editor-fold>
}
