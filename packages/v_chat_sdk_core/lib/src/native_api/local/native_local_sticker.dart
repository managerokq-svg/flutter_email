import 'package:sqflite/sqflite.dart';
import 'package:v_chat_sdk_core/src/local_db/tables/sticker_pack_table.dart';
import 'package:v_chat_sdk_core/src/local_db/tables/sticker_table.dart';
import 'package:v_platform/v_platform.dart';

class NativeLocalSticker {
  final Database? _db;
  // In-memory storage for web platform
  final Map<String, Map<String, dynamic>> _memoryPacks = {};
  final Map<String, List<Map<String, dynamic>>> _memoryStickers = {};

  NativeLocalSticker(this._db);

  Future<void> insertStickerPack(Map<String, dynamic> pack) async {
    if (VPlatforms.isWeb || _db == null) {
      final packId = pack['id'] as String;
      _memoryPacks[packId] = {
        'id': pack['id'],
        'name': pack['name'],
        'thumbnailUrl': pack['thumbnailUrl'],
        'fullThumbnailUrl': pack['fullThumbnailUrl'],
        'author': pack['author'],
        'isAnimated': pack['isAnimated'] == true,
        'version': pack['version'],
      };
      final stickers = pack['stickers'] as List;
      _memoryStickers[packId] = stickers.map((sticker) {
        final emojisList = sticker['emojis'];
        final emojisStr = emojisList is List ? emojisList.join(',') : emojisList?.toString() ?? '';
        return {
          'id': sticker['id'],
          'packId': pack['id'],
          'url': sticker['url'],
          'fullUrl': sticker['fullUrl'],
          'localPath': sticker['localPath'],
          'emojis': emojisStr,
        };
      }).toList();
      return;
    }
    await _db!.transaction((txn) async {
      await txn.insert(
        StickerPackTable.tableName,
        {
          StickerPackTable.columnId: pack['id'],
          StickerPackTable.columnName: pack['name'],
          StickerPackTable.columnThumbnailUrl: pack['thumbnailUrl'],
          StickerPackTable.columnAuthor: pack['author'],
          StickerPackTable.columnIsAnimated: pack['isAnimated'] == true ? 1 : 0,
          StickerPackTable.columnVersion: pack['version'],
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final stickers = pack['stickers'] as List;
      for (final sticker in stickers) {
        final emojisList = sticker['emojis'];
        final emojisStr = emojisList is List ? emojisList.join(',') : emojisList?.toString() ?? '';
        await txn.insert(
          StickerTable.tableName,
          {
            StickerTable.columnId: sticker['id'],
            StickerTable.columnPackId: pack['id'],
            StickerTable.columnUrl: sticker['url'],
            StickerTable.columnLocalPath: sticker['localPath'],
            StickerTable.columnEmojis: emojisStr,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAllStickerPacks() async {
    if (VPlatforms.isWeb || _db == null) {
      return _memoryPacks.values.toList();
    }
    final rows = await _db!.query(StickerPackTable.tableName);
    // Map snake_case SQLite columns to camelCase for consistency
    return rows.map((row) => {
      'id': row['id'],
      'name': row['name'],
      'thumbnailUrl': row['thumbnail_url'],
      'author': row['author'],
      'isAnimated': row['is_animated'] == 1,
      'version': row['version'],
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getStickersForPack(String packId) async {
    if (VPlatforms.isWeb || _db == null) {
      return _memoryStickers[packId] ?? [];
    }
    final rows = await _db!.query(
      StickerTable.tableName,
      where: '${StickerTable.columnPackId} = ?',
      whereArgs: [packId],
    );
    // Map snake_case SQLite columns to camelCase for consistency
    return rows.map((row) => {
      'id': row['id'],
      'packId': row['pack_id'],
      'url': row['url'],
      'localPath': row['local_path'],
      'emojis': row['emojis'],
    }).toList();
  }

  Future<void> deleteStickerPack(String packId) async {
    if (VPlatforms.isWeb || _db == null) {
      _memoryPacks.remove(packId);
      _memoryStickers.remove(packId);
      return;
    }
    await _db!.delete(
      StickerPackTable.tableName,
      where: '${StickerPackTable.columnId} = ?',
      whereArgs: [packId],
    );
  }

  Future<Map<String, dynamic>?> getSticker(String stickerId) async {
    if (VPlatforms.isWeb || _db == null) {
      for (final stickers in _memoryStickers.values) {
        for (final sticker in stickers) {
          if (sticker['id'] == stickerId) {
            return sticker;
          }
        }
      }
      return null;
    }
    final result = await _db!.query(
      StickerTable.tableName,
      where: '${StickerTable.columnId} = ?',
      whereArgs: [stickerId],
    );
    if (result.isNotEmpty) {
      final row = result.first;
      return {
        'id': row['id'],
        'packId': row['pack_id'],
        'url': row['url'],
        'localPath': row['local_path'],
        'emojis': row['emojis'],
      };
    }
    return null;
  }
}
