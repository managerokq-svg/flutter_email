import 'package:flutter/material.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_media_editor/v_chat_media_editor.dart';
import 'package:v_platform/v_platform.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

import '../../../core/utils/enums.dart';
import '../media_story/create_media_story.dart';
import '../text_story/create_text_story.dart';
import '../voice_story/create_voice_story.dart';

class CreateStoryPageState {
  List<AssetEntity> recentAssets = [];
  bool isLoadingAssets = true;
}

class CreateStoryPageController extends ValueNotifier<CreateStoryPageState> {
  CreateStoryPageController() : super(CreateStoryPageState());

  Future<void> loadRecentAssets() async {
    if (!VPlatforms.isMobile) {
      value.isLoadingAssets = false;
      notifyListeners();
      return;
    }
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        value.isLoadingAssets = false;
        notifyListeners();
        return;
      }
      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
        ),
      );
      if (albums.isEmpty) {
        value.isLoadingAssets = false;
        notifyListeners();
        return;
      }
      final recentAlbum = albums.first;
      final assets = await recentAlbum.getAssetListPaged(page: 0, size: 20);
      value.recentAssets = assets;
      value.isLoadingAssets = false;
      notifyListeners();
    } catch (e) {
      value.isLoadingAssets = false;
      notifyListeners();
    }
  }

  Future<void> openCamera(BuildContext context) async {
    final entity = await CameraPicker.pickFromCamera(
      context,
      pickerConfig: CameraPickerConfig(
        enableRecording: true,
        enableTapRecording: true,
        maximumRecordingDuration: const Duration(seconds: 60),
        textDelegate: const EnglishCameraPickerTextDelegate(),
        shouldAutoPreviewVideo: true,
      ),
    );
    if (entity == null || !context.mounted) return;
    await _processAssetEntity(context, entity);
  }

  Future<void> openGallery(BuildContext context) async {
    final assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.common,
        themeColor: Theme.of(context).primaryColor,
      ),
    );
    if (assets == null || assets.isEmpty || !context.mounted) return;
    await _processAssetEntity(context, assets.first);
  }

  Future<void> onRecentAssetTap(BuildContext context, AssetEntity asset) async {
    await _processAssetEntity(context, asset);
  }

  Future<void> _processAssetEntity(BuildContext context, AssetEntity asset) async {
    final file = await asset.file;
    if (file == null || !context.mounted) return;
    final platformFile = VPlatformFile.fromPath(fileLocalPath: file.path);
    final isVideo = asset.type == AssetType.video;
    final storyType = isVideo ? StoryType.video : StoryType.image;
    // Open media editor
    final mediaAfterEdit = await context.toPage(
      VMediaEditorView(files: [platformFile]),
    ) as List<VBaseMediaRes>?;
    if (mediaAfterEdit == null || mediaAfterEdit.isEmpty || !context.mounted) return;
    await context.toPage(
      CreateMediaStory(
        media: mediaAfterEdit.first,
        storyType: storyType,
      ),
    );
  }

  void openTextStory(BuildContext context) {
    context.toPage(const CreateTextStory());
  }

  void openVoiceStory(BuildContext context) {
    context.toPage(const CreateVoiceStory());
  }
}
