import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'cache_db.g.dart';

/// Last known server responses, stored as JSON so the schedule can be shown
/// while offline (SRS 3.3 "drift (SQLite)", 4.4).
class CacheEntries extends Table {
  TextColumn get key => text()();
  TextColumn get json => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(tables: [CacheEntries])
class CacheDb extends _$CacheDb {
  CacheDb([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'homeslot_cache'));

  @override
  int get schemaVersion => 1;

  Future<String?> read(String key) async {
    final row = await (select(
      cacheEntries,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.json;
  }

  Future<void> write(String key, String json) =>
      into(cacheEntries).insertOnConflictUpdate(
        CacheEntriesCompanion.insert(
          key: key,
          json: json,
          updatedAt: DateTime.now(),
        ),
      );

  Future<void> clear() => delete(cacheEntries).go();
}
