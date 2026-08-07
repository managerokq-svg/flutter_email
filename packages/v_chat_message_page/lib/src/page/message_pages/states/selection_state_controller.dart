// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// State model for message selection mode
class SelectionState {
  final bool isSelectionMode;
  final Set<String> selectedIds;

  const SelectionState({
    required this.isSelectionMode,
    required this.selectedIds,
  });

  factory SelectionState.initial() => const SelectionState(
        isSelectionMode: false,
        selectedIds: {},
      );

  SelectionState copyWith({
    bool? isSelectionMode,
    Set<String>? selectedIds,
  }) {
    return SelectionState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

/// Controller for managing message multi-selection state
class SelectionStateController extends ValueNotifier<SelectionState> {
  SelectionStateController() : super(SelectionState.initial());

  bool get isSelectionMode => value.isSelectionMode;
  Set<String> get selectedIds => value.selectedIds;
  int get selectedCount => value.selectedIds.length;

  /// Enter selection mode with an initial selected message
  void enterSelectionMode(String initialMessageId) {
    value = SelectionState(
      isSelectionMode: true,
      selectedIds: {initialMessageId},
    );
  }

  /// Toggle selection of a message
  void toggleSelection(String messageId) {
    final newIds = Set<String>.from(value.selectedIds);
    if (newIds.contains(messageId)) {
      newIds.remove(messageId);
    } else {
      newIds.add(messageId);
    }
    // Auto-exit if no selection remaining
    if (newIds.isEmpty) {
      value = SelectionState.initial();
    } else {
      value = SelectionState(isSelectionMode: true, selectedIds: newIds);
    }
  }

  /// Exit selection mode and clear all selections
  void exitSelectionMode() {
    value = SelectionState.initial();
  }

  /// Select multiple messages at once
  void selectAll(List<String> messageIds) {
    if (messageIds.isEmpty) {
      value = SelectionState.initial();
    } else {
      value = SelectionState(
        isSelectionMode: true,
        selectedIds: messageIds.toSet(),
      );
    }
  }

  /// Check if a specific message is selected
  bool isSelected(String messageId) => value.selectedIds.contains(messageId);
}
