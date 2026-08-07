// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:ui';

class AppearanceSettings {
  final double messageFontSize;
  final double senderNameFontSize;
  final Color lightSenderColor;
  final Color lightReceiverColor;
  final Color darkSenderColor;
  final Color darkReceiverColor;

  const AppearanceSettings({
    required this.messageFontSize,
    required this.senderNameFontSize,
    required this.lightSenderColor,
    required this.lightReceiverColor,
    required this.darkSenderColor,
    required this.darkReceiverColor,
  });

  static const double defaultMessageFontSize = 15.0;
  static const double defaultSenderNameFontSize = 14.0;
  static const Color defaultLightSenderColor = Color(0xFFD9FDD3);
  static const Color defaultLightReceiverColor = Color(0xFFFFFFFF);
  static const Color defaultDarkSenderColor = Color(0xFF005C4B);
  static const Color defaultDarkReceiverColor = Color(0xFF202C33);

  static const double minMessageFontSize = 12.0;
  static const double maxMessageFontSize = 24.0;
  static const double minSenderNameFontSize = 10.0;
  static const double maxSenderNameFontSize = 18.0;

  static AppearanceSettings get defaults => const AppearanceSettings(
        messageFontSize: defaultMessageFontSize,
        senderNameFontSize: defaultSenderNameFontSize,
        lightSenderColor: defaultLightSenderColor,
        lightReceiverColor: defaultLightReceiverColor,
        darkSenderColor: defaultDarkSenderColor,
        darkReceiverColor: defaultDarkReceiverColor,
      );

  AppearanceSettings copyWith({
    double? messageFontSize,
    double? senderNameFontSize,
    Color? lightSenderColor,
    Color? lightReceiverColor,
    Color? darkSenderColor,
    Color? darkReceiverColor,
  }) =>
      AppearanceSettings(
        messageFontSize: messageFontSize ?? this.messageFontSize,
        senderNameFontSize: senderNameFontSize ?? this.senderNameFontSize,
        lightSenderColor: lightSenderColor ?? this.lightSenderColor,
        lightReceiverColor: lightReceiverColor ?? this.lightReceiverColor,
        darkSenderColor: darkSenderColor ?? this.darkSenderColor,
        darkReceiverColor: darkReceiverColor ?? this.darkReceiverColor,
      );

  Map<String, dynamic> toMap() => {
        'messageFontSize': messageFontSize,
        'senderNameFontSize': senderNameFontSize,
        'lightSenderColor': lightSenderColor.toARGB32(),
        'lightReceiverColor': lightReceiverColor.toARGB32(),
        'darkSenderColor': darkSenderColor.toARGB32(),
        'darkReceiverColor': darkReceiverColor.toARGB32(),
      };

  factory AppearanceSettings.fromMap(Map<String, dynamic> map) =>
      AppearanceSettings(
        messageFontSize: (map['messageFontSize'] as num?)?.toDouble() ??
            defaultMessageFontSize,
        senderNameFontSize: (map['senderNameFontSize'] as num?)?.toDouble() ??
            defaultSenderNameFontSize,
        lightSenderColor: Color(map['lightSenderColor'] as int? ??
            defaultLightSenderColor.toARGB32()),
        lightReceiverColor: Color(map['lightReceiverColor'] as int? ??
            defaultLightReceiverColor.toARGB32()),
        darkSenderColor: Color(map['darkSenderColor'] as int? ??
            defaultDarkSenderColor.toARGB32()),
        darkReceiverColor: Color(map['darkReceiverColor'] as int? ??
            defaultDarkReceiverColor.toARGB32()),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppearanceSettings &&
          runtimeType == other.runtimeType &&
          messageFontSize == other.messageFontSize &&
          senderNameFontSize == other.senderNameFontSize &&
          lightSenderColor == other.lightSenderColor &&
          lightReceiverColor == other.lightReceiverColor &&
          darkSenderColor == other.darkSenderColor &&
          darkReceiverColor == other.darkReceiverColor;

  @override
  int get hashCode => Object.hash(
        messageFontSize,
        senderNameFontSize,
        lightSenderColor,
        lightReceiverColor,
        darkSenderColor,
        darkReceiverColor,
      );
}
