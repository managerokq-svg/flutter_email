import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/core/models/story/story_model.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_story_viewer/v_story_viewer.dart';

class StoryWidget extends StatelessWidget {
  final UserStoryModel storyModel;
  final Function(UserStoryModel storyModel) onTap;
  final Function(UserStoryModel storyModel)? onMute;
  final Function(UserStoryModel storyModel)? onHide;
  final Function(UserStoryModel storyModel)? onReport;
  final bool isMuted;
  final bool showSwipeActions;

  const StoryWidget({
    super.key,
    required this.storyModel,
    required this.onTap,
    this.onMute,
    this.onHide,
    this.onReport,
    this.isMuted = false,
    this.showSwipeActions = true,
  });

  int get storyCount => storyModel.stories.length;
  int get unseenCount => storyModel.stories.where((s) => !s.viewedByMe).length;
  bool get allSeen => storyModel.stories.every((s) => s.viewedByMe);

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (!showSwipeActions) return content;
    return Dismissible(
      key: Key('story_${storyModel.userData.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        _showOptionsMenu(context);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.grey.shade800,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.more_horiz, color: Colors.white.withValues(alpha: 0.9)),
            const SizedBox(width: 8),
            Text(
              S.of(context).options,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      child: content,
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onTap(storyModel),
      onLongPress: () => _showOptionsMenu(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _buildAvatar(context),
            const SizedBox(width: 12),
            Expanded(child: _buildInfo(context, theme)),
            _buildTrailing(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: isMuted ? 0.5 : 1.0,
          child: VStoryCircle(
            user: VStoryUser(
              id: storyModel.userData.id,
              name: storyModel.userData.fullName,
              imageUrl: storyModel.userData.userImageS3,
            ),
            storySeenStates: storyModel.stories.map((s) => s.viewedByMe).toList(),
            config: VStoryCircleConfig(
              size: 56,
              unseenColor: isMuted ? Colors.grey : Colors.green,
              seenColor: Colors.grey.shade400,
              ringWidth: 2.5,
              ringPadding: 2.5,
              segmentGap: 0.15,
            ),
          ),
        ),
        if (isMuted)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.volume_off,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                storyModel.userData.fullName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isMuted ? Colors.grey : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!allSeen && !isMuted) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unseenCount ${S.of(context).newText}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (storyCount > 1) ...[
              Icon(
                Icons.collections,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                '$storyCount',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.access_time,
              size: 14,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                _getTimeAgo(context),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context, ThemeData theme) {
    return Icon(
      Icons.chevron_right,
      color: Colors.grey.shade400,
    );
  }

  String _getTimeAgo(BuildContext context) {
    if (storyModel.stories.isEmpty) return '';
    final lastStory = storyModel.stories.last;
    return format(
      DateTime.parse(lastStory.createdAt).toLocal(),
      locale: Localizations.localeOf(context).languageCode,
    );
  }

  void _showOptionsMenu(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(storyModel.userData.userImageS3),
                ),
                title: Text(
                  storyModel.userData.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('$storyCount ${S.of(context).stories}'),
              ),
              const Divider(),
              if (onMute != null)
                ListTile(
                  leading: Icon(
                    isMuted ? Icons.volume_up : Icons.volume_off,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    isMuted ? S.of(context).unmute : S.of(context).mute,
                  ),
                  subtitle: Text(
                    isMuted
                        ? S.of(context).showStoriesInFeed
                        : S.of(context).hideStoriesFromFeed,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onMute?.call(storyModel);
                  },
                ),
              if (onHide != null)
                ListTile(
                  leading: Icon(
                    Icons.visibility_off,
                    color: Colors.orange.shade700,
                  ),
                  title: Text(S.of(context).hideStories),
                  subtitle: Text(S.of(context).hideStoriesDescription),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmHide(context);
                  },
                ),
              if (onReport != null)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.red),
                  title: Text(S.of(context).report),
                  onTap: () {
                    Navigator.pop(context);
                    onReport?.call(storyModel);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmHide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).hideStories),
        content: Text(
          '${S.of(context).hideStoriesConfirm} ${storyModel.userData.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onHide?.call(storyModel);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(S.of(context).hide),
          ),
        ],
      ),
    );
  }
}
