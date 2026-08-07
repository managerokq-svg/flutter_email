// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';

abstract class VAppAlert {
  static void showErrorSnackBar({
    required String msg,
    required BuildContext context,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 5),
    ));
  }

  static Future<ModelSheetItem?> showModalSheet<T>({
    String? title,
    required List<ModelSheetItem> content,
    required BuildContext context,
    required String cancelText,
  }) async {
    final attachmentOptions = content
        .map((item) => AttachmentOptionItem(
              id: item.id,
              title: item.title,
              icon: _getIconDataFromIcon(item.iconData),
            ))
        .toList();
    final result = await showTelegramAttachmentSheet(
      context: context,
      options: attachmentOptions,
      cancelLabel: cancelText,
    );
    return result != null
        ? content.firstWhere((item) => item.id == result.id)
        : null;
  }

  static IconData _getIconDataFromIcon(Icon? icon) {
    if (icon?.icon != null) {
      return icon!.icon!;
    }
    return Icons.attach_file;
  }
}

class ModelSheetItem<T> {
  final T id;
  final String title;
  final Icon? iconData;
  ModelSheetItem({
    required this.title,
    required this.id,
    this.iconData,
  });
}

class AttachmentOptionItem<T> {
  final T id;
  final String title;
  final IconData icon;
  const AttachmentOptionItem({
    required this.id,
    required this.title,
    required this.icon,
  });
}

/// Telegram iOS style attachment colors
class TelegramAttachmentColors {
  // Gradient colors for each attachment type
  static const List<Color> mediaGradient = [Color(0xFF8B5CF6), Color(0xFFA855F7)];
  static const List<Color> fileGradient = [Color(0xFF3B82F6), Color(0xFF60A5FA)];
  static const List<Color> locationGradient = [Color(0xFF22C55E), Color(0xFF4ADE80)];
  static const List<Color> contactGradient = [Color(0xFFF97316), Color(0xFFFB923C)];
  static const List<Color> cameraGradient = [Color(0xFFEF4444), Color(0xFFF87171)];
  static const List<Color> musicGradient = [Color(0xFFEC4899), Color(0xFFF472B6)];

  static List<Color> getGradientForIndex(int index) {
    switch (index) {
      case 0:
        return mediaGradient;
      case 1:
        return fileGradient;
      case 2:
        return locationGradient;
      case 3:
        return contactGradient;
      case 4:
        return cameraGradient;
      default:
        return musicGradient;
    }
  }
}

/// Telegram iOS style attachment picker
class TelegramAttachmentSheet extends StatelessWidget {
  final List<AttachmentOptionItem> options;
  final String cancelLabel;

  const TelegramAttachmentSheet({
    super.key,
    required this.options,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {}, // Prevent tap through
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E).withValues(alpha: 0.85)
                            : const Color(0xFFF2F2F7).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),
                          _buildOptionsGrid(context, isDark),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Cancel button - separate container
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1C1C1E).withValues(alpha: 0.85)
                            : const Color(0xFFF2F2F7).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        cancelLabel,
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF007AFF),
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: bottomPadding + 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsGrid(BuildContext context, bool isDark) {
    final optionsCount = options.length;
    final columns = optionsCount <= 4 ? optionsCount : 4;
    final rows = (optionsCount / columns).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: List.generate(rows, (rowIndex) {
          final startIndex = rowIndex * columns;
          final endIndex = (startIndex + columns).clamp(0, optionsCount);
          final rowOptions = options.sublist(startIndex, endIndex);
          return Padding(
            padding: EdgeInsets.only(bottom: rowIndex < rows - 1 ? 16 : 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ...rowOptions.asMap().entries.map((entry) {
                  final globalIndex = startIndex + entry.key;
                  return _buildOptionItem(
                    context,
                    entry.value,
                    globalIndex,
                    isDark,
                  );
                }),
                ...List.generate(
                  columns - rowOptions.length,
                  (index) => const Expanded(child: SizedBox()),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    AttachmentOptionItem option,
    int index,
    bool isDark,
  ) {
    final gradient = TelegramAttachmentColors.getGradientForIndex(index);
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(option),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Gradient circular icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  option.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              // Label
              Text(
                option.title,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : const Color(0xFF3C3C43).withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<AttachmentOptionItem?> showTelegramAttachmentSheet({
  required BuildContext context,
  required List<AttachmentOptionItem> options,
  String? cancelLabel,
}) async {
  return showModalBottomSheet<AttachmentOptionItem?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => TelegramAttachmentSheet(
      options: options,
      cancelLabel: cancelLabel ?? S.of(context).cancel,
    ),
  );
}

// Keep old function for backward compatibility
Future<AttachmentOptionItem?> showCustomAttachmentOptionsSheet({
  required BuildContext context,
  required List<AttachmentOptionItem> options,
  String? title,
  String? cancelLabel,
}) async {
  return showTelegramAttachmentSheet(
    context: context,
    options: options,
    cancelLabel: cancelLabel,
  );
}
