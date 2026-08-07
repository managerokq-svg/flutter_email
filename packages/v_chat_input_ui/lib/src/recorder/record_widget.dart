// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:v_chat_input_ui/src/input/widgets/telegram_glass_container.dart';
import 'package:v_chat_input_ui/src/recorder/recorders.dart';
import 'package:v_platform/v_platform.dart';
import '../models/message_voice_data.dart';

class RecordWidget extends StatefulWidget {
  final Duration maxTime;
  final VoidCallback onMaxTime;
  final VoidCallback onCancel;
  final bool isLocked;
  final double dragProgress;

  const RecordWidget({
    super.key,
    required this.onCancel,
    required this.maxTime,
    required this.onMaxTime,
    this.isLocked = false,
    this.dragProgress = 0.0,
  });

  @override
  State<RecordWidget> createState() => RecordWidgetState();
}

class RecordWidgetState extends State<RecordWidget>
    with TickerProviderStateMixin {
  final _stopWatchTimer = StopWatchTimer();
  String _currentTime = "00:00";
  int _recordMilli = 0;
  AppRecorder? _recorder;
  StreamSubscription? _rawTime;
  StreamSubscription? _minuteTime;
  bool _isPaused = false;
  // Pulsing animation for recording indicator
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  // Chevron animation
  late AnimationController _chevronController;

  bool get isPaused => _isPaused;

  @override
  void initState() {
    super.initState();
    _recorder = PlatformRecorder();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _chevronController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _rawTime = _stopWatchTimer.rawTime.listen((value) {
      _recordMilli = value;
      _currentTime = StopWatchTimer.getDisplayTime(
        value,
        hours: false,
        milliSecond: false,
      );
      if (mounted) {
        setState(() {});
      }
    });
    _minuteTime = _stopWatchTimer.minuteTime.listen((value) {
      if (value == widget.maxTime.inMinutes) {
        pause();
      }
    });
    _start();
  }

  void startCounterUp() {
    if (_stopWatchTimer.isRunning) {
      _stopCounter();
    }
    _stopWatchTimer.onStartTimer();
  }

  Future<void> _stopCounter() async {
    _stopWatchTimer.onResetTimer();
    _stopWatchTimer.onStopTimer();
    _recordMilli = 0;
  }

  Future<void> pause() async {
    _stopWatchTimer.onStopTimer();
    await _recorder?.pause();
    _pulseController.stop();
    _chevronController.stop();
    if (mounted) {
      setState(() {
        _isPaused = true;
      });
    }
  }

  Future<void> resume() async {
    await _recorder?.resume();
    _stopWatchTimer.onStartTimer();
    _pulseController.repeat(reverse: true);
    _chevronController.repeat();
    if (mounted) {
      setState(() {
        _isPaused = false;
      });
    }
  }

  Future<void> togglePause() async {
    if (_isPaused) {
      await resume();
    } else {
      await pause();
    }
  }

  Future<String> _getDir() async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return join(appDirectory.path, 'voice_$timestamp.aac');
  }

  Future<bool> _start() async {
    if (VPlatforms.isDeskTop) return false;
    if (VPlatforms.isWeb) {
      await _recorder!.start();
    } else {
      final path = await _getDir();
      await _recorder!.start(path);
    }
    await Future.delayed(const Duration(milliseconds: 200));
    final isRecording = await _recorder!.isRecording();
    if (isRecording) {
      startCounterUp();
      return true;
    }
    return false;
  }

  Future<MessageVoiceData> stopRecord() async {
    _stopWatchTimer.onStopTimer();
    await Future.delayed(const Duration(milliseconds: 10));
    final path = await _recorder!.stop();
    if (path != null) {
      List<int>? bytes;
      late final XFile? xFile;
      if (VPlatforms.isWeb) {
        xFile = XFile(path);
        bytes = await xFile.readAsBytes();
      }
      final uri = Uri.parse(path);
      final data = MessageVoiceData(
        duration: _recordMilli,
        fileSource: VPlatforms.isWeb
            ? VPlatformFile.fromBytes(
                name: "voice_recording.wav",
                bytes: bytes!,
              )
            : VPlatformFile.fromPath(
                fileLocalPath: uri.path,
              ),
      );
      return data;
    }
    throw "record path is null here ! while stop the record";
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.telegramColors;
    // Telegram style: simple layout with red dot, timer, and slide to cancel
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pulsing red dot
          _buildPulsingDot(),
          const SizedBox(width: 10),
          // Timer
          _buildTimer(colors),
          // Spacer pushes slide-to-cancel to the right
          const Spacer(),
          // Slide to cancel or locked mode controls
          if (widget.isLocked)
            _buildLockedControls(colors)
          else
            _buildSlideToCancel(colors),
        ],
      ),
    );
  }

  Widget _buildPulsingDot() {
    if (_isPaused) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.withValues(alpha: 0.5),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: _pulseAnimation.value),
          ),
        );
      },
    );
  }

  Widget _buildTimer(TelegramColorScheme colors) {
    return Text(
      _currentTime,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: colors.primaryText,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildSlideToCancel(TelegramColorScheme colors) {
    final opacity = (1.0 - widget.dragProgress * 2).clamp(0.0, 1.0);
    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 100),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated chevron
          AnimatedBuilder(
            animation: _chevronController,
            builder: (context, child) {
              final progress = _chevronController.value;
              final chevronOpacity = 0.4 + (math.sin(progress * math.pi * 2) * 0.6).abs();
              return Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: colors.secondaryText.withValues(alpha: chevronOpacity),
              );
            },
          ),
          Text(
            'Slide to cancel',
            style: TextStyle(
              fontSize: 14,
              color: colors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedControls(TelegramColorScheme colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cancel text button
        GestureDetector(
          onTap: widget.onCancel,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        // Pause/Resume button
        GestureDetector(
          onTap: togglePause,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.secondaryText.withValues(alpha: 0.15),
            ),
            child: Icon(
              _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: colors.primaryText,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _chevronController.dispose();
    close();
    super.dispose();
  }

  Future<void> close() async {
    _stopCounter();
    await _recorder?.stop();
    _stopWatchTimer.dispose();
    _rawTime?.cancel();
    _minuteTime?.cancel();
    await _recorder?.close();
  }
}
