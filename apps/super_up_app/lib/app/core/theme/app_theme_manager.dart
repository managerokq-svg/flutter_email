// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/core/api_service/story/story_api_service.dart';
import 'package:super_up/app/modules/story/story_view_page/story_view_page.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_message_page/v_chat_message_page.dart';
import 'package:v_chat_room_page/v_chat_room_page.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

import 'app_fonts.dart';

/// Manages all theme-related operations and configurations
class AppThemeManager {
  /// Returns the appropriate brightness for iOS based on the current theme mode
  static Brightness getIosBrightness(ThemeMode themeMode) {
    if (themeMode == ThemeMode.dark) {
      return Brightness.dark;
    }
    if (themeMode == ThemeMode.light) {
      return Brightness.light;
    }
    // Default to light theme if system theme is chosen
    VAppPref.setStringKey(SStorageKeys.appTheme.name, ThemeMode.light.name);
    return Brightness.light;
  }

  /// Creates the dark theme data with all necessary extensions
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: AppFonts.defaultFontFamily,
      fontFamilyFallback: const ['NotoSans', 'NotoEmoji', 'NotoColorEmoji'],
      appBarTheme: AppBarTheme(centerTitle: true),
      scaffoldBackgroundColor: Colors.black,
      cupertinoOverrideTheme: getCupertinoTheme(ThemeMode.dark),
      extensions: [
        VMessageTheme.dark().copyWith(
          senderBubbleColor: const Color(0xff005046),
          receiverBubbleColor: const Color(0xff363638),
          senderTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontFamily: AppFonts.defaultFontFamily,
          ),
          receiverTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 16.5,
            fontFamily: AppFonts.defaultFontFamily,
          ),
          storyReplyTapHandler: _handleStoryReplyTap,
          baseMediaUrl: SConstants.baseMediaUrl,
        ),
        VRoomTheme.dark().copyWith(),
      ],
    );
  }

  /// Creates the light theme data with all necessary extensions
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: AppFonts.defaultFontFamily,
      fontFamilyFallback: const ['NotoSans', 'NotoEmoji', 'NotoColorEmoji'],
      appBarTheme: AppBarTheme(centerTitle: true),
      primaryColor: Colors.green,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      cupertinoOverrideTheme: getCupertinoTheme(ThemeMode.light),
      extensions: [
        VMessageTheme.light().copyWith(
          senderBubbleColor: const Color(0xffE2FFD4),
          receiverBubbleColor: const Color(0xffFFFFFF),
          senderTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 16.5,
            fontFamily: AppFonts.defaultFontFamily,
          ),
          receiverTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 16.5,
            fontFamily: AppFonts.defaultFontFamily,
          ),
          storyReplyTapHandler: _handleStoryReplyTap,
          baseMediaUrl: SConstants.baseMediaUrl,
        ),
        VRoomTheme.light().copyWith(),
      ],
    );
  }

  /// Creates the Cupertino theme data based on the current theme mode
  static CupertinoThemeData getCupertinoTheme(ThemeMode themeMode) {
    final brightness = getIosBrightness(themeMode);
    final isDark = brightness == Brightness.dark;
    // Create the appropriate text theme based on dark/light mode
    final textTheme =
        isDark ? _getDarkCupertinoTextTheme() : _getLightCupertinoTextTheme();
    return CupertinoThemeData(
      brightness: brightness,
      applyThemeToAll: true,
      barBackgroundColor: isDark ? Colors.black : Colors.white,
      primaryColor: Colors.green,
      primaryContrastingColor: Colors.green,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? Colors.black : CupertinoColors.white,
    );
  }

  /// Returns the dark mode Cupertino text theme
  static CupertinoTextThemeData _getDarkCupertinoTextTheme() {
    return CupertinoTextThemeData(
      // Base text style for most text
      textStyle: TextStyle(
        color: CupertinoColors.white,
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Action buttons (like in dialogs)
      actionTextStyle: TextStyle(
        color: Colors.green,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Tab labels at bottom of screen
      tabLabelTextStyle: TextStyle(
        color: CupertinoColors.systemGrey,
        fontSize: 10.0,
        fontWeight: FontWeight.w500,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Standard navigation bar title
      navTitleTextStyle: TextStyle(
        color: CupertinoColors.white,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Large navigation bar title (collapsible header)
      navLargeTitleTextStyle: TextStyle(
        color: CupertinoColors.white,
        fontSize: 34.0,
        fontWeight: FontWeight.bold,
        fontFamily: AppFonts.sfProDisplay,
      ),
      // Navigation bar action items
      navActionTextStyle: TextStyle(
        color: Colors.green,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Picker text style (eg. for date pickers)
      pickerTextStyle: TextStyle(
        color: CupertinoColors.white,
        fontSize: 16.0,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Date/time picker text style
      dateTimePickerTextStyle: TextStyle(
        color: CupertinoColors.white,
        fontSize: 21.0,
        fontWeight: FontWeight.normal,
        fontFamily: AppFonts.defaultFontFamily,
      ),
    );
  }

  /// Returns the light mode Cupertino text theme
  static CupertinoTextThemeData _getLightCupertinoTextTheme() {
    return CupertinoTextThemeData(
      // Base text style for most text
      textStyle: TextStyle(
        color: CupertinoColors.black,
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Action buttons (like in dialogs)
      actionTextStyle: TextStyle(
        color: Colors.green,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Tab labels at bottom of screen
      tabLabelTextStyle: TextStyle(
        color: CupertinoColors.systemGrey,
        fontSize: 10.0,
        fontWeight: FontWeight.w500,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Standard navigation bar title
      navTitleTextStyle: TextStyle(
        color: CupertinoColors.black,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Large navigation bar title (collapsible header)
      navLargeTitleTextStyle: TextStyle(
        color: CupertinoColors.black,
        fontSize: 34.0,
        fontWeight: FontWeight.bold,
        fontFamily: AppFonts.sfProDisplay,
      ),
      // Navigation bar action items
      navActionTextStyle: TextStyle(
        color: Colors.green,
        fontSize: 17.0,
        fontWeight: FontWeight.w600,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Picker text style (eg. for date pickers)
      pickerTextStyle: TextStyle(
        color: CupertinoColors.black,
        fontSize: 16.0,
        fontFamily: AppFonts.defaultFontFamily,
      ),
      // Date/time picker text style
      dateTimePickerTextStyle: TextStyle(
        color: CupertinoColors.black,
        fontSize: 21.0,
        fontWeight: FontWeight.normal,
        fontFamily: AppFonts.defaultFontFamily,
      ),
    );
  }

  /// Handles story reply tap - fetches story and navigates to view it
  static Future<void> _handleStoryReplyTap(
    BuildContext context,
    VStoryReplyMsgData storyData,
  ) async {
    final storyId = storyData.storyId;
    if (storyId.isEmpty) {
      VAppAlert.showErrorSnackBar(
        message: S.of(context).storyNoLongerAvailable,
        context: context,
      );
      return;
    }
    // Show loading dialog
    _showLoadingDialog(context);
    try {
      final storyApiService = GetIt.I.get<StoryApiService>();
      final result = await storyApiService.getStoryById(storyId);
      if (!context.mounted) return;
      // Dismiss loading dialog
      Navigator.of(context, rootNavigator: true).pop();
      if (result == null) {
        VAppAlert.showErrorSnackBar(
          message: S.of(context).storyNoLongerAvailable,
          context: context,
        );
        return;
      }
      await context.toPage(
        StoryViewpage(
          allUserStories: [result],
          initialIndex: 0,
          onDelete: (_) {},
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      // Dismiss loading dialog if still showing
      Navigator.of(context, rootNavigator: true).pop();
      VAppAlert.showErrorSnackBar(
        message: S.of(context).storyNoLongerAvailable,
        context: context,
      );
    }
  }

  /// Shows a loading dialog overlay
  static void _showLoadingDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (ctx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  S.of(context).loading,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
