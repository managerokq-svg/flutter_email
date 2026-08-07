// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:v_chat_input_ui/src/input/widgets/telegram_glass_container.dart';

/// Recording state for the Telegram-style record button
enum TelegramRecordState {
  idle,
  recording, // Long press hold mode
  locked, // Tap mode or swipe-up locked mode
  cancelled,
}

/// Telegram-style record button with two recording modes:
///
/// **Mode 1 - Single Tap (Locked/Hands-free):**
/// - Tap once to start recording in locked mode
/// - Recording continues until user taps send or cancel
///
/// **Mode 2 - Long Press (Hold to record):**
/// - Long press and hold to record
/// - Swipe left to cancel
/// - Swipe up to lock (switch to hands-free mode)
/// - Release to send
class TelegramRecordButton extends StatefulWidget {
  final VoidCallback onRecordStart;
  final VoidCallback onRecordCancel;
  final VoidCallback onRecordSend;
  final VoidCallback onRecordLock;
  final double size;
  final Widget icon;
  final bool isEnabled;

  const TelegramRecordButton({
    super.key,
    required this.onRecordStart,
    required this.onRecordCancel,
    required this.onRecordSend,
    required this.onRecordLock,
    this.size = 42,
    required this.icon,
    this.isEnabled = true,
  });

  @override
  State<TelegramRecordButton> createState() => TelegramRecordButtonState();
}

