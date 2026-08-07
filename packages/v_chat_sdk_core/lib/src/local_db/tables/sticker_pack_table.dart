import 'package:sqflite/sqflite.dart';

class StickerPackTable {
  static const String tableName = 'sticker_packs';
  static const String columnId = 'id';
  static const String columnName = 'name';
  static const String columnThumbnailUrl = 'thumbnail_url';
  static const String columnAuthor = 'author';
  static const String columnIsAnimated = 'is_animated';
  static const String columnVersion = 'version';

  static Future<void> createTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnName TEXT NOT NULL,
        $columnThumbnailUrl TEXT NOT NULL,
        $columnAuthor TEXT NOT NULL,
        $columnIsAnimated INTEGER NOT NULL,
        $columnVersion INTEGER NOT NULL
      )
    ''');
  }
}
