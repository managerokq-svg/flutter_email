// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:ui';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';

/// Telegram iOS style option colors with gradients
class TelegramOptionColors {
  static const List<Color> replyGradient = [Color(0xFF3B82F6), Color(0xFF60A5FA)];
  static const List<Color> forwardGradient = [Color(0xFF8B5CF6), Color(0xFFA855F7)];
  static const List<Color> copyGradient = [Color(0xFF06B6D4), Color(0xFF22D3EE)];
  static const List<Color> deleteGradient = [Color(0xFFEF4444), Color(0xFFF87171)];
  static const List<Color> editGradient = [Color(0xFFF97316), Color(0xFFFB923C)];
  static const List<Color> pinGradient = [Color(0xFF22C55E), Color(0xFF4ADE80)];
  static const List<Color> starGradient = [Color(0xFFEAB308), Color(0xFFFACC15)];
  static const List<Color> infoGradient = [Color(0xFF6366F1), Color(0xFF818CF8)];
  static const List<Color> muteGradient = [Color(0xFF64748B), Color(0xFF94A3B8)];
  static const List<Color> reportGradient = [Color(0xFFDC2626), Color(0xFFF87171)];
  static const List<Color> blockGradient = [Color(0xFF991B1B), Color(0xFFDC2626)];
  static const List<Color> profileGradient = [Color(0xFF0EA5E9), Color(0xFF38BDF8)];
  static const List<Color> messageGradient = [Color(0xFF10B981), Color(0xFF34D399)];
  static const List<Color> defaultGradient = [Color(0xFF6B7280), Color(0xFF9CA3AF)];

  static List<Color> getGradientForTitle(String title, bool isDestructive) {
    if (isDestructive) return deleteGradient;
    final lower = title.toLowerCase();
    if (lower.contains('reply')) return replyGradient;
    if (lower.contains('forward')) return forwardGradient;
    if (lower.contains('copy')) return copyGradient;
    if (lower.contains('delete') || lower.contains('remove') || lower.contains('clear')) return deleteGradient;
    if (lower.contains('edit')) return editGradient;
    if (lower.contains('pin')) return pinGradient;
    if (lower.contains('star') || lower.contains('favorite')) return starGradient;
    if (lower.contains('info') || lower.contains('detail')) return infoGradient;
    if (lower.contains('mute') || lower.contains('unmute')) return muteGradient;
    if (lower.contains('report')) return reportGradient;
    if (lower.contains('block')) return blockGradient;
    if (lower.contains('profile')) return profileGradient;
    if (lower.contains('message') || lower.contains('chat')) return messageGradient;
    return defaultGradient;
  }

  static List<Color> getGradientForIndex(int index) {
    final gradients = [
      replyGradient,
      forwardGradient,
      copyGradient,
      editGradient,
      pinGradient,
      starGradient,
      infoGradient,
      profileGradient,
    ];
    return gradients[index % gradients.length];
  }
}

class CustomMessageOptionsSheet extends StatefulWidget {
  final List<MessageOptionItem> options;
  final String? title;
  final String cancelLabel;
  final List<String> quickReactions;
  final ValueChanged<String>? onReactionSelected;
  final String? currentUserEmoji;

  const CustomMessageOptionsSheet({
    super.key,
    required this.options,
    this.title,
    required this.cancelLabel,
    this.quickReactions = const ['❤️', '😂', '😮', '😢', '😡', '👍'],
    this.onReactionSelected,
    this.currentUserEmoji,
  });

  @override
  State<CustomMessageOptionsSheet> createState() => _CustomMessageOptionsSheetState();
}

