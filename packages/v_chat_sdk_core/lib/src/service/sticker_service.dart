import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:super_up_core/super_up_core.dart';
import 'package:v_chat_sdk_core/v_chat_sdk_core.dart';

class StickerService {
  final _nativeApi = VNativeApi.I;

  /// Normalize pack data: map _id to id
  /// URLs are kept as keys (relative paths) and converted to full URLs only when displaying
  Map<String, dynamic> _normalizePack(Map<String, dynamic> pack) {
    final normalized = Map<String, dynamic>.from(pack);
    // Map MongoDB _id to id
    if (normalized['_id'] != null && normalized['id'] == null) {
      normalized['id'] = normalized['_id'].toString();
    }
    // Keep thumbnailUrl as key, add fullThumbnailUrl for display
    if (normalized['thumbnailUrl'] != null &&
        !normalized['thumbnailUrl'].toString().startsWith('http')) {
      normalized['fullThumbnailUrl'] =
          '${SConstants.baseMediaUrl}${normalized['thumbnailUrl']}';
    } else {
      normalized['fullThumbnailUrl'] = normalized['thumbnailUrl'];
    }
    // Normalize stickers array - keep url as key, add fullUrl for display
    if (normalized['stickers'] != null) {
      normalized['stickers'] = (normalized['stickers'] as List).map((sticker) {
        final s = Map<String, dynamic>.from(sticker as Map);
        if (s['url'] != null && !s['url'].toString().startsWith('http')) {
          // Add full URL for display purposes
          s['fullUrl'] = '${SConstants.baseMediaUrl}${s['url']}';
        } else {
          s['fullUrl'] = s['url'];
        }
        return s;
      }).toList();
    }
    return normalized;
  }

  Future<List<Map<String, dynamic>>> getStorePacks() async {
    final uri = Uri.parse('${VAppConstants.baseUri}/stickers/store');
    print('[StickerService] Fetching store from: $uri');
    final response = await _nativeApi.remote.nativeHttp(
      uri,
      method: VChatHttpMethods.get,
      body: null,
    );
    print(
        '[StickerService] Store response: ${response.statusCode} - ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      // Handle both direct array and wrapped response { data: [...] }
      final List<dynamic> data;
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded['data'] != null) {
        data = decoded['data'] as List;
      } else {
        print(
            '[StickerService] Unexpected response format: ${decoded.runtimeType}');
        return [];
      }
      return data
          .map((p) => _normalizePack(p as Map<String, dynamic>))
          .toList();
    }
    throw Exception(
        'Failed to load sticker store: ${response.statusCode} - ${response.body}');
  }

  Future<List<Map<String, dynamic>>> getMyPacks() async {
    // Load local first for fast UI
    final localPacks = await _nativeApi.local.sticker.getAllStickerPacks();
    // Sync with server in background (don't await)
    _syncWithServer(localPacks);
    return localPacks;
  }

  Future<void> _syncWithServer(List<Map<String, dynamic>> localPacks) async {
    try {
      // Build map of local packs with their sticker counts
      final localPackMap = <String, int>{};
      for (final p in localPacks) {
        final id = (p['_id'] ?? p['id'])?.toString();
        if (id != null) {
          final stickers =
              await _nativeApi.local.sticker.getStickersForPack(id);
          localPackMap[id] = stickers.length;
        }
      }
      print('[StickerService] Local packs: $localPackMap');
      final storePacks = await getStorePacks();
      print('[StickerService] Store has ${storePacks.length} packs');
      for (final pack in storePacks) {
        final packId = pack['id'] as String;
        final localStickerCount = localPackMap[packId] ?? 0;
        // Skip only if pack exists locally AND has stickers
        if (localPackMap.containsKey(packId) && localStickerCount > 0) {
          print(
              '[StickerService] Pack $packId already has $localStickerCount stickers, skipping');
          continue;
        }
        print(
            '[StickerService] Pack $packId needs sync (local stickers: $localStickerCount)');
        // Fetch full pack and install
        print('[StickerService] Fetching full pack: $packId');
        final fullPackResponse = await _nativeApi.remote.nativeHttp(
          Uri.parse('${VAppConstants.baseUri}/stickers/pack/$packId'),
          method: VChatHttpMethods.get,
          body: null,
        );
        print('[StickerService] Pack response: ${fullPackResponse.statusCode}');
        if (fullPackResponse.statusCode == 200) {
          final rawPack =
              jsonDecode(fullPackResponse.body) as Map<String, dynamic>;
          print(
              '[StickerService] Raw pack stickers count: ${(rawPack['stickers'] as List?)?.length ?? 0}');
          final fullPack = _normalizePack(rawPack);
          print(
              '[StickerService] Normalized pack stickers count: ${(fullPack['stickers'] as List?)?.length ?? 0}');
          await _installPackLocally(fullPack);
          print('[StickerService] Pack installed locally');
        }
      }
    } catch (e, stack) {
      // Log error for debugging but don't crash - sync is background operation
      print('[StickerService] Sync error: $e');
      print('[StickerService] Stack: $stack');
    }
  }

  Future<void> installPack(String packId) async {
    // 1. Notify server
    final response = await _nativeApi.remote.nativeHttp(
      Uri.parse('${VAppConstants.baseUri}/stickers/install/$packId'),
      method: VChatHttpMethods.post,
      body: null,
    );
    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to install pack on server');
    }
    // 2. Get full pack details
    final packResponse = await _nativeApi.remote.nativeHttp(
      Uri.parse('${VAppConstants.baseUri}/stickers/pack/$packId'),
      method: VChatHttpMethods.get,
      body: null,
    );
    if (packResponse.statusCode == 200) {
      final rawPack = jsonDecode(packResponse.body) as Map<String, dynamic>;
      final packData = _normalizePack(rawPack);
      await _installPackLocally(packData);
    }
  }

  Future<void> _installPackLocally(Map<String, dynamic> pack) async {
    final stickers = pack['stickers'] as List;
    final docsDir = await getApplicationDocumentsDirectory();
    final packDir = Directory('${docsDir.path}/stickers/${pack['id']}');
    if (!packDir.existsSync()) {
      packDir.createSync(recursive: true);
    }

    for (var i = 0; i < stickers.length; i++) {
      final sticker = stickers[i];
      final fileName = '${sticker['id']}.webp'; // Assuming webp
      final file = File('${packDir.path}/$fileName');

      if (!file.existsSync()) {
        // Download sticker
        final response =
            await http.get(Uri.parse(SConstants.baseMediaUrl + sticker['url']));
        if (response.statusCode == 200) {
          await file.writeAsBytes(response.bodyBytes);
        }
      }
      stickers[i]['localPath'] = file.path;
    }

    pack['stickers'] = stickers;
    await _nativeApi.local.sticker.insertStickerPack(pack);
  }
}
