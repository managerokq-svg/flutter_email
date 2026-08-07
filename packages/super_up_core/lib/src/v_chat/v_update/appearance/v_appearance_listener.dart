// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../../super_up_core.dart';

class VAppearanceListener extends ValueNotifier<AppearanceSettings> {
  VAppearanceListener._() : super(AppearanceSettings.defaults) {
    _loadFromPrefs();
  }

  static final _instance = VAppearanceListener._();

  static VAppearanceListener get I => _instance;

  void _loadFromPrefs() {
    final messageFontSize = VAppPref.getDoubleOrNull(
      SStorageKeys.appearanceMessageFontSize.name,
    );
    final senderNameFontSize = VAppPref.getDoubleOrNull(
      SStorageKeys.appearanceSenderNameFontSize.name,
    );
    final lightSenderColor = VAppPref.getIntOrNull(
      SStorageKeys.appearanceLightSenderColor.name,
    );
    final lightReceiverColor = VAppPref.getIntOrNull(
      SStorageKeys.appearanceLightReceiverColor.name,
    );
    final darkSenderColor = VAppPref.getIntOrNull(
      SStorageKeys.appearanceDarkSenderColor.name,
    );
    final darkReceiverColor = VAppPref.getIntOrNull(
      SStorageKeys.appearanceDarkReceiverColor.name,
    );
    value = AppearanceSettings(
      messageFontSize: messageFontSize ?? AppearanceSettings.defaultMessageFontSize,
      senderNameFontSize: senderNameFontSize ?? AppearanceSettings.defaultSenderNameFontSize,
      lightSenderColor: lightSenderColor != null
          ? Color(lightSenderColor)
          : AppearanceSettings.defaultLightSenderColor,
      lightReceiverColor: lightReceiverColor != null
          ? Color(lightReceiverColor)
          : AppearanceSettings.defaultLightReceiverColor,
      darkSenderColor: darkSenderColor != null
          ? Color(darkSenderColor)
          : AppearanceSettings.defaultDarkSenderColor,
      darkReceiverColor: darkReceiverColor != null
          ? Color(darkReceiverColor)
          : AppearanceSettings.defaultDarkReceiverColor,
    );
  }

  Future<void> setMessageFontSize(double size) async {
    await VAppPref.setDouble(SStorageKeys.appearanceMessageFontSize.name, size);
    value = value.copyWith(messageFontSize: size);
  }

  Future<void> setSenderNameFontSize(double size) async {
    await VAppPref.setDouble(SStorageKeys.appearanceSenderNameFontSize.name, size);
    value = value.copyWith(senderNameFontSize: size);
  }

  Future<void> setLightSenderColor(Color color) async {
    await VAppPref.setInt(SStorageKeys.appearanceLightSenderColor.name, color.toARGB32());
    value = value.copyWith(lightSenderColor: color);
  }

  Future<void> setLightReceiverColor(Color color) async {
    await VAppPref.setInt(SStorageKeys.appearanceLightReceiverColor.name, color.toARGB32());
    value = value.copyWith(lightReceiverColor: color);
  }

  Future<void> setDarkSenderColor(Color color) async {
    await VAppPref.setInt(SStorageKeys.appearanceDarkSenderColor.name, color.toARGB32());
    value = value.copyWith(darkSenderColor: color);
  }

  Future<void> setDarkReceiverColor(Color color) async {
    await VAppPref.setInt(SStorageKeys.appearanceDarkReceiverColor.name, color.toARGB32());
    value = value.copyWith(darkReceiverColor: color);
  }

  Future<void> resetToDefaults() async {
    await Future.wait([
      VAppPref.removeKey(SStorageKeys.appearanceMessageFontSize.name),
      VAppPref.removeKey(SStorageKeys.appearanceSenderNameFontSize.name),
      VAppPref.removeKey(SStorageKeys.appearanceLightSenderColor.name),
      VAppPref.removeKey(SStorageKeys.appearanceLightReceiverColor.name),
      VAppPref.removeKey(SStorageKeys.appearanceDarkSenderColor.name),
      VAppPref.removeKey(SStorageKeys.appearanceDarkReceiverColor.name),
    ]);
    value = AppearanceSettings.defaults;
  }
}
