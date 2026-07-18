import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Hive-backed stop cache + outbox for offline sync prep.
class OfflineCache {
  OfflineCache._();

  static const _stopsBox = 'stops_cache';
  static const _outboxBox = 'outbox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<String>(_stopsBox);
    await Hive.openBox<String>(_outboxBox);
  }

  static Box<String> get _stops => Hive.box<String>(_stopsBox);
  static Box<String> get _outbox => Hive.box<String>(_outboxBox);

  static Future<void> saveStops(List<Map<String, dynamic>> rows) async {
    await _stops.put('rows', jsonEncode(rows));
    await _stops.put('saved_at', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> loadStops() {
    final raw = _stops.get('rows');
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return [
      for (final e in decoded)
        if (e is Map) Map<String, dynamic>.from(e),
    ];
  }

  static Future<void> enqueue(String method, Map<String, dynamic> args) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    await _outbox.put(
      id,
      jsonEncode({
        'id': id,
        'method': method,
        'args': args,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  static List<Map<String, dynamic>> peekOutbox() {
    return [
      for (final v in _outbox.values)
        Map<String, dynamic>.from(jsonDecode(v) as Map),
    ]..sort((a, b) => '${a['createdAt']}'.compareTo('${b['createdAt']}'));
  }

  static Future<void> removeOutbox(String id) async {
    await _outbox.delete(id);
  }

  static int get outboxCount => _outbox.length;
}
