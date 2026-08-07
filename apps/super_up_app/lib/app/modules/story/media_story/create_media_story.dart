import 'dart:io' as io;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_media_editor/v_chat_media_editor.dart';
import 'package:video_player/video_player.dart';

import '../../../core/api_service/story/story_api_service.dart';
import '../../../core/models/story/create_story_dto.dart';
import '../../../core/utils/enums.dart';

class CreateMediaStory extends StatefulWidget {
  final VBaseMediaRes media;
  final StoryType storyType;

  const CreateMediaStory({
    super.key,
    required this.media,
    this.storyType = StoryType.image,
  });

  @override
  State<CreateMediaStory> createState() => _CreateMediaStoryState();
}

class _CreateMediaStoryState extends State<CreateMediaStory> {
  final _txtController = TextEditingController();
  final _api = GetIt.I.get<StoryApiService>();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  bool get _isVideo => widget.storyType == StoryType.video;

  @override
  void initState() {
    super.initState();
    if (_isVideo) {
      _initVideoPlayer();
    }
  }

  Future<void> _initVideoPlayer() async {
    final file = widget.media.getVPlatformFile();
    if (file.fileLocalPath != null) {
      _videoController = VideoPlayerController.file(
        io.File(file.fileLocalPath!),
      );
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      _videoController!.play();
      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
    }
  }

  @override
  void dispose() {
    _txtController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          S.of(context).createStory,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _isVideo ? _buildVideoPreview() : _buildImagePreview(),
              ),
            ),
            _buildCaptionInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return VPlatformCacheImageWidget(
      source: widget.media.getVPlatformFile(),
      size: const Size(500, 500),
    );
  }

  Widget _buildVideoPreview() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return GestureDetector(
      onTap: () {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
        setState(() {});
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          if (!_videoController!.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 48,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCaptionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              placeholder: S.of(context).writeACaption,
              controller: _txtController,
              style: const TextStyle(color: Colors.white),
              placeholderStyle: const TextStyle(color: Colors.white54),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.all(12),
              onPressed: uploadMediaStory,
              child: const Icon(
                Icons.send,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void uploadMediaStory() async {
    await vSafeApiCall(
      onLoading: () {
        VAppAlert.showLoading(context: context);
      },
      request: () async {
        Map<String, dynamic>? attachment;
        if (widget.media is VMediaImageRes) {
          attachment = (widget.media as VMediaImageRes).data.toMap();
        } else if (widget.media is VMediaVideoRes) {
          attachment = (widget.media as VMediaVideoRes).data.toMap();
        }
        final dto = CreateStoryDto(
          storyType: widget.storyType,
          content: widget.storyType.name,
          caption: _txtController.text.isEmpty ? null : _txtController.text,
          image: widget.media.getVPlatformFile(),
          attachment: attachment,
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
