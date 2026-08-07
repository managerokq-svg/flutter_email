// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

/// Font family constants for the application
///
/// SF Pro fonts are bundled in assets/fonts/ for cross-platform consistency.
/// On iOS, these will use the native system font automatically.
/// On Android/Web/Desktop, the bundled font files will be used.
///
/// Fallback fonts (Noto Sans, Noto Emoji) are automatically downloaded via
/// google_fonts package to display characters not supported by SF Pro
/// (emojis, special symbols, non-Latin scripts like Arabic, Chinese, etc.)
class AppFonts {
  /// SF Pro Text - Primary font for body text and UI elements
  /// This is the default iOS system font for most text
  /// Bundled weights: Regular (400), Bold (700)
  /// Note: Medium (500) and Semibold (600) will fallback to closest weight
  static const String sfProText = 'SF Pro Text';

  /// SF Pro Display - For large text and headlines
  /// Used for navigation titles and prominent text
  /// Bundled weights: Regular (400), Bold (700)
  /// Note: Medium (500) and Semibold (600) will fallback to closest weight
  static const String sfProDisplay = 'SF Pro Display';

  /// Default font family for the entire app
  /// Using SF Pro Text as it's the most commonly used iOS system font
  static const String defaultFontFamily = sfProText;

  /// Fallback fonts for characters not supported by SF Pro
  /// These are automatically loaded from Google Fonts when needed
  /// - NotoSans: Covers most Unicode characters
  /// - NotoEmoji: Emoji support
  /// - NotoColorEmoji: Color emoji support
  static const List<String> fallbackFonts = [
    'NotoSans',
    'NotoEmoji',
    'NotoColorEmoji',
  ];

  /// Prevents instantiation of this utility class
  AppFonts._();
}
