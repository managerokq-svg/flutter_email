// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:v_platform/v_platform.dart';

class VInputTheme extends ThemeExtension<VInputTheme> {
  final BoxDecoration containerDecoration;
  final InputDecoration textFieldDecoration;
  // Icon widgets
  Widget? cameraIcon;
  Widget? fileIcon;
  Widget? emojiIcon;
  Widget? trashIcon;
  Widget? attachIcon;
  // Button widgets
  Widget? recordBtn;
  Widget? sendBtn;
  // Text styles
  final TextStyle textFieldTextStyle;
  final TextStyle hintTextStyle;
  // Telegram-specific properties
  final double buttonSize;
  final double textFieldBorderRadius;
  final Color accentColor;
  final bool useTelegramStyle;

  VInputTheme._({
    required this.containerDecoration,
    required this.textFieldDecoration,
    required this.recordBtn,
    required this.sendBtn,
    required this.textFieldTextStyle,
    required this.hintTextStyle,
    required this.emojiIcon,
    required this.trashIcon,
    required this.fileIcon,
    required this.cameraIcon,
    required this.attachIcon,
    required this.buttonSize,
    required this.textFieldBorderRadius,
    required this.accentColor,
    required this.useTelegramStyle,
  });

  /// Creates Telegram-style light theme
  VInputTheme.telegramLight({
    this.containerDecoration = const BoxDecoration(),
    this.textFieldDecoration = const InputDecoration(
      border: InputBorder.none,
      fillColor: Colors.transparent,
    ),
    this.recordBtn,
    this.sendBtn,
    this.textFieldTextStyle = const TextStyle(
      fontSize: 17,
      height: 1.3,
      color: Color(0xFF404040),
      letterSpacing: -0.43,
    ),
    this.hintTextStyle = const TextStyle(
      fontSize: 17,
      color: Color(0xFF8C8C8C),
      letterSpacing: -0.43,
    ),
    this.buttonSize = 42,
    this.textFieldBorderRadius = 21,
    this.accentColor = const Color(0xFF008BFF),
    this.useTelegramStyle = true,
  }) {
    emojiIcon ??= Icon(
      PhosphorIcons.smileySticker(),
      size: 27,
      color: const Color(0xFF8C8C8C),
    );
    fileIcon ??= Icon(
      CupertinoIcons.paperclip,
      size: 27,
      color: const Color(0xFF404040),
    );
    attachIcon ??= Icon(
      CupertinoIcons.paperclip,
      size: 27,
      color: const Color(0xFF404040),
    );
    cameraIcon ??= Icon(
      CupertinoIcons.camera,
      size: 24,
      color: const Color(0xFF8C8C8C),
    );
    trashIcon ??= const Icon(
      CupertinoIcons.trash,
      color: Colors.redAccent,
      size: 24,
    );
    recordBtn ??= Icon(
      PhosphorIcons.microphone(PhosphorIconsStyle.fill),
      size: 24,
      color: VPlatforms.isDeskTop
          ? const Color(0xFF8C8C8C)
          : const Color(0xFF404040),
    );
    sendBtn ??= const Icon(
      Icons.arrow_upward_rounded,
      size: 24,
      color: Colors.white,
    );
  }

  /// Creates Telegram-style dark theme
  VInputTheme.telegramDark({
    this.containerDecoration = const BoxDecoration(),
    this.textFieldDecoration = const InputDecoration(
      border: InputBorder.none,
      fillColor: Colors.transparent,
    ),
    this.recordBtn,
    this.sendBtn,
    this.textFieldTextStyle = const TextStyle(
      fontSize: 17,
      height: 1.3,
      color: Color(0xFFE5E5E5),
      letterSpacing: -0.43,
    ),
    this.hintTextStyle = const TextStyle(
      fontSize: 17,
      color: Color(0xFF8C8C8C),
      letterSpacing: -0.43,
    ),
    this.buttonSize = 42,
    this.textFieldBorderRadius = 21,
    this.accentColor = const Color(0xFF5EB5FF),
    this.useTelegramStyle = true,
  }) {
    emojiIcon ??= Icon(
      PhosphorIcons.smileySticker(),
      size: 27,
      color: const Color(0xFF8C8C8C),
    );
    fileIcon ??= Icon(
      CupertinoIcons.paperclip,
      size: 27,
      color: const Color(0xFFE5E5E5),
    );
    attachIcon ??= Icon(
      CupertinoIcons.paperclip,
      size: 27,
      color: const Color(0xFFE5E5E5),
    );
    cameraIcon ??= Icon(
      CupertinoIcons.camera,
      size: 24,
      color: const Color(0xFF8C8C8C),
    );
    trashIcon ??= const Icon(
      CupertinoIcons.trash,
      color: Colors.redAccent,
      size: 24,
    );
    recordBtn ??= Icon(
      PhosphorIcons.microphone(PhosphorIconsStyle.fill),
      size: 24,
      color: VPlatforms.isDeskTop
          ? const Color(0xFF8C8C8C)
          : const Color(0xFFE5E5E5),
    );
    sendBtn ??= const Icon(
      Icons.arrow_upward_rounded,
      size: 24,
      color: Colors.white,
    );
  }

