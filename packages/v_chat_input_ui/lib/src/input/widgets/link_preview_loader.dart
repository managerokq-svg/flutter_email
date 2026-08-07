// Copyright 2023, the hatemragab project author.
// All rights reserved. Use of this source code is governed by a
// MIT license that can be found in the LICENSE file.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:v_chat_input_ui/src/input/widgets/telegram_glass_container.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

class LinkPreviewLoader extends StatefulWidget {
  const LinkPreviewLoader({
    super.key,
    required this.onGetData,
    required this.uri,
    required this.roomId,
  });

  final Uri uri;
  final String roomId;
  final Function(VLinkPreviewData? data) onGetData;

  @override
  State<LinkPreviewLoader> createState() => _LinkPreviewLoaderState();
}

Uri? _currentLoadedUrl;
List<Uri> _failureUrls = [];

class _LinkPreviewLoaderState extends State<LinkPreviewLoader> {
  @override
  Widget build(BuildContext context) {
    final colors = context.telegramColors;
    return FutureBuilder<WebMetadata>(
      future: _currentLoadedUrl == widget.uri
          ? null
          : _failureUrls.contains(widget.uri)
              ? null
              : fetchUrlContent(widget.uri.toString()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CupertinoActivityIndicator(
                    radius: 8,
                    color: colors.secondaryText,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading preview...',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.secondaryText,
                  ),
                ),
              ],
            ),
          );
        } else if (snapshot.hasError) {
          widget.onGetData(null);
          _failureUrls.add(widget.uri);
          return const SizedBox.shrink();
        } else {
          _currentLoadedUrl = widget.uri;
          final data = snapshot.data;
          if (data == null) {
            return const SizedBox.shrink();
          }
          widget.onGetData(
            VLinkPreviewData(
              link: data.url,
              title: data.title,
              description: data.description ?? data.url,
              image: data.images.isEmpty
                  ? data.favicons.first
                  : data.images.first,
            ),
          );
          return _TelegramLinkPreview(
            imageUrl: data.images.isEmpty
                ? data.favicons.first
                : data.images.first,
            title: data.title,
            description: data.description ?? data.url,
            url: data.url,
          );
        }
      },
    );
  }

  Future<WebMetadata> fetchUrlContent(String url) async {
    return VChatController.I.nativeApi.remote.room.getUrlPreview(
      roomId: widget.roomId,
      url: ensureHttpPrefix(url),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _currentLoadedUrl = null;
  }

  String ensureHttpPrefix(String url) {
    if (!url.startsWith(RegExp(r'https?:\/\/'))) {
      return 'https://$url';
    }
    return url;
  }
}

/// Telegram-style link preview card
class _TelegramLinkPreview extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String url;

  const _TelegramLinkPreview({
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.telegramColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: colors.glassBackground.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: colors.accent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Site name / URL domain
                  Text(
                    _extractDomain(url),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.accent,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.primaryText,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (description.isNotEmpty &&
                      description != url &&
                      description != title) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.secondaryText,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Image thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 72,
                height: 72,
                color: colors.secondaryText.withOpacity(0.1),
                child: Icon(
                  Icons.link_rounded,
                  color: colors.secondaryText.withOpacity(0.3),
                  size: 24,
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: 72,
                height: 72,
                color: colors.secondaryText.withOpacity(0.1),
                child: Icon(
                  Icons.link_rounded,
                  color: colors.secondaryText.withOpacity(0.3),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return url;
    }
  }
}
