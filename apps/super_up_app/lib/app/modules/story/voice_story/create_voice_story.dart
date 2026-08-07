import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up_core/super_up_core.dart';

import '../../../core/api_service/story/story_api_service.dart';
import '../../../core/models/story/create_story_dto.dart';
import '../../../core/utils/enums.dart';
import 'create_voice_story_controller.dart';

class CreateVoiceStory extends StatefulWidget {
  const CreateVoiceStory({super.key});

  @override
  State<CreateVoiceStory> createState() => _CreateVoiceStoryState();
}

class _CreateVoiceStoryState extends State<CreateVoiceStory> {
  late final CreateVoiceStoryController _controller;
  final _api = GetIt.I.get<StoryApiService>();

  @override
  void initState() {
    super.initState();
    _controller = CreateVoiceStoryController();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _controller.checkPermission();
    if (!hasPermission && mounted) {
      VAppAlert.showErrorSnackBar(
        context: context,
        message: 'Microphone permission is required',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CreateVoiceStoryState>(
      valueListenable: _controller,
      builder: (context, state, _) {
        return Scaffold(
          backgroundColor: state.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                const SizedBox(height: 24),
                _buildColorPicker(state),
                Expanded(
                  child: _buildRecordingArea(state),
                ),
                _buildBottomActions(state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      leading: InkWell(
        onTap: () => Navigator.of(context).pop(),
        child: const Icon(
          CupertinoIcons.clear,
          color: Colors.white,
          size: 30,
        ),
      ),
      title: Text(
        S.of(context).voiceStory,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildColorPicker(CreateVoiceStoryState state) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _controller.availableColors.length,
        itemBuilder: (context, index) {
          final color = _controller.availableColors[index];
          final isSelected = color == state.backgroundColor;
          return GestureDetector(
            onTap: () => _controller.changeBackgroundColor(color),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.transparent,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecordingArea(CreateVoiceStoryState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Microphone icon with animation
          _buildMicrophoneIcon(state),
          const SizedBox(height: 24),
          // Duration display
          Text(
            _formatDuration(state.currentDuration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '/ ${_formatDuration(const Duration(seconds: CreateVoiceStoryController.maxDurationSeconds))}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 24),
          // Progress bar
          if (state.recordingState != RecordingState.idle)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.currentDuration.inMilliseconds /
                      (CreateVoiceStoryController.maxDurationSeconds * 1000),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneIcon(CreateVoiceStoryState state) {
    final isRecording = state.recordingState == RecordingState.recording;
    final isPlaying = state.recordingState == RecordingState.playing;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isRecording ? 140 : 120,
      height: isRecording ? 140 : 120,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
      child: Icon(
        isPlaying ? Icons.volume_up : Icons.mic,
        color: Colors.white,
        size: isRecording ? 64 : 56,
      ),
    );
  }

  Widget _buildBottomActions(CreateVoiceStoryState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.recordingState == RecordingState.idle) ...[
            _buildRecordButton(),
          ] else if (state.recordingState == RecordingState.recording) ...[
            _buildStopRecordingButton(),
          ] else if (state.recordingState == RecordingState.recorded ||
              state.recordingState == RecordingState.playing) ...[
            _buildPlaybackControls(state),
            const SizedBox(height: 24),
            _buildSubmitButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return GestureDetector(
      onTap: _controller.startRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.mic,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildStopRecordingButton() {
    return GestureDetector(
      onTap: _controller.stopRecording,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.stop,
          color: Colors.red,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildPlaybackControls(CreateVoiceStoryState state) {
    final isPlaying = state.recordingState == RecordingState.playing;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Delete button
        IconButton(
          onPressed: _controller.deleteRecording,
          icon: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Play/Stop button
        GestureDetector(
          onTap: isPlaying ? _controller.stopPlaying : _controller.playRecording,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isPlaying ? Icons.stop : Icons.play_arrow,
              color: Colors.black87,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 24),
        // Placeholder for symmetry
        const SizedBox(width: 52),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _uploadVoiceStory,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send, size: 20),
            const SizedBox(width: 8),
            Text(
              S.of(context).shareYourStatus,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _uploadVoiceStory() async {
    final file = _controller.getRecordedFile();
    if (file == null) return;
    await vSafeApiCall(
      onLoading: () {
        VAppAlert.showLoading(context: context);
      },
      request: () async {
        final dto = CreateStoryDto(
          storyType: StoryType.voice,
          content: StoryType.voice.name,
          image: file,
          backgroundColor: _controller.value.backgroundColor.toARGB32().toRadixString(16),
          attachment: {
            'duration': _controller.value.recordedDuration.inSeconds,
          },
        );
        return _api.createStory(dto);
      },
      onSuccess: (response) {
        context.pop();
        context.pop();
        VAppAlert.showSuccessSnackBar(
          context: context,
          message: S.of(context).storyCreatedSuccessfully,
        );
      },
      onError: (exception) {
        context.pop();
        VAppAlert.showErrorSnackBar(
          context: context,
          message: exception.toString(),
        );
      },
    );
  }
}
