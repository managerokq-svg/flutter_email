import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/core/api_service/story/story_api_service.dart';
import 'package:super_up/app/core/models/story/story_model.dart';
import 'package:super_up/app/modules/peer_profile/views/peer_profile_view.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:v_story_viewer/v_story_viewer.dart';

import '../../../core/utils/enums.dart';
import '../../home/mobile/story_tab/controllers/story_tab_controller.dart';
import '../story_views/story_viewers_screen.dart';

class StoryViewpage extends StatefulWidget {
  final List<UserStoryModel> allUserStories;
  final int initialIndex;
  final Function(String storyId)? onDelete;

  const StoryViewpage({
    super.key,
    required this.allUserStories,
    required this.initialIndex,
    required this.onDelete,
  });

  @override
  State<StoryViewpage> createState() => _StoryViewpageState();
}

class _StoryViewpageState extends State<StoryViewpage> {
  late List<VStoryGroup> storyGroups;
  late Map<String, Map<int, StoryModel>> storyIndexMaps;
  final _api = GetIt.I.get<StoryApiService>();

  @override
  void initState() {
    super.initState();
    final parsed = _parseAllStoryGroups();
    storyGroups = parsed.groups;
    storyIndexMaps = parsed.indexMappings;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = widget.allUserStories[widget.initialIndex].userData;
    final isMe = currentUser.isMe;
    return VStoryViewer(
      storyGroups: storyGroups,
      initialGroupIndex: widget.initialIndex,
      config: (isMe ? VStoryConfig.forOwner() : VStoryConfig.forViewer())
          .copyWith(
        enableCaching: true,
        autoPauseOnBackground: true,
        hideStatusBar: true,
        texts: VStoryTexts(
          replyHint: S.of(context).textFieldHint,
        ),
      ),
      onComplete: (group, item) {
        // VStoryViewer calls pop() internally after this callback
        // Auto-advance is handled by VStoryViewer natively
      },
      onClose: (group, item) {
        // VStoryViewer calls pop() internally after this callback
      },
      onStoryViewed: (group, item) {
        final groupStories = group.stories;
        final index = groupStories.indexOf(item);
        final userIndexMap = storyIndexMaps[group.user.id];
        if (userIndexMap != null) {
          final storyModel = userIndexMap[index];
          if (storyModel != null) {
            unawaited(_setSeen(storyModel.id));
            GetIt.I.get<StoryTabController>().markStoryAsSeen(storyModel.id);
          }
        }
      },
      onUserTap: (group, item) async {
        if (group.user.id == AppAuth.myId) return true;
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PeerProfileView(
              peerId: group.user.id,
            ),
          ),
        );
        return true;
      },
      onMenuTap: isMe
          ? (group, item) async {
              final groupStories = group.stories;
              final index = groupStories.indexOf(item);
              final userIndexMap = storyIndexMaps[group.user.id];
              if (userIndexMap == null) return true;
              final storyModel = userIndexMap[index];
              if (storyModel == null) return true;
              final action = await _showStoryMenu(context, storyModel);
              return action;
            }
          : null,
      onReply: (group, item, text) {
        if (group.user.id == AppAuth.myId) return;
        final groupStories = group.stories;
        final index = groupStories.indexOf(item);
        final userIndexMap = storyIndexMaps[group.user.id];
        if (userIndexMap != null) {
          final storyModel = userIndexMap[index];
          if (storyModel != null) {
            _onReplySubmitted(storyModel.id, text);
          }
        }
      },
      onError: (group, item, error) {
        switch (error) {
          case VStoryNetworkError():
            debugPrint('Network error: ${error.message}');
          case VStoryTimeoutError():
            debugPrint('Timeout: ${error.message}');
          case VStoryCacheError():
            debugPrint('Cache error: ${error.message}');
          case VStoryFormatError():
            debugPrint('Format error: ${error.message}');
          case VStoryPermissionError():
            debugPrint('Permission error: ${error.message}');
          case VStoryLoadError():
            debugPrint('Load error: ${error.message}');
        }
      },
    );
  }

  Future<bool> _showStoryMenu(
      BuildContext context, StoryModel storyModel) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text(S.of(context).storyViewers),
              onTap: () => Navigator.pop(ctx, 'viewers'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                S.of(context).delete,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action == 'viewers' && context.mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => StoryViewersScreen(storyId: storyModel.id),
        ),
      );
      return true;
    }
    if (action == 'delete' && context.mounted) {
      final confirmed = await VAppAlert.showAskYesNoDialog(
        context: context,
        title: S.of(context).delete,
        content: S.of(context).areYouSure,
      );
      if (confirmed == 1) {
        try {
          await _api.deleteStory(storyModel.id);
          if (!context.mounted) return false;
          VAppAlert.showSuccessSnackBar(
            message: S.of(context).deleted,
            context: context,
          );
          widget.onDelete?.call(storyModel.id);
          Navigator.of(context).pop();
          return false;
        } catch (error) {
          if (!context.mounted) return true;
          VAppAlert.showErrorSnackBar(
            message: S.of(context).error,
            context: context,
          );
        }
      }
    }
    return true;
  }

  Future<void> _setSeen(String id) async {
    try {
      await _api.setSeen(id);
    } catch (e) {
      debugPrint('Error marking story as seen: $e');
    }
  }

  Future<void> _onReplySubmitted(String storyId, String reply) async {
    try {
      await _api.replyToStory(storyId: storyId, content: reply);
      if (!mounted) return;
      VAppAlert.showSuccessSnackBar(
        message: S.of(context).done,
        context: context,
      );
    } catch (e) {
      if (!mounted) return;
      VAppAlert.showErrorSnackBar(message: e.toString(), context: context);
    }
  }

  ({
    List<VStoryGroup> groups,
    Map<String, Map<int, StoryModel>> indexMappings
  }) _parseAllStoryGroups() {
    final List<VStoryGroup> groups = [];
    final Map<String, Map<int, StoryModel>> indexMappings = {};
    for (final userStory in widget.allUserStories) {
      final List<VStoryItem> items = [];
      final Map<int, StoryModel> indexMapping = {};
      for (final story in userStory.stories) {
        VStoryItem? item;
        if (story.storyType == StoryType.image) {
          final imageUrl = story.att?['url'] as String?;
          if (imageUrl == null || imageUrl.isEmpty) continue;
          item = VImageStory(
            url: SConstants.baseMediaUrl + imageUrl,
            isSeen: story.viewedByMe,
            duration: const Duration(seconds: 7),
            createdAt: DateTime.parse(story.createdAt),
            caption: story.caption,
          );
        } else if (story.storyType == StoryType.video) {
          final videoUrl = story.att?['url'] as String?;
          if (videoUrl == null || videoUrl.isEmpty) continue;
          final durationMs = story.att?['duration'] as int? ?? 15000;
          item = VVideoStory(
            url: SConstants.baseMediaUrl + videoUrl,
            isSeen: story.viewedByMe,
            duration: Duration(milliseconds: durationMs),
            createdAt: DateTime.parse(story.createdAt),
            caption: story.caption,
          );
        } else if (story.storyType == StoryType.voice) {
          final audioUrl = story.att?['url'] as String?;
          if (audioUrl == null || audioUrl.isEmpty) continue;
          final durationSec = story.att?['duration'] as int? ?? 30;
          item = VVoiceStory(
            url: SConstants.baseMediaUrl + audioUrl,
            isSeen: story.viewedByMe,
            duration: Duration(seconds: durationSec),
            createdAt: DateTime.parse(story.createdAt),
            backgroundColor: story.colorValue == null
                ? Colors.deepPurple
                : Color(story.colorValue!),
          );
        } else if (story.storyType == StoryType.text) {
          item = VTextStory(
            text: story.content,
            duration: const Duration(seconds: 10),
            createdAt: DateTime.parse(story.createdAt),
            isSeen: story.viewedByMe,
            textStyle: _getTextStyleForFont(story.fontType),
            backgroundColor: story.colorValue == null
                ? Colors.green
                : Color(story.colorValue!),
            enableParsing: true,
            parserConfig: _textParserConfig,
          );
        }
        if (item != null) {
          indexMapping[items.length] = story;
          items.add(item);
        }
      }
      if (items.isNotEmpty) {
        groups.add(VStoryGroup(
          user: VStoryUser(
            id: userStory.userData.id,
            name: userStory.userData.fullName,
            imageUrl: userStory.userData.userImageS3,
          ),
          stories: items,
        ));
        indexMappings[userStory.userData.id] = indexMapping;
      }
    }
    return (groups: groups, indexMappings: indexMappings);
  }

  TextStyle _getTextStyleForFont(StoryFontType fontType) {
    switch (fontType) {
      case StoryFontType.normal:
        return const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.w400,
        );
      case StoryFontType.bold:
        return const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        );
      case StoryFontType.italic:
        return const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontStyle: FontStyle.italic,
        );
    }
  }

  VTextParserConfig get _textParserConfig => VTextParserConfig(
        onUrlTap: (url) => _launchUrl(url),
        onPhoneTap: (phone) => _launchUrl('tel:$phone'),
        onEmailTap: (email) => _launchUrl('mailto:$email'),
        onMentionTap: (mention) => _openUserProfile(mention),
        onHashtagTap: (hashtag) => _searchHashtag(hashtag),
        urlStyle: const TextStyle(
          color: Colors.lightBlueAccent,
          decoration: TextDecoration.underline,
        ),
        phoneStyle: const TextStyle(
          color: Colors.lightBlueAccent,
          decoration: TextDecoration.underline,
        ),
        emailStyle: const TextStyle(
          color: Colors.lightBlueAccent,
          decoration: TextDecoration.underline,
        ),
        mentionStyle: const TextStyle(
          color: Colors.cyanAccent,
          fontWeight: FontWeight.w600,
        ),
        hashtagStyle: const TextStyle(
          color: Colors.pinkAccent,
          fontWeight: FontWeight.w600,
        ),
      );

  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to launch URL: $e');
    }
  }

  void _openUserProfile(String mention) {
    // Search for user by mention and open profile
    debugPrint('Open profile for: $mention');
  }

  void _searchHashtag(String hashtag) {
    // Search for hashtag
    debugPrint('Search hashtag: $hashtag');
  }
}
