// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:super_up_core/super_up_core.dart';

/// App bar displayed during message multi-selection mode
class VSelectionAppBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onClose;
  final VoidCallback onDelete;
  final VoidCallback onForward;

  const VSelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.onClose,
    required this.onDelete,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: context.isDark ? const Color(0xff272727) : Colors.white,
      surfaceTintColor: context.isDark ? const Color(0xff272727) : Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: onClose,
        tooltip: 'Cancel selection',
      ),
      title: Text(
        '$selectedCount',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: context.isDark ? Colors.white : Colors.black87,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: onDelete,
          tooltip: 'Delete',
        ),
        IconButton(
          icon: const Icon(CupertinoIcons.arrow_right),
          onPressed: onForward,
          tooltip: 'Forward',
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
