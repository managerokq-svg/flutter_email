// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:super_up_core/super_up_core.dart';

import '../../../../../core/api_service/story/story_api_service.dart';
import '../../../../../core/models/story/story_model.dart';
import '../../../../story/create_story_page/create_story_page.dart';

class StoryTabState {
  List<UserStoryModel> allStories = [];
  UserStoryModel myStories =
      UserStoryModel(stories: [], userData: AppAuth.myProfile.baseUser);
  bool isMyStoriesLoading = false;
  Set<String> mutedUserIds = {};
  Set<String> hiddenUserIds = {};
}

class StoryTabController extends SLoadingController<StoryTabState> {
  StoryTabController() : super(SLoadingState(StoryTabState()));
  final _apiService = GetIt.I.get<StoryApiService>();
  Timer? _timer;

  static const _mutedUsersKey = 'story_muted_users';
  static const _hiddenUsersKey = 'story_hidden_users';

  @override
  void onInit() {
    _loadMutedAndHiddenUsers();
    getStories();
    _timer = Timer.periodic(const Duration(seconds: 130), (timer) {
      getStoriesFromApi();
    });
    getMyStoryFromApi();
  }

  @override
  void onClose() {
    _timer?.cancel();
  }

  void _loadMutedAndHiddenUsers() {
    final mutedList = VAppPref.getList(_mutedUsersKey);
    final hiddenList = VAppPref.getList(_hiddenUsersKey);
    if (mutedList != null) {
      data.mutedUserIds = mutedList.toSet();
    }
    if (hiddenList != null) {
      data.hiddenUserIds = hiddenList.toSet();
    }
  }

  Future<void> _saveMutedUsers() async {
    await VAppPref.setList(_mutedUsersKey, data.mutedUserIds.toList());
  }

  Future<void> _saveHiddenUsers() async {
    await VAppPref.setList(_hiddenUsersKey, data.hiddenUserIds.toList());
  }

  /// Get visible (non-hidden) stories
  List<UserStoryModel> get visibleStories {
    return data.allStories
        .where((story) => !data.hiddenUserIds.contains(story.userData.id))
        .toList();
  }

  /// Get unmuted stories (visible and not muted)
  List<UserStoryModel> get unmutedStories {
    return visibleStories
        .where((story) => !data.mutedUserIds.contains(story.userData.id))
        .toList();
  }

  /// Get muted stories (visible but muted)
  List<UserStoryModel> get mutedStories {
    return visibleStories
        .where((story) => data.mutedUserIds.contains(story.userData.id))
        .toList();
  }

  /// Check if a user is muted
  bool isUserMuted(String userId) => data.mutedUserIds.contains(userId);

  /// Check if a user is hidden
  bool isUserHidden(String userId) => data.hiddenUserIds.contains(userId);

  /// Toggle mute status for a user
  Future<void> toggleMuteUser(String userId) async {
    if (data.mutedUserIds.contains(userId)) {
      data.mutedUserIds.remove(userId);
    } else {
      data.mutedUserIds.add(userId);
    }
    await _saveMutedUsers();
    update();
  }

  /// Mute a user
  Future<void> muteUser(String userId) async {
    data.mutedUserIds.add(userId);
    await _saveMutedUsers();
    update();
  }

  /// Unmute a user
  Future<void> unmuteUser(String userId) async {
    data.mutedUserIds.remove(userId);
    await _saveMutedUsers();
    update();
  }

  /// Hide a user's stories
  Future<void> hideUserStories(String userId) async {
    data.hiddenUserIds.add(userId);
    await _saveHiddenUsers();
    update();
  }

  /// Unhide a user's stories
  Future<void> unhideUserStories(String userId) async {
    data.hiddenUserIds.remove(userId);
    await _saveHiddenUsers();
    update();
  }

  /// Get total story count for my stories
  int get myStoryCount => data.myStories.stories.length;

  /// Get unseen story count
  int getUnseenCount(UserStoryModel userStory) {
    return userStory.stories.where((s) => !s.viewedByMe).length;
  }

  /// Check if all stories are seen
  bool areAllStoriesSeen(UserStoryModel userStory) {
    return userStory.stories.every((s) => s.viewedByMe);
  }

  void getStories() async {
    try {
      final oldStories = VAppPref.getMap("api/stories/all");
      if (oldStories != null) {
        final list = oldStories['data'] as List;
        data.allStories = list.map((e) => UserStoryModel.fromMap(e)).toList();
        setStateSuccess();
      }
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
    }
    await getStoriesFromApi();
  }

  Future<void> getStoriesFromApi() async {
    vSafeApiCall(
      request: () {
        return _apiService.getUsersStories(page: 1, limit: 50);
      },
      onSuccess: (response) {
        for (int i = response.length - 1; i >= 0; i--) {
          var item = response[i];
          if (!data.allStories.contains(item)) {
            data.allStories.insert(0, item);
          }
        }
        if (response.isEmpty) {
          data.allStories.clear();
          unawaited(VAppPref.removeKey("api/stories/all"));
        } else {
          unawaited(VAppPref.setMap("api/stories/all", {
            "data": response.map((e) => e.toMap()).toList(),
          }));
        }
        setStateSuccess();
        update();
      },
    );
  }

  Future getMyStoryFromApi() async {
    vSafeApiCall<UserStoryModel?>(
      request: () {
        return _apiService.getMyStories();
      },
      onSuccess: (response) {
        if (response == null) {
          data.myStories =
              UserStoryModel(stories: [], userData: AppAuth.myProfile.baseUser);
        } else {
          data.myStories = response;
        }
        setStateSuccess();
        update();
      },
    );
  }

  /// Removes a specific story from the local state immediately after deletion
  void removeStoryFromLocalState(String storyId) async {
    data.myStories.stories.removeWhere((story) => story.id == storyId);
    for (int i = 0; i < data.allStories.length; i++) {
      final userStory = data.allStories[i];
      userStory.stories.removeWhere((story) => story.id == storyId);
      if (userStory.stories.isEmpty) {
        data.allStories.removeAt(i);
        break;
      }
    }
    await _apiService.deleteStory(storyId);
    setStateSuccess();
    update();
  }

  /// Marks a story as seen in local state for immediate UI update
  void markStoryAsSeen(String storyId) {
    for (final userStory in data.allStories) {
      for (int i = 0; i < userStory.stories.length; i++) {
        if (userStory.stories[i].id == storyId && !userStory.stories[i].viewedByMe) {
          userStory.stories[i] = userStory.stories[i].copyWith(viewedByMe: true);
          break;
        }
      }
    }
    update();
  }

  /// Refreshes stories data after any story operation
  Future<void> refreshStoriesAfterOperation() async {
    await Future.wait([
      getMyStoryFromApi(),
      getStoriesFromApi(),
    ]);
  }

  void toCreateStory(BuildContext context) async {
    await context.toPage(const CreateStoryPage());
    getMyStoryFromApi();
  }
}
