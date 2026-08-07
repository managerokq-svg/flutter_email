// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:ui';
import 'package:flutter/material.dart';

/// Telegram-style glassmorphism colors
class TelegramInputColors {
  // Light mode colors
  static const Color lightGlassBackground = Color(0xFFF7F7F7);
  static const Color lightGlassOverlay = Color(0x80FFFFFF);
  static const Color lightPrimaryText = Color(0xFF404040);
  static const Color lightSecondaryText = Color(0xFF8C8C8C);
  static const Color lightAccent = Color(0xFF008BFF);
  static const Color lightDivider = Color(0xFFE5E5E5);
  // Dark mode colors
  static const Color darkGlassBackground = Color(0xFF2A2A2A);
  static const Color darkGlassOverlay = Color(0x40FFFFFF);
  static const Color darkPrimaryText = Color(0xFFE5E5E5);
  static const Color darkSecondaryText = Color(0xFF8C8C8C);
  static const Color darkAccent = Color(0xFF5EB5FF);
  static const Color darkDivider = Color(0xFF3D3D3D);
  /// Get colors based on brightness
  static Color glassBackground(Brightness brightness) =>
      brightness == Brightness.dark ? darkGlassBackground : lightGlassBackground;
  static Color glassOverlay(Brightness brightness) =>
      brightness == Brightness.dark ? darkGlassOverlay : lightGlassOverlay;
  static Color primaryText(Brightness brightness) =>
      brightness == Brightness.dark ? darkPrimaryText : lightPrimaryText;
  static Color secondaryText(Brightness brightness) =>
      brightness == Brightness.dark ? darkSecondaryText : lightSecondaryText;
  static Color accent(Brightness brightness) =>
      brightness == Brightness.dark ? darkAccent : lightAccent;
  static Color divider(Brightness brightness) =>
      brightness == Brightness.dark ? darkDivider : lightDivider;
}

/// Telegram-style glass container with blur effect
class TelegramGlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final bool isCircular;

  const TelegramGlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 21,
    this.padding,
    this.blurSigma = 20,
    this.isCircular = false,
  });

  /// Creates a circular glass button (42x42 like Telegram)
  const TelegramGlassContainer.circular({
    super.key,
    required this.child,
    this.width = 42,
    this.height = 42,
    this.padding,
    this.blurSigma = 20,
  })  : borderRadius = 1000,
        isCircular = true;

  /// Creates a pill-shaped text field container
  const TelegramGlassContainer.pill({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.blurSigma = 20,
  })  : borderRadius = 21,
        isCircular = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderRadius = isCircular
        ? BorderRadius.circular(1000)
        : BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: effectiveBorderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: effectiveBorderRadius,
            color: isDark
                ? TelegramInputColors.darkGlassBackground.withOpacity(0.85)
                : TelegramInputColors.lightGlassBackground.withOpacity(0.85),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Telegram-style circular icon button with glass effect
class TelegramGlassIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onTap;
  final double size;
  final bool isEnabled;

  const TelegramGlassIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 42,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: TelegramGlassContainer.circular(
        width: size,
        height: size,
        child: Center(
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: icon,
          ),
        ),
      ),
    );
  }
}

/// Telegram-style send button (blue circular button)
class TelegramSendButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final Widget? icon;

  const TelegramSendButton({
    super.key,
    required this.onTap,
    this.size = 42,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: TelegramInputColors.accent(brightness),
          boxShadow: [
            BoxShadow(
              color: TelegramInputColors.accent(brightness).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: icon ??
              const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.white,
                size: 24,
              ),
        ),
      ),
    );
  }
}

/// Telegram-style recording indicator
class TelegramRecordingIndicator extends StatefulWidget {
  final String duration;
  final VoidCallback onCancel;

  const TelegramRecordingIndicator({
    super.key,
    required this.duration,
    required this.onCancel,
  });

  @override
  State<TelegramRecordingIndicator> createState() =>
      _TelegramRecordingIndicatorState();
}

class _TelegramRecordingIndicatorState extends State<TelegramRecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Row(
      children: [
        // Pulsing red dot
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(_pulseAnimation.value),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        // Duration text
        Text(
          widget.duration,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: TelegramInputColors.primaryText(brightness),
          ),
        ),
        const Spacer(),
        // Slide to cancel hint
        Text(
          '< Slide to cancel',
          style: TextStyle(
            fontSize: 15,
            color: TelegramInputColors.secondaryText(brightness),
          ),
        ),
      ],
    );
  }
}

/// Extension for easy access to Telegram colors
extension TelegramColorsExtension on BuildContext {
  TelegramColorScheme get telegramColors {
    final brightness = Theme.of(this).brightness;
    return TelegramColorScheme(brightness);
  }
}

class TelegramColorScheme {
  final Brightness brightness;
  TelegramColorScheme(this.brightness);
  Color get glassBackground => TelegramInputColors.glassBackground(brightness);
  Color get glassOverlay => TelegramInputColors.glassOverlay(brightness);
  Color get primaryText => TelegramInputColors.primaryText(brightness);
  Color get secondaryText => TelegramInputColors.secondaryText(brightness);
  Color get accent => TelegramInputColors.accent(brightness);
  Color get divider => TelegramInputColors.divider(brightness);
  Color get inputBackground => TelegramInputColors.glassBackground(brightness);
}
