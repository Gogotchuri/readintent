// This database file makes it possible to operate the app in offline mode.
// We store information and perform operations in the local database and sync with the server when online.
import "dart:io";

import "package:drift/drift.dart";
import "package:drift/native.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "package:sqlite3/sqlite3.dart";

part "app_database.g.dart";

class ArticlePreviews extends Table {
  IntColumn get id => integer().unique()();
  TextColumn get status => text()();
  TextColumn get title => text().withDefault(const Constant(""))();
  TextColumn get author => text().withDefault(const Constant(""))();
  TextColumn get date => text().withDefault(const Constant(""))();
  TextColumn get url => text().withDefault(const Constant(""))();
  TextColumn get categories => text().withDefault(const Constant("[]"))();
  TextColumn get description => text().withDefault(const Constant(""))();
  TextColumn get imageUrl => text().withDefault(const Constant(""))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  IntColumn get cachedAt => integer()();
  IntColumn get playerPositionMs => integer().withDefault(const Constant(0))();
  RealColumn get scrollPosition => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}

class ArticleDetails extends Table {
  IntColumn get id => integer().unique()();
  TextColumn get extractedHtml => text().withDefault(const Constant(""))();
  TextColumn get pureText => text().withDefault(const Constant(""))();
  BlobColumn get phonemizerBlob => blob().nullable()();
  IntColumn get cachedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// Operations that need to be performed when online and are queued when offline
class PendingOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  TextColumn get status => text().withDefault(const Constant("pending"))();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
}

@DriftDatabase(tables: [ArticlePreviews, ArticleDetails, PendingOperations])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        // Drop and recreate all tables on schema upgrade, we do not store critical data and this keeps migrations simple
        for (final table in allTables) {
          await m.deleteTable(table.actualTableName);
        }
        await m.createAll();
      },
      beforeOpen: (details) async {
        await customStatement("PRAGMA foreign_keys = ON");
      },
    );
  }

  // -- Articles --

  Future<List<ArticlePreview>> getAllPreviews() {
    return (select(articlePreviews)..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();
  }

  Future<void> upsertPreview(ArticlePreviewsCompanion entry) {
    return into(articlePreviews).insert(entry, mode: InsertMode.insertOrReplace);
  }

  // Replace all previews in a single transaction
  Future<void> replacePreviews(List<ArticlePreviewsCompanion> entries) {
    return transaction(() async {
      for (final entry in entries) {
        await into(articlePreviews).insert(entry, mode: InsertMode.insertOrReplace);
      }
    });
  }

  Future<void> deletePreview(int articleId) {
    return (delete(articlePreviews)..where((t) => t.id.equals(articleId))).go();
  }

  Future<ArticlePreview?> getPreview(int articleId) {
    return (select(articlePreviews)..where((t) => t.id.equals(articleId))).getSingleOrNull();
  }

  Future<ArticleDetail?> getDetail(int articleId) {
    return (select(articleDetails)..where((t) => t.id.equals(articleId))).getSingleOrNull();
  }

  Future<void> upsertDetail(ArticleDetailsCompanion entry) {
    return into(articleDetails).insert(entry, mode: InsertMode.insertOrReplace);
  }

  Future<void> updateProgress(int articleId, int playerPositionMs, double scrollPosition) {
    return (update(articlePreviews)..where((t) => t.id.equals(articleId))).write(
      ArticlePreviewsCompanion(
        playerPositionMs: playerPositionMs > 0 ? Value(playerPositionMs) : const Value.absent(),
        scrollPosition: scrollPosition > 0 ? Value(scrollPosition) : const Value.absent(),
      ),
    );
  }

  // -- PendingOperations --

  Future<List<PendingOperation>> getPendingOps() {
    return (select(pendingOperations)
          ..where((t) => t.status.equals("pending"))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<int> insertPendingOp(PendingOperationsCompanion entry) {
    return into(pendingOperations).insert(entry);
  }

  Future<void> deletePendingOp(int opId) {
    return (delete(pendingOperations)..where((t) => t.id.equals(opId))).go();
  }

  Future<void> updatePendingOp(int opId, {int? retryCount, String? lastError, String? status}) {
    return (update(pendingOperations)..where((t) => t.id.equals(opId))).write(
      PendingOperationsCompanion(
        retryCount: retryCount != null ? Value(retryCount) : const Value.absent(),
        lastError: lastError != null ? Value(lastError) : const Value.absent(),
        status: status != null ? Value(status) : const Value.absent(),
      ),
    );
  }
}

QueryExecutor _openDatabase() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, "readintent.db"));
    final cacheDir = await getTemporaryDirectory();
    sqlite3.tempDirectory = cacheDir.path;
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(_openDatabase());
  ref.onDispose(() => db.close());
  return db;
});
