// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FontSizeSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const FontSizeSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      title: Text(label),
      subtitle: Row(
        children: [
          Text('${min.toInt()}'),
          Expanded(
            child: CupertinoSlider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: (max - min).toInt(),
              onChanged: onChanged,
            ),
          ),
          Text('${max.toInt()}'),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${value.toInt()}',
          style: TextStyle(
            fontSize: value,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
