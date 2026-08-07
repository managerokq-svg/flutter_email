import 'package:sqflite/sqflite.dart';

class StickerTable {
  static const String tableName = 'stickers';
  static const String columnId = 'id';
  static const String columnPackId = 'pack_id';
  static const String columnUrl = 'url';
  static const String columnLocalPath = 'local_path';
  static const String columnEmojis = 'emojis';

  static Future<void> createTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        $columnId TEXT PRIMARY KEY,
        $columnPackId TEXT NOT NULL,
        $columnUrl TEXT NOT NULL,
        $columnLocalPath TEXT,
        $columnEmojis TEXT,
        FOREIGN KEY ($columnPackId) REFERENCES sticker_packs (id) ON DELETE CASCADE
      )
    ''');
  }
}