class TelegramRecordButtonState extends State<TelegramRecordButton>
    with TickerProviderStateMixin {
  TelegramRecordState _state = TelegramRecordState.idle;

  // Drag tracking for long press mode
  Offset _dragOffset = Offset.zero;
  Offset _startPosition = Offset.zero;
  bool _isLongPressActive = false;

  // Thresholds for gestures
  static const double _cancelThreshold = -80.0;
  static const double _lockThreshold = -60.0;

  // Custom long press with shorter duration (150ms instead of 500ms)
  Timer? _longPressTimer;
  static const Duration _longPressDuration = Duration(milliseconds: 150);
  bool _isPointerDown = false;

  // Animation controllers
  late AnimationController _scaleController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  // Visual hints
  bool _showLockHint = false;

  // Public getters
  TelegramRecordState get state => _state;
  bool get isRecording => _state == TelegramRecordState.recording;
  bool get isLocked => _state == TelegramRecordState.locked;
  bool get isIdle => _state == TelegramRecordState.idle;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutBack),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _hapticFeedback() {
    HapticFeedback.mediumImpact();
  }

  // ===== POINTER HANDLING (Fast long press - 150ms) =====
  void _onPointerDown(PointerDownEvent event) {
    if (!widget.isEnabled || _state != TelegramRecordState.idle) return;
    _isPointerDown = true;
    _startPosition = event.position;
    _dragOffset = Offset.zero;
    // Start timer for long press detection
    _longPressTimer = Timer(_longPressDuration, () {
      if (_isPointerDown && _state == TelegramRecordState.idle) {
        _startHoldRecording();
      }
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_state != TelegramRecordState.recording || !_isLongPressActive) return;
    final delta = event.position - _startPosition;
    setState(() {
      _dragOffset = delta;
      _showLockHint = delta.dy < _lockThreshold / 2;
    });
    // Check thresholds
    if (delta.dy < _lockThreshold) {
      _lockFromLongPress();
    } else if (delta.dx < _cancelThreshold) {
      _cancelRecording();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _longPressTimer?.cancel();
    final wasPointerDown = _isPointerDown;
    _isPointerDown = false;
    if (_isLongPressActive) {
      // Was in long press mode - release to send
      _isLongPressActive = false;
      if (_state == TelegramRecordState.recording) {
        _sendRecording();
      }
    } else if (wasPointerDown && _state == TelegramRecordState.idle) {
      // Quick tap - start locked recording
      _startLockedRecording();
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _longPressTimer?.cancel();
    _isPointerDown = false;
    if (_isLongPressActive) {
      _isLongPressActive = false;
      _cancelRecording();
    }
  }

  // ===== SINGLE TAP MODE =====
  void _startLockedRecording() {
    _setState(TelegramRecordState.locked);
    _pulseController.repeat(reverse: true);
    _hapticFeedback();
    widget.onRecordStart();
    widget.onRecordLock();
  }

  // ===== LONG PRESS MODE =====
  void _startHoldRecording() {
    _isLongPressActive = true;
    _setState(TelegramRecordState.recording);
    _scaleController.forward();
    _pulseController.repeat(reverse: true);
    _hapticFeedback();
    widget.onRecordStart();
  }

  void _lockFromLongPress() {
    if (_state == TelegramRecordState.locked) return;
    _isLongPressActive = false;
    _setState(TelegramRecordState.locked);
    _scaleController.reverse();
    _dragOffset = Offset.zero;
    _showLockHint = false;
    _hapticFeedback();
    widget.onRecordLock();
  }

  void _cancelRecording() {
    _isLongPressActive = false;
    _setState(TelegramRecordState.cancelled);
    _resetAnimations();
    _hapticFeedback();
    widget.onRecordCancel();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _setState(TelegramRecordState.idle);
    });
  }

  void _sendRecording() {
    _setState(TelegramRecordState.idle);
    _resetAnimations();
    _hapticFeedback();
    widget.onRecordSend();
  }

  void _resetAnimations() {
    _scaleController.reverse();
    _pulseController.stop();
    _pulseController.reset();
    _dragOffset = Offset.zero;
    _showLockHint = false;
  }

  void _setState(TelegramRecordState newState) {
    if (mounted) setState(() => _state = newState);
  }

  // ===== PUBLIC METHODS (called from parent) =====
  void cancelLockedRecording() {
    if (_state == TelegramRecordState.locked) {
      _cancelRecording();
    }
  }

  void sendLockedRecording() {
    if (_state == TelegramRecordState.locked) {
      _sendRecording();
    }
  }

  void resetToIdle() {
    _isLongPressActive = false;
    _resetAnimations();
    _setState(TelegramRecordState.idle);
  }

  // ===== BUILD =====
  @override
  Widget build(BuildContext context) {
    final colors = context.telegramColors;
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Lock hint (above button during long press)
          if (_state == TelegramRecordState.recording && _isLongPressActive)
            _buildLockHint(colors),
          // Main button
          _buildButton(colors),
        ],
      ),
    );
  }

  Widget _buildButton(TelegramColorScheme colors) {
    final isActive = _state == TelegramRecordState.recording;
    final isLockedMode = _state == TelegramRecordState.locked;
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _pulseAnimation]),
      builder: (context, child) {
        double scale = 1.0;
        if (isActive) {
          scale = _scaleAnimation.value * _pulseAnimation.value;
        } else if (isLockedMode) {
          scale = _pulseAnimation.value;
        }
        final xOffset = isActive ? _dragOffset.dx.clamp(-80.0, 0.0) * 0.25 : 0.0;
        final yOffset = isActive ? _dragOffset.dy.clamp(-50.0, 0.0) * 0.15 : 0.0;
        return Transform.translate(
          offset: Offset(xOffset, yOffset),
          child: Transform.scale(
            scale: scale.clamp(1.0, 2.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isActive || isLockedMode) ? Colors.red : colors.glassBackground,
                border: (isActive || isLockedMode)
                    ? null
                    : Border.all(
                        color: colors.secondaryText.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                boxShadow: (isActive || isLockedMode)
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: (isActive || isLockedMode)
                      ? Icon(
                          PhosphorIcons.microphone(PhosphorIconsStyle.fill),
                          key: const ValueKey('recording'),
                          color: Colors.white,
                          size: 22,
                        )
                      : widget.icon,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLockHint(TelegramColorScheme colors) {
    final progress = (_dragOffset.dy.abs() / _lockThreshold.abs()).clamp(0.0, 1.0);
    return Positioned(
      bottom: widget.size + 12,
      child: AnimatedOpacity(
        opacity: _showLockHint ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _showLockHint ? colors.accent : colors.glassBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _showLockHint ? colors.accent : colors.secondaryText.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AnimatedRotation(
            turns: progress * 0.05,
            duration: const Duration(milliseconds: 100),
            child: Icon(
              _showLockHint ? Icons.lock : Icons.lock_open_outlined,
              color: _showLockHint ? Colors.white : colors.secondaryText,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated waveform visualizer for recording
class RecordingWaveform extends StatefulWidget {
  final double height;
  final Color color;
  final int barCount;

  const RecordingWaveform({
    super.key,
    this.height = 24,
    required this.color,
    this.barCount = 20,
  });

  @override
  State<RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.barCount; i++) {
      _barHeights.add(0.3 + (math.Random().nextDouble() * 0.7));
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..repeat();
    _controller.addListener(_updateBars);
  }

  void _updateBars() {
    if (mounted) {
      setState(() {
        _barHeights.removeAt(0);
        _barHeights.add(0.2 + (math.Random().nextDouble() * 0.8));
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateBars);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(widget.barCount, (index) {
          final height = _barHeights[index] * widget.height;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 2.5,
            height: height.clamp(3.0, widget.height),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          );
        }),
      ),
    );
  }
}
