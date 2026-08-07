import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/core/models/story/story_model.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_story_viewer/v_story_viewer.dart';

class MyStoryCard extends StatelessWidget {
  final UserStoryModel storyModel;
  final VoidCallback onTap;
  final VoidCallback onAddStory;
  final VoidCallback? onViewersPressed;
  final bool isLoading;

  const MyStoryCard({
    super.key,
    required this.storyModel,
    required this.onTap,
    required this.onAddStory,
    this.onViewersPressed,
    this.isLoading = false,
  });

  bool get hasStories => storyModel.stories.isNotEmpty;
  int get storyCount => storyModel.stories.length;
  int get viewersCount {
    if (!hasStories) return 0;
    return storyModel.stories.first.viewedByMe ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: hasStories ? onTap : onAddStory,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildAvatar(context),
              const SizedBox(width: 12),
              Expanded(child: _buildContent(context)),
              _buildActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (isLoading) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Stack(
      children: [
        VStoryCircle(
          user: VStoryUser(
            id: storyModel.userData.id,
            name: storyModel.userData.fullName,
            imageUrl: storyModel.userData.userImageS3,
          ),
          storySeenStates: storyModel.stories.map((s) => s.viewedByMe).toList(),
          config: VStoryCircleConfig(
            size: 64,
            unseenColor: Colors.green,
            seenColor: Colors.grey.shade400,
            ringWidth: 3,
            ringPadding: 3,
            segmentGap: 0.15,
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: GestureDetector(
            onTap: onAddStory,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.add,
                size: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).myStatus,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (hasStories) ...[
          Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: Colors.green.shade400,
              ),
              const SizedBox(width: 6),
              Text(
                '$storyCount ${storyCount == 1 ? S.of(context).story : S.of(context).stories}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                _getTimeAgo(context),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ] else
          Text(
            S.of(context).addNewStory,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    if (isLoading) return const SizedBox.shrink();
    if (!hasStories) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          S.of(context).add,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onViewersPressed != null)
          IconButton(
            onPressed: onViewersPressed,
            icon: Icon(
              Icons.visibility_outlined,
              color: Colors.grey.shade600,
            ),
            tooltip: S.of(context).viewers,
          ),
        Icon(
          Icons.chevron_right,
          color: Colors.grey.shade400,
        ),
      ],
    );
  }

  String _getTimeAgo(BuildContext context) {
    if (!hasStories) return '';
    final lastStory = storyModel.stories.first;
    return format(
      DateTime.parse(lastStory.createdAt).toLocal(),
      locale: Localizations.localeOf(context).languageCode,
    );
  }
}