  /// Legacy light theme (kept for backwards compatibility)
  VInputTheme.light({
    this.containerDecoration = const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(
        Radius.circular(15),
      ),
    ),
    this.textFieldDecoration = const InputDecoration(
      border: InputBorder.none,
      fillColor: Colors.transparent,
    ),
    this.recordBtn,
    this.sendBtn,
    this.textFieldTextStyle = const TextStyle(height: 1.3),
    this.hintTextStyle = const TextStyle(color: Colors.grey),
    this.buttonSize = 42,
    this.textFieldBorderRadius = 15,
    this.accentColor = Colors.green,
    this.useTelegramStyle = false,
  }) {
    emojiIcon ??= Icon(
      PhosphorIcons.smiley(),
      size: 26,
      color: Colors.green,
    );
    fileIcon ??= Icon(
      CupertinoIcons.paperclip,
      size: 26,
      color: Colors.green,
    );
    attachIcon ??= Icon(
      CupertinoIcons.paperclip,
      size: 26,
      color: Colors.green,
    );
    cameraIcon ??= Icon(
      CupertinoIcons.camera,
      size: 26,
      color: Colors.green,
    );
    trashIcon ??= Icon(
      CupertinoIcons.trash,
      color: Colors.redAccent,
      size: 30,
    );
    recordBtn ??= Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VPlatforms.isDeskTop ? Colors.grey : Colors.green,
      ),
      child: Icon(
        PhosphorIcons.microphone(PhosphorIconsStyle.fill),
        color: Colors.white,
      ),
    );
    sendBtn ??= Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
      ),
      child: const Icon(
        Icons.send,
        color: Colors.white,
      ),
    );
  }

  /// Legacy dark theme (kept for backwards compatibility)
  VInputTheme.dark({
    this.containerDecoration = const BoxDecoration(
      color: Color(0xf7232121),
      borderRadius: BorderRadius.all(
        Radius.circular(15),
      ),
    ),
    this.textFieldDecoration = const InputDecoration(
      border: InputBorder.none,
      fillColor: Colors.transparent,
    ),
    this.recordBtn,
    this.textFieldTextStyle = const TextStyle(height: 1.3),
    this.hintTextStyle = const TextStyle(color: Colors.grey),
    this.sendBtn,
    this.buttonSize = 42,
    this.textFieldBorderRadius = 15,
    this.accentColor = Colors.green,
    this.useTelegramStyle = false,
  }) {
    emojiIcon ??= Icon(
      CupertinoIcons.smiley,
      size: 26,
      color: Colors.green,
    );
    fileIcon ??= Icon(
      CupertinoIcons.paperclip,
      size: 26,
      color: Colors.green,
    );
    attachIcon ??= Icon(
      CupertinoIcons.paperclip,
      size: 26,
      color: Colors.green,
    );
    cameraIcon ??= Icon(
      CupertinoIcons.camera,
      size: 26,
      color: Colors.green,
    );
    trashIcon ??= Icon(
      CupertinoIcons.trash,
      color: Colors.redAccent,
      size: 30,
    );
    recordBtn ??= Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: VPlatforms.isDeskTop ? Colors.grey : Colors.green,
      ),
      child: Icon(
        PhosphorIcons.microphone(PhosphorIconsStyle.fill),
        color: Colors.white,
      ),
    );
    sendBtn ??= Container(
      padding: const EdgeInsets.all(7),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green,
      ),
      child: const Icon(
        Icons.send,
        color: Colors.white,
      ),
    );
  }

  @override
  ThemeExtension<VInputTheme> lerp(
      ThemeExtension<VInputTheme>? other, double t) {
    if (other is! VInputTheme) {
      return this;
    }
    return this;
  }

  @override
  VInputTheme copyWith({
    BoxDecoration? containerDecoration,
    InputDecoration? textFieldDecoration,
    Widget? cameraIcon,
    Widget? fileIcon,
    Widget? emojiIcon,
    Widget? recordBtn,
    Widget? sendBtn,
    Widget? trashIcon,
    Widget? attachIcon,
    TextStyle? textFieldTextStyle,
    TextStyle? hintTextStyle,
    double? buttonSize,
    double? textFieldBorderRadius,
    Color? accentColor,
    bool? useTelegramStyle,
  }) {
    return VInputTheme._(
      containerDecoration: containerDecoration ?? this.containerDecoration,
      textFieldDecoration: textFieldDecoration ?? this.textFieldDecoration,
      cameraIcon: cameraIcon ?? this.cameraIcon,
      fileIcon: fileIcon ?? this.fileIcon,
      trashIcon: trashIcon ?? this.trashIcon,
      emojiIcon: emojiIcon ?? this.emojiIcon,
      attachIcon: attachIcon ?? this.attachIcon,
      recordBtn: recordBtn ?? this.recordBtn,
      sendBtn: sendBtn ?? this.sendBtn,
      textFieldTextStyle: textFieldTextStyle ?? this.textFieldTextStyle,
      hintTextStyle: hintTextStyle ?? this.hintTextStyle,
      buttonSize: buttonSize ?? this.buttonSize,
      textFieldBorderRadius:
          textFieldBorderRadius ?? this.textFieldBorderRadius,
      accentColor: accentColor ?? this.accentColor,
      useTelegramStyle: useTelegramStyle ?? this.useTelegramStyle,
    );
  }
}

extension VInputThemeExt on BuildContext {
  /// Returns Telegram-style theme based on brightness
  VInputTheme get vInputTheme {
    if (CupertinoTheme.of(this).brightness == Brightness.dark) {
      return VInputTheme.telegramDark();
    } else {
      return VInputTheme.telegramLight();
    }
  }

  /// Returns legacy theme (for backwards compatibility)
  VInputTheme get vInputThemeLegacy {
    if (CupertinoTheme.of(this).brightness == Brightness.dark) {
      return VInputTheme.dark();
    } else {
      return VInputTheme.light();
    }
  }

  /// Check if dark mode
  bool get isDarkMode => CupertinoTheme.of(this).brightness == Brightness.dark;
}
