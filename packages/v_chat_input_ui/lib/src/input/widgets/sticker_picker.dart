import 'dart:io';

import 'package:flutter/material.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';
import 'package:s_translation/generated/l10n.dart';

class StickerPicker extends StatefulWidget {
  final Function(Map<String, dynamic>) onStickerSelected;

  const StickerPicker({
    super.key,
    required this.onStickerSelected,
  });

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  List<Map<String, dynamic>> _myPacks = [];
  bool _isLoading = true;
  int _selectedPackIndex = 0;

  /// Get full URL for display, handling both relative keys and full URLs
  String _getFullUrl(String? url) {
    if (url == null) return '';
    if (url.startsWith('http')) return url;
    return '${SConstants.baseMediaUrl}$url';
  }

  @override
  void initState() {
    super.initState();
    _loadPacks();
  }

  Future<void> _loadPacks() async {
    try {
      final packs = await VChatController.I.stickerService.getMyPacks();
      if (mounted) {
        setState(() {
          _myPacks = packs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_myPacks.isEmpty) {
      return Center(
        child: TextButton(
          onPressed: () {
            // TODO: Navigate to Sticker Store
          },
          child: Text(S.of(context).getStickers),
        ),
      );
    }

    return Column(
      children: [
        // Tab bar for packs
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _myPacks.length + 1, // +1 for store icon
            itemBuilder: (context, index) {
              if (index == _myPacks.length) {
                return IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    // TODO: Navigate to Sticker Store
                  },
                );
              }
              final pack = _myPacks[index];
              final thumbnailUrl = _getFullUrl(
                  pack['fullThumbnailUrl'] ?? pack['thumbnailUrl']);
              return GestureDetector(
                onTap: () => setState(() => _selectedPackIndex = index),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: _selectedPackIndex == index
                      ? Colors.grey.withValues(alpha: 0.2)
                      : null,
                  child: Image.network(
                    thumbnailUrl,
                    width: 30,
                    height: 30,
                    errorBuilder: (_, __, ___) => const Icon(Icons.error),
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Stickers grid
        Expanded(
          child: Builder(
            builder: (context) {
              final packId = _myPacks[_selectedPackIndex]['id'] as String?;
              if (packId == null) {
                return Center(child: Text(S.of(context).packIdIsNull));
              }
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: VChatController.I.nativeApi.local.sticker
                    .getStickersForPack(packId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text(S.of(context).stickerError('${snapshot.error}')));
                  }
                  final stickers = snapshot.data ?? [];
                  if (stickers.isEmpty) {
                    return Center(child: Text(S.of(context).noStickersInPack));
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: stickers.length,
                    itemBuilder: (context, index) {
                      final sticker = stickers[index];
                      final localPath = sticker['localPath'] as String?;
                      // Use fullUrl if available, otherwise construct from url
                      final displayUrl =
                          _getFullUrl(sticker['fullUrl'] ?? sticker['url']);
                      return GestureDetector(
                        onTap: () => widget.onStickerSelected(sticker),
                        child: localPath != null && File(localPath).existsSync()
                            ? Image.file(File(localPath))
                            : displayUrl.isNotEmpty
                                ? Image.network(
                                    displayUrl,
                                    errorBuilder: (_, e, __) =>
                                        const Icon(Icons.broken_image),
                                  )
                                : const Icon(Icons.image_not_supported),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
