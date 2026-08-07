// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up_core/super_up_core.dart';

import '../widgets/bubble_color_picker.dart';
import '../widgets/bubble_preview.dart';
import '../widgets/font_size_slider.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> {
  bool _showDarkModeColors = false;

  @override
  Widget build(BuildContext context) {
    final lang = S.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(lang.appearance),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<AppearanceSettings>(
          valueListenable: VAppearanceListener.I,
          builder: (context, settings, _) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Preview Section
                Text(
                  lang.preview,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                BubblePreview(settings: settings),
                const SizedBox(height: 24),
                // Font Sizes Section
                CupertinoListSection.insetGrouped(
                  header: Text(lang.fontSizes),
                  children: [
                    FontSizeSlider(
                      label: lang.messageFontSize,
                      value: settings.messageFontSize,
                      min: AppearanceSettings.minMessageFontSize,
                      max: AppearanceSettings.maxMessageFontSize,
                      onChanged: (value) {
                        VAppearanceListener.I.setMessageFontSize(value);
                      },
                    ),
                    FontSizeSlider(
                      label: lang.senderNameFontSize,
                      value: settings.senderNameFontSize,
                      min: AppearanceSettings.minSenderNameFontSize,
                      max: AppearanceSettings.maxSenderNameFontSize,
                      onChanged: (value) {
                        VAppearanceListener.I.setSenderNameFontSize(value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Bubble Colors Section
                CupertinoListSection.insetGrouped(
                  header: Text(lang.bubbleColors),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: CupertinoSlidingSegmentedControl<bool>(
                        groupValue: _showDarkModeColors,
                        children: {
                          false: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(lang.lightMode),
                          ),
                          true: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(lang.darkMode),
                          ),
                        },
                        onValueChanged: (value) {
                          setState(() => _showDarkModeColors = value ?? false);
                        },
                      ),
                    ),
                    BubbleColorPicker(
                      label: lang.senderBubble,
                      selectedColor: _showDarkModeColors
                          ? settings.darkSenderColor
                          : settings.lightSenderColor,
                      onColorSelected: (color) {
                        if (_showDarkModeColors) {
                          VAppearanceListener.I.setDarkSenderColor(color);
                        } else {
                          VAppearanceListener.I.setLightSenderColor(color);
                        }
                      },
                    ),
                    BubbleColorPicker(
                      label: lang.receiverBubble,
                      selectedColor: _showDarkModeColors
                          ? settings.darkReceiverColor
                          : settings.lightReceiverColor,
                      onColorSelected: (color) {
                        if (_showDarkModeColors) {
                          VAppearanceListener.I.setDarkReceiverColor(color);
                        } else {
                          VAppearanceListener.I.setLightReceiverColor(color);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Reset Button
                CupertinoButton(
                  onPressed: () async {
                    final confirm = await showCupertinoDialog<bool>(
                      context: context,
                      builder: (context) => CupertinoAlertDialog(
                        title: Text(lang.resetToDefaults),
                        actions: [
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(lang.cancel),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(lang.reset),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await VAppearanceListener.I.resetToDefaults();
                    }
                  },
                  child: Text(
                    lang.resetToDefaults,
                    style: const TextStyle(color: CupertinoColors.destructiveRed),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
