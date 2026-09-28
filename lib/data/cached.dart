import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:homeslot_client/homeslot_client.dart';

import '../core/client.dart';
import 'cache_db.dart';

final cacheDbProvider = Provider<CacheDb>((ref) {
  final db = CacheDb();
  ref.onDispose(db.close);
  return db;
});

/// True while the server cannot be reached and cached data is shown.
final offlineProvider = NotifierProvider<OfflineNotifier, bool>(
  OfflineNotifier.new,
);

class OfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool offline) {
    if (state != offline) state = offline;
  }
}

/// Fetches from the server and keeps a copy in the local cache. When the
/// server cannot be reached, returns the cached copy and switches the app to
/// read-only offline mode.
Future<T> cachedFetch<T>(
  Ref ref,
  String key,
  Future<T> Function() fetch,
) async {
  // Read dependencies before awaiting: an auto-disposed provider may be
  // disposed while the request is in flight, and its ref is then unusable.
  final db = ref.read(cacheDbProvider);
  final offline = ref.read(offlineProvider.notifier);
  try {
    final value = await fetch();
    offline.set(false);
    unawaited(db.write(key, SerializationManager.encode(value)));
    return value;
  } catch (error) {
    if (!isConnectionError(error)) rethrow;
    offline.set(true);
    final json = await db.read(key);
    if (json == null) rethrow;
    return client.serializationManager.decode<T>(json);
  }
}
