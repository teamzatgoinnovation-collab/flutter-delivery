import '../data/offline_cache.dart';
import 'session.dart';

/// Flushes Hive outbox method calls when back online.
class SyncService {
  SyncService(this.session);

  final DeliverySession session;

  Future<int> flush() async {
    if (!session.connected) return 0;
    var ok = 0;
    for (final item in OfflineCache.peekOutbox()) {
      final id = '${item['id']}';
      final method = '${item['method']}';
      final args = item['args'];
      try {
        await session.store.callMethod(
          method,
          args: args is Map
              ? Map<String, dynamic>.from(args)
              : <String, dynamic>{},
        );
        await OfflineCache.removeOutbox(id);
        ok++;
      } catch (_) {
        // leave in outbox; stop to preserve order
        break;
      }
    }
    return ok;
  }
}
