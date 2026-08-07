// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BubbleColorPicker extends StatelessWidget {
  final String label;
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;

  const BubbleColorPicker({
    super.key,
    required this.label,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<Color> _presetColors = [
    Color(0xFFD9FDD3), // WhatsApp light green
    Color(0xFF005C4B), // WhatsApp dark green
    Color(0xFFFFFFFF), // White
    Color(0xFF202C33), // WhatsApp dark gray
    Color(0xFF128C7E), // Teal
    Color(0xFF25D366), // Green
    Color(0xFF34B7F1), // Blue
    Color(0xFFE91E63), // Pink
    Color(0xFF9C27B0), // Purple
    Color(0xFFFF5722), // Orange
    Color(0xFFFFEB3B), // Yellow
    Color(0xFF795548), // Brown
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      title: Text(label),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _presetColors.map((color) {
            final isSelected = color.toARGB32() == selectedColor.toARGB32();
            return GestureDetector(
              onTap: () => onColorSelected(color),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey4,
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: color == const Color(0xFFFFFFFF)
                      ? [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.3),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        CupertinoIcons.checkmark,
                        size: 18,
                        color: _getContrastColor(color),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
