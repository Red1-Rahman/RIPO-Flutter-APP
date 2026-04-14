// backend\lib\src\db\database.dart
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'schema.dart';

class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static AppDatabase openLocal({String? filePath}) {
    final resolvedPath =
        filePath ?? p.join(Directory.current.path, 'data', 'ripo.sqlite3');
    final directory = Directory(p.dirname(resolvedPath));
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    final database = sqlite3.open(resolvedPath);
    database.execute('PRAGMA foreign_keys = ON;');
    createSchema(database);
    seedIfEmpty(database);

    return AppDatabase._(database);
  }

  void close() {
    db.dispose();
  }
}
