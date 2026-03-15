import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';
import '../db/app_database.dart';
import 'sync_status.dart';

part 'sync_queue_service.g.dart';

@riverpod
SyncQueueService syncQueueService(Ref ref) {
  return SyncQueueService(
    db: ref.watch(appDatabaseProvider),
    ref: ref,
  );
}

/// Gère la file d'attente des mutations offline.
/// Quand le réseau revient, rejoue toutes les entrées en attente.
class SyncQueueService {
  final AppDatabase _db;
  final Ref _ref;

  SyncQueueService({required AppDatabase db, required Ref ref})
      : _db = db,
        _ref = ref {
    // Écoute les changements de connectivité
    Connectivity().onConnectivityChanged.listen((results) {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) flush();
    });
  }

  /// Ajoute une mutation dans la file offline.
  Future<void> enqueue({
    required String method,
    required String endpoint,
    Map<String, dynamic>? payload,
  }) async {
    await _db.into(_db.syncQueueTable).insert(
          SyncQueueTableCompanion.insert(
            method: method,
            endpoint: endpoint,
            payload: Value(payload != null ? jsonEncode(payload) : null),
          ),
        );
  }

  /// Rejoue toutes les mutations en attente.
  Future<SyncResult> flush() async {
    final pending = await (_db.select(_db.syncQueueTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    int synced = 0;
    int failed = 0;
    final dio = _ref.read(apiClientProvider);

    for (final entry in pending) {
      try {
        final body = entry.payload != null ? jsonDecode(entry.payload!) : null;
        switch (entry.method) {
          case 'POST':
            await dio.post(entry.endpoint, data: body);
          case 'PATCH':
            await dio.patch(entry.endpoint, data: body);
          case 'DELETE':
            await dio.delete(entry.endpoint);
        }
        await (_db.delete(_db.syncQueueTable)
              ..where((t) => t.id.equals(entry.id)))
            .go();
        synced++;
      } catch (_) {
        await (_db.update(_db.syncQueueTable)
              ..where((t) => t.id.equals(entry.id)))
            .write(SyncQueueTableCompanion(
              retryCount: Value(entry.retryCount + 1),
            ));
        failed++;
      }
    }

    return SyncResult(synced: synced, failed: failed);
  }
}