class _CustomMessageOptionsSheetState extends State<CustomMessageOptionsSheet> {
  bool _showEmojiPicker = false;
  Widget? _emojiPicker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_emojiPicker == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      _emojiPicker = _buildEmojiPicker(context, isDark);
    }
  }

  void _handleOptionTap(BuildContext context, MessageOptionItem option) {
    Navigator.of(context).pop(option);
  }

  void _handleCancel(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _handleQuickReactionTap(BuildContext context, String emoji) {
    widget.onReactionSelected?.call(emoji);
    Navigator.of(context).pop();
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return GestureDetector(
      onTap: () => _handleCancel(context),
      child: Container(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Main options container
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
                          const SizedBox(height: 16),
                          // Reaction bar
                          if (widget.onReactionSelected != null)
                            _ReactionBar(
                              quickReactions: widget.quickReactions,
                              currentUserEmoji: widget.currentUserEmoji,
                              onReactionSelected: (emoji) => _handleQuickReactionTap(context, emoji),
                              onToggleEmojiPicker: _toggleEmojiPicker,
                              isDark: isDark,
                            ),
                          if (widget.onReactionSelected != null) const SizedBox(height: 8),
                          // Emoji picker
                          if (widget.onReactionSelected != null)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final scale = Tween<double>(begin: 0.98, end: 1.0).animate(animation);
                                return FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(scale: scale, child: child),
                                );
                              },
                              child: _showEmojiPicker ? _emojiPicker : const SizedBox.shrink(),
                            ),
                          if (_showEmojiPicker && widget.onReactionSelected != null)
                            const SizedBox(height: 8),
                          // Options grid
                          _TelegramOptionsGrid(
                            options: widget.options,
                            onOptionTap: (option) => _handleOptionTap(context, option),
                            isDark: isDark,
                          ),
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
              onTap: () => _handleCancel(context),
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
                        widget.cancelLabel,
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

  Widget _buildEmojiPicker(BuildContext context, bool isDark) {
    final bg = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 260,
        child: EmojiPicker(
          onEmojiSelected: (category, emoji) {
            _handleQuickReactionTap(context, emoji.emoji);
          },
          config: Config(
            height: 260,
            emojiViewConfig: EmojiViewConfig(
              columns: 7,
              emojiSizeMax: 28,
              backgroundColor: bg,
            ),
            categoryViewConfig: CategoryViewConfig(
              tabBarHeight: 36,
              indicatorColor: const Color(0xFF007AFF),
              iconColorSelected: const Color(0xFF007AFF),
            ),
            bottomActionBarConfig: const BottomActionBarConfig(
              enabled: true,
              showBackspaceButton: false,
              showSearchViewButton: false,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReactionBar extends StatelessWidget {
  final List<String> quickReactions;
  final String? currentUserEmoji;
  final ValueChanged<String> onReactionSelected;
  final VoidCallback onToggleEmojiPicker;
  final bool isDark;

  const _ReactionBar({
    required this.quickReactions,
    required this.currentUserEmoji,
    required this.onReactionSelected,
    required this.onToggleEmojiPicker,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final e in quickReactions)
            _ReactionEmoji(
              emoji: e,
              isSelected: e == currentUserEmoji,
              onSelected: onReactionSelected,
            ),
          GestureDetector(
            onTap: onToggleEmojiPicker,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add,
                size: 20,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TelegramOptionsGrid extends StatelessWidget {
  final List<MessageOptionItem> options;
  final ValueChanged<MessageOptionItem> onOptionTap;
  final bool isDark;

  const _TelegramOptionsGrid({
    required this.options,
    required this.onOptionTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final optionsCount = options.length;
    if (optionsCount == 0) return const SizedBox.shrink();
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
                  return _TelegramOptionItem(
                    option: entry.value,
                    index: globalIndex,
                    onTap: () => onOptionTap(entry.value),
                    isDark: isDark,
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
}

class _TelegramOptionItem extends StatelessWidget {
  final MessageOptionItem option;
  final int index;
  final VoidCallback onTap;
  final bool isDark;

  const _TelegramOptionItem({
    required this.option,
    required this.index,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = TelegramOptionColors.getGradientForTitle(option.title, option.isDestructive);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
                  color: option.isDestructive
                      ? (isDark ? const Color(0xFFFF6B6B) : const Color(0xFFDC2626))
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.9)
                          : const Color(0xFF3C3C43).withValues(alpha: 0.9)),
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

class _ReactionEmoji extends StatefulWidget {
  final String emoji;
  final ValueChanged<String> onSelected;
  final bool isSelected;

  const _ReactionEmoji({
    required this.emoji,
    required this.onSelected,
    this.isSelected = false,
  });

  @override
  State<_ReactionEmoji> createState() => _ReactionEmojiState();
}

class _ReactionEmojiState extends State<_ReactionEmoji> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: () => widget.onSelected(widget.emoji),
      child: AnimatedScale(
        scale: _pressed ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: widget.isSelected
              ? BoxDecoration(
                  color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF007AFF),
                    width: 2,
                  ),
                )
              : null,
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}

class MessageOptionItem<T> {
  final T id;
  final String title;
  final IconData icon;
  final bool isDestructive;

  const MessageOptionItem({
    required this.id,
    required this.title,
    required this.icon,
    this.isDestructive = false,
  });
}

Future<MessageOptionItem?> showCustomMessageOptionsSheet({
  required BuildContext context,
  required List<MessageOptionItem> options,
  String? title,
  String? cancelLabel,
  List<String> quickReactions = const ['❤️', '😂', '😮', '😢', '😡', '👍'],
  ValueChanged<String>? onReactionSelected,
  String? currentUserEmoji,
}) async {
  return showModalBottomSheet<MessageOptionItem?>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    useRootNavigator: true,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (context) => CustomMessageOptionsSheet(
      options: options,
      title: title,
      cancelLabel: cancelLabel ?? S.of(context).cancel,
      quickReactions: quickReactions,
      onReactionSelected: onReactionSelected,
      currentUserEmoji: currentUserEmoji,
    ),
  );
}
