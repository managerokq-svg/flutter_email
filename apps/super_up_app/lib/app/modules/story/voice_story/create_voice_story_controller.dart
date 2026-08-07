import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:v_platform/v_platform.dart';

enum RecordingState { idle, recording, recorded, playing }

class CreateVoiceStoryState {
  RecordingState recordingState = RecordingState.idle;
  Color backgroundColor;
  Duration currentDuration = Duration.zero;
  Duration recordedDuration = Duration.zero;
  String? recordedFilePath;

  CreateVoiceStoryState({Color? backgroundColor})
      : backgroundColor = backgroundColor ?? _generateRandomColor();

  static Color _generateRandomColor() {
    final random = Random();
    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF673AB7),
      const Color(0xFF3F51B5),
      const Color(0xFF2196F3),
      const Color(0xFF00BCD4),
      const Color(0xFF009688),
      const Color(0xFF4CAF50),
      const Color(0xFF8BC34A),
      const Color(0xFFFF9800),
      const Color(0xFFFF5722),
      const Color(0xFF795548),
    ];
    return colors[random.nextInt(colors.length)];
  }
}

class CreateVoiceStoryController extends ValueNotifier<CreateVoiceStoryState> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _durationTimer;
  static const int maxDurationSeconds = 60;

  CreateVoiceStoryController() : super(CreateVoiceStoryState()) {
    _audioPlayer.onPlayerComplete.listen((_) {
      if (value.recordingState == RecordingState.playing) {
        value.recordingState = RecordingState.recorded;
        notifyListeners();
      }
    });
    _audioPlayer.onPositionChanged.listen((duration) {
      if (value.recordingState == RecordingState.playing) {
        value.currentDuration = duration;
        notifyListeners();
      }
    });
  }

  List<Color> get availableColors => const [
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF673AB7),
    Color(0xFF3F51B5),
    Color(0xFF2196F3),
    Color(0xFF00BCD4),
    Color(0xFF009688),
    Color(0xFF4CAF50),
    Color(0xFF8BC34A),
    Color(0xFFFF9800),
    Color(0xFFFF5722),
    Color(0xFF795548),
  ];

  void changeBackgroundColor(Color color) {
    value.backgroundColor = color;
    notifyListeners();
  }

  Future<bool> checkPermission() async {
    return _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) return;
    String path;
    if (VPlatforms.isMobile) {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/voice_story_${DateTime.now().millisecondsSinceEpoch}.m4a';
    } else {
      path = '';
    }
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1),
      path: path,
    );
    value.recordingState = RecordingState.recording;
    value.currentDuration = Duration.zero;
    notifyListeners();
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (value.recordingState != RecordingState.recording) {
        timer.cancel();
        return;
      }
      value.currentDuration += const Duration(milliseconds: 100);
      notifyListeners();
      if (value.currentDuration.inSeconds >= maxDurationSeconds) {
        await stopRecording();
      }
    });
  }

  Future<void> stopRecording() async {
    _durationTimer?.cancel();
    final path = await _recorder.stop();
    if (path != null && path.isNotEmpty) {
      value.recordedFilePath = path;
      value.recordedDuration = value.currentDuration;
      value.recordingState = RecordingState.recorded;
    } else {
      value.recordingState = RecordingState.idle;
    }
    notifyListeners();
  }

  Future<void> playRecording() async {
    if (value.recordedFilePath == null) return;
    value.recordingState = RecordingState.playing;
    value.currentDuration = Duration.zero;
    notifyListeners();
    await _audioPlayer.play(DeviceFileSource(value.recordedFilePath!));
  }

  Future<void> stopPlaying() async {
    await _audioPlayer.stop();
    value.recordingState = RecordingState.recorded;
    value.currentDuration = Duration.zero;
    notifyListeners();
  }

  void deleteRecording() {
    if (value.recordedFilePath != null) {
      try {
        File(value.recordedFilePath!).deleteSync();
      } catch (_) {}
    }
    value.recordedFilePath = null;
    value.recordedDuration = Duration.zero;
    value.currentDuration = Duration.zero;
    value.recordingState = RecordingState.idle;
    notifyListeners();
  }

  VPlatformFile? getRecordedFile() {
    if (value.recordedFilePath == null) return null;
    return VPlatformFile.fromPath(fileLocalPath: value.recordedFilePath!);
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}
