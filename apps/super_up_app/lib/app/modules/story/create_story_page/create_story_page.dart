import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:v_platform/v_platform.dart';

import 'create_story_page_controller.dart';
import 'widgets/recent_media_grid.dart';
import 'widgets/story_type_card.dart';

class CreateStoryPage extends StatefulWidget {
  const CreateStoryPage({super.key});

  @override
  State<CreateStoryPage> createState() => _CreateStoryPageState();
}

class _CreateStoryPageState extends State<CreateStoryPage> {
  late final CreateStoryPageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateStoryPageController();
    _controller.loadRecentAssets();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).createStory),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Camera - Large card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StoryTypeCard(
                icon: Icons.camera_alt_rounded,
                title: S.of(context).camera,
                subtitle: S.of(context).takePhotoOrVideo,
                onTap: () => _controller.openCamera(context),
                isLarge: true,
                iconColor: Colors.blue,
              ),
            ),
            const SizedBox(height: 12),
            // Gallery, Text, Voice - Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: StoryTypeCard(
                      icon: Icons.photo_library_rounded,
                      title: S.of(context).gallery,
                      onTap: () => _controller.openGallery(context),
                      iconColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StoryTypeCard(
                      icon: Icons.text_fields_rounded,
                      title: S.of(context).text,
                      onTap: () => _controller.openTextStory(context),
                      iconColor: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StoryTypeCard(
                      icon: Icons.mic_rounded,
                      title: S.of(context).voice,
                      onTap: () => _controller.openVoiceStory(context),
                      iconColor: Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Recent Media Section
            if (VPlatforms.isMobile) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      S.of(context).recentMedia,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<CreateStoryPageState>(
                valueListenable: _controller,
                builder: (context, state, _) {
                  return RecentMediaGrid(
                    assets: state.recentAssets,
                    isLoading: state.isLoadingAssets,
                    onAssetTap: (asset) => _controller.onRecentAssetTap(context, asset),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
