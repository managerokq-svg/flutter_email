import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:s_translation/generated/l10n.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

class GifPicker extends StatefulWidget {
  final Function(Map<String, dynamic>) onGifSelected;

  const GifPicker({
    super.key,
    required this.onGifSelected,
  });

  @override
  State<GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends State<GifPicker> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _gifs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTrending();
  }

  Future<void> _loadTrending() async {
    setState(() => _isLoading = true);
    try {
      final response = await VChatController.I.nativeApi.remote.nativeHttp(
        Uri.parse(
          'https://api.giphy.com/v1/gifs/trending?api_key=${SConstants.giphyApiKey}&limit=20',
        ),
        method: VChatHttpMethods.get,
        body: null,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _gifs = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _search(String query) async {
    if (query.isEmpty) return _loadTrending();
    setState(() => _isLoading = true);
    try {
      final response = await VChatController.I.nativeApi.remote.nativeHttp(
        Uri.parse(
          'https://api.giphy.com/v1/gifs/search?api_key=${SConstants.giphyApiKey}&q=$query&limit=20',
        ),
        method: VChatHttpMethods.get,
        body: null,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _gifs = data['data'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: S.of(context).searchGifs,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onSubmitted: _search,
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _gifs.length,
                  itemBuilder: (context, index) {
                    final gif = _gifs[index];
                    final images = gif['images'];
                    final fixedHeight = images['fixed_height'];
                    final original = images['original'];
                    final previewUrl = fixedHeight['url'] as String;
                    final originalUrl = original['url'] as String;
                    final width = int.tryParse(original['width'].toString()) ?? 1;
                    final height = int.tryParse(original['height'].toString()) ?? 1;
                    return GestureDetector(
                      onTap: () => widget.onGifSelected({
                        'url': originalUrl,
                        'aspectRatio': width / height,
                      }),
                      child: CachedNetworkImage(
                        imageUrl: previewUrl,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
