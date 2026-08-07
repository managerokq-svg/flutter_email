// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up/app/core/app_config/app_config_controller.dart';
import 'package:super_up/app/modules/home/mobile/story_tab/views/widgets/my_story_card.dart';
import 'package:super_up/app/modules/home/mobile/story_tab/views/widgets/story_widget.dart';
import 'package:super_up/app/modules/report/views/report_page.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_platform/v_platform.dart';

import '../../../../../core/models/story/story_model.dart';
import '../../../../story/story_view_page/story_view_page.dart';
import '../../../../story/story_views/story_viewers_screen.dart';
import '../controllers/story_tab_controller.dart';

class StoryTabView extends StatefulWidget {
  const StoryTabView({super.key});

  @override
  State<StoryTabView> createState() => _StoryTabViewState();
}

class _StoryTabViewState extends State<StoryTabView> {
  late final StoryTabController controller;

  @override
  void initState() {
    super.initState();
    controller = GetIt.I.get<StoryTabController>();
    controller.onInit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.refreshStoriesAfterOperation,
        color: Colors.green,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            CupertinoSliverNavigationBar(
              heroTag: 'story_nav_bar',
              largeTitle: Text(S.of(context).stories),
            ),
          ],
          body: ValueListenableBuilder<SLoadingState<StoryTabState>>(
            valueListenable: controller,
            builder: (_, value, __) {
              return CustomScrollView(
                slivers: [
                  // Ads Banner
                  SliverToBoxAdapter(
                    child: AdsBannerWidget(
                      adsId: VPlatforms.isAndroid
                          ? SConstants.androidBannerAdsUnitId
                          : SConstants.iosBannerAdsUnitId,
                      isEnableAds: VAppConfigController.appConfig.enableAds,
                    ),
                  ),
                  // My Story Card
                  SliverToBoxAdapter(
                    child: MyStoryCard(
                      storyModel: value.data.myStories,
                      isLoading: value.data.isMyStoriesLoading,
                      onTap: () => _viewMyStories(value),
                      onAddStory: () => controller.toCreateStory(context),
                      onViewersPressed: value.data.myStories.stories.isNotEmpty
                          ? () => _showStoryViewers(value.data.myStories)
                          : null,
                    ),
                  ),
                  // Recent Updates Section
                  if (controller.unmutedStories.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      S.of(context).recentUpdate,
                      count: controller.unmutedStories.length,
                    ),
                    _buildUnmutedStoriesList(value),
                  ],
                  // Muted Stories Section
                  if (controller.mutedStories.isNotEmpty) ...[
                    _buildSectionHeader(
                      context,
                      S.of(context).mutedUpdates,
                      count: controller.mutedStories.length,
                      isMuted: true,
                    ),
                    _buildMutedStoriesList(value),
                  ],
                  // Empty State
                  if (controller.visibleStories.isEmpty &&
                      value.loadingState != VChatLoadingState.loading)
                    SliverFillRemaining(
                      child: _buildEmptyState(context),
                    ),
                  // Loading State
                  if (value.loadingState == VChatLoadingState.loading &&
                      controller.visibleStories.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  // Bottom padding for glassmorphic nav bar
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButton: _buildFAB(context),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    int? count,
    bool isMuted = false,
  }) {
    final theme = Theme.of(context);
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Row(
          children: [
            if (isMuted) ...[
              Icon(
                Icons.volume_off,
                size: 16,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isMuted ? Colors.grey.shade500 : Colors.grey.shade700,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isMuted
                      ? Colors.grey.shade200
                      : Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMuted ? Colors.grey.shade600 : Colors.green,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUnmutedStoriesList(SLoadingState<StoryTabState> value) {
    final stories = controller.unmutedStories;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final storyModel = stories[index];
          return StoryWidget(
            storyModel: storyModel,
            isMuted: false,
            onTap: (story) => _viewStory(value, storyModel),
            onMute: (story) => controller.muteUser(story.userData.id),
            onHide: (story) => controller.hideUserStories(story.userData.id),
            onReport: (story) => _reportUser(story),
          );
        },
        childCount: stories.length,
      ),
    );
  }

  Widget _buildMutedStoriesList(SLoadingState<StoryTabState> value) {
    final stories = controller.mutedStories;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final storyModel = stories[index];
          return StoryWidget(
            storyModel: storyModel,
            isMuted: true,
            onTap: (story) => _viewStory(value, storyModel),
            onMute: (story) => controller.unmuteUser(story.userData.id),
            onHide: (story) => controller.hideUserStories(story.userData.id),
            onReport: (story) => _reportUser(story),
          );
        },
        childCount: stories.length,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_camera_outlined,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              S.of(context).noStoriesYet,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).noStoriesDescription,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => controller.toCreateStory(context),
              icon: const Icon(Icons.add),
              label: Text(S.of(context).createStory),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 90),
      child: FloatingActionButton(
        onPressed: () => controller.toCreateStory(context),
        backgroundColor: Colors.green,
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),
    );
  }

  void _viewMyStories(SLoadingState<StoryTabState> value) {
    if (value.data.myStories.stories.isEmpty) return;
    final allStories = value.data.myStories.stories.isNotEmpty
        ? [value.data.myStories, ...controller.visibleStories]
        : controller.visibleStories;
    context.toPage(
      StoryViewpage(
        allUserStories: allStories,
        initialIndex: 0,
        onDelete: (storyId) async {
          controller.removeStoryFromLocalState(storyId);
          await controller.refreshStoriesAfterOperation();
        },
      ),
    );
  }

  void _viewStory(
      SLoadingState<StoryTabState> value, UserStoryModel storyModel) {
    if (storyModel.stories.isEmpty) return;
    final hasMyStories = value.data.myStories.stories.isNotEmpty;
    final visibleStories = controller.visibleStories;
    final allStories = hasMyStories
        ? [value.data.myStories, ...visibleStories]
        : visibleStories;
    final storyIndex = visibleStories.indexOf(storyModel);
    final initialIndex = hasMyStories ? storyIndex + 1 : storyIndex;
    context.toPage(
      StoryViewpage(
        allUserStories: allStories,
        initialIndex: initialIndex,
        onDelete: storyModel.userData.isMe
            ? (storyId) async {
                controller.removeStoryFromLocalState(storyId);
                await controller.refreshStoriesAfterOperation();
              }
            : null,
      ),
    );
  }

  void _showStoryViewers(UserStoryModel storyModel) {
    if (storyModel.stories.isEmpty) return;
    context.toPage(
      StoryViewersScreen(storyId: storyModel.stories.first.id),
    );
  }

  void _reportUser(UserStoryModel storyModel) {
    context.toPage(
      ReportPage(userId: storyModel.userData.id),
    );
  }
}
