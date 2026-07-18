import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zatgo_dart_sdk/zatgo_dart_sdk.dart';

import '../models/delivery_models.dart';
import '../services/location_service.dart';
import '../services/messenger.dart';
import '../services/notification_service.dart';
import '../services/session.dart';
import '../services/sync_service.dart';
import 'offline_cache.dart';

/// ERPNext-backed delivery store via `zatgo_core.api.v1.delivery` + Hive cache.
class DeliveryRepo {
  List<DeliveryStop> _stops = [];
  final Map<String, PodCapture> _pods = {};
  final List<TrackingPing> _trail = [];
  String _driverName = 'Driver';
  String _vehicle = '—';
  int _points = 0;
  int _bonus = 0;
  int _deliveriesDone = 0;
  double? _lastLat;
  double? _lastLng;
  String? _boyId;
  String? lastError;
  bool offlineMode = false;
  DeliverySession? _session;

  String? get boyId => _boyId;
  int get points => _points;
  int get bonus => _bonus;
  int get outboxCount => OfflineCache.outboxCount;

  RouteSummary get route {
    final delivered = _stops
        .where((s) => s.status == StopStatus.delivered)
        .length;
    final pending = _stops.where((s) => s.isActive).length;
    final cod = _stops.fold<double>(0, (a, s) => a + s.codAmount);
    var distance = 0.0;
    if (_lastLat != null && _lastLng != null) {
      for (final s in _stops.where((s) => s.isActive)) {
        distance += LocationService.haversineKm(
          _lastLat!,
          _lastLng!,
          s.lat,
          s.lng,
        );
      }
    }
    return RouteSummary(
      routeName: 'Delivery route',
      vehicle: _vehicle,
      driverName: _driverName,
      stopCount: _stops.length,
      deliveredCount: delivered > 0 ? delivered : _deliveriesDone,
      pendingCount: pending,
      points: _points,
      bonus: _bonus,
      codTotal: cod,
      distanceKm: distance,
      etaLabel: _stops.isEmpty ? 'No stops' : 'In progress',
    );
  }

  Map<StopStatus, int> statusCounts() {
    final m = <StopStatus, int>{};
    for (final s in _stops) {
      m[s.status] = (m[s.status] ?? 0) + 1;
    }
    return m;
  }

  Future<void> refreshFromErpnext(DeliverySession session) async {
    _session = session;
    lastError = null;
    offlineMode = false;
    if (!session.connected) {
      _loadCache();
      offlineMode = true;
      lastError = 'Offline — showing cached stops';
      return;
    }

    final sync = SyncService(session);
    try {
      await sync.flush();
    } catch (_) {}

    try {
      await session.store.callMethod(ZatGoApiMethods.deliveryPing);
    } catch (e) {
      _loadCache();
      offlineMode = true;
      lastError = 'Offline — using cache ($e)';
      return;
    }

    String? boyId;
    try {
      final boyEnv = await session.store.callMethod(
        ZatGoApiMethods.deliveryBoysEnsure,
      );
      final boy = boyEnv.data;
      if (boy is Map) {
        _driverName = '${boy['full_name'] ?? boy['name'] ?? 'Driver'}';
        final rawId = '${boy['id'] ?? boy['name'] ?? ''}';
        boyId = rawId.isEmpty ? null : rawId;
        final vehicle = boy['vehicle'];
        if (vehicle != null && '$vehicle'.isNotEmpty) {
          _vehicle = '$vehicle';
        }
        _applyPerformance(boy);
      }
    } catch (e) {
      boyId = null;
      _driverName = session.fullName ?? session.user ?? 'Driver';
      lastError =
          'No courier linked to ${session.user}. Showing all stops. ($e)';
    }
    _boyId = boyId;

    if (boyId != null) {
      try {
        final me = await session.store.callMethod(
          ZatGoApiMethods.deliveryTrackingMe,
        );
        if (me.data is Map) {
          final m = me.data as Map;
          _applyPerformance(m);
          _lastLat = double.tryParse('${m['last_lat'] ?? ''}');
          _lastLng = double.tryParse('${m['last_lng'] ?? ''}');
        }
      } catch (_) {}
    }

    try {
      final env = await session.store.callMethod(
        ZatGoApiMethods.deliveryStopsList,
        args: {'page': 1, 'page_size': 100, 'delivery_boy': ?boyId},
      );
      final rows = env.data is List ? env.data as List : const [];
      _stops = [
        for (var i = 0; i < rows.length; i++) _mapStop(rows[i] as Map, i),
      ];
      await OfflineCache.saveStops([for (final s in _stops) s.toCacheMap()]);
      if (_stops.isEmpty && lastError == null) {
        lastError = boyId == null
            ? 'No delivery stops yet. Charge a delivery sale in POS.'
            : 'No stops assigned to $_driverName.';
      }
    } catch (e) {
      _loadCache();
      offlineMode = true;
      lastError = 'Failed to load stops — using cache: $e';
    }
  }

  void _loadCache() {
    final cached = OfflineCache.loadStops();
    _stops = [for (final m in cached) DeliveryStop.fromCacheMap(m)];
  }

  void _applyPerformance(Map boy) {
    _points = int.tryParse('${boy['points'] ?? 0}') ?? 0;
    _deliveriesDone = int.tryParse('${boy['deliveries_done'] ?? 0}') ?? 0;
    _bonus =
        int.tryParse('${boy['bonus'] ?? (_points ~/ 50)}') ?? (_points ~/ 50);
  }

  DeliveryStop _mapStop(Map row, int i) {
    final phone = '${row['phone'] ?? ''}'.trim();
    return DeliveryStop(
      id: '${row['name'] ?? row['id'] ?? 'stop-$i'}',
      orderNumber:
          '${row['order'] ?? row['order_number'] ?? row['name'] ?? 'ORD-$i'}',
      customerName: '${row['customer'] ?? row['title'] ?? 'Stop ${i + 1}'}',
      address: '${row['address'] ?? ''}',
      city: '${row['city'] ?? ''}',
      windowLabel: '${row['window'] ?? '—'}',
      status: parseStopStatus('${row['status'] ?? ''}'),
      itemsSummary: '${row['items'] ?? ''}',
      sequence: row['sequence'] is int ? row['sequence'] as int : i + 1,
      requiresOtp: false,
      requiresSignature: true,
      lat: double.tryParse('${row['lat'] ?? ''}') ?? 0,
      lng: double.tryParse('${row['lng'] ?? ''}') ?? 0,
      phone: phone.isEmpty ? null : phone,
      podMethod: '${row['pod_method'] ?? ''}'.trim().isEmpty
          ? null
          : '${row['pod_method']}'.trim(),
      podSignedBy: '${row['pod_signed_by'] ?? ''}'.trim().isEmpty
          ? null
          : '${row['pod_signed_by']}'.trim(),
      invoiceNumber: '${row['invoice_number'] ?? ''}'.trim().isEmpty
          ? null
          : '${row['invoice_number']}'.trim(),
      area: '${row['area'] ?? ''}'.trim().isEmpty
          ? null
          : '${row['area']}'.trim(),
      priority: '${row['priority'] ?? 'Normal'}',
      remarks: '${row['remarks'] ?? ''}'.trim().isEmpty
          ? null
          : '${row['remarks']}'.trim(),
      paymentMethod: '${row['payment_method'] ?? ''}'.trim().isEmpty
          ? null
          : '${row['payment_method']}'.trim(),
      codAmount: double.tryParse('${row['cod_amount'] ?? 0}') ?? 0,
      paidAmount: double.tryParse('${row['paid_amount'] ?? 0}') ?? 0,
      balance: double.tryParse('${row['balance'] ?? 0}') ?? 0,
      deliveryCharges: double.tryParse('${row['delivery_charges'] ?? 0}') ?? 0,
      assignedAt: '${row['assigned_at'] ?? ''}'.trim().isEmpty
          ? null
          : '${row['assigned_at']}'.trim(),
      expectedAt: '${row['expected_at'] ?? ''}'.trim().isEmpty
          ? null
          : '${row['expected_at']}'.trim(),
      podPhoto: '${row['pod_photo'] ?? ''}'.trim().isEmpty
          ? null
          : '${row['pod_photo']}'.trim(),
    );
  }

  String _podMethodLabel(PodMethod method) => switch (method) {
    PodMethod.otp => 'OTP',
    PodMethod.signature => 'Signature',
    PodMethod.photo => 'Photo',
    PodMethod.none => 'Signature',
  };

  List<DeliveryStop> listStops({StopStatus? status, String? query}) {
    var sorted = [..._stops]..sort((a, b) => a.sequence.compareTo(b.sequence));
    if (status != null) {
      sorted = sorted.where((s) => s.status == status).toList();
    }
    final q = query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      sorted = sorted
          .where(
            (s) =>
                s.orderNumber.toLowerCase().contains(q) ||
                s.customerName.toLowerCase().contains(q) ||
                (s.phone ?? '').contains(q) ||
                s.address.toLowerCase().contains(q),
          )
          .toList();
    }
    return sorted;
  }

  DeliveryStop? getStop(String id) {
    for (final s in _stops) {
      if (s.id == id) return s;
    }
    return null;
  }

  PodCapture? getPod(String stopId) => _pods[stopId];

  List<TrackingPing> trackingTrail() => List.unmodifiable(_trail);

  Future<void> setStatus(String id, StopStatus status, {String? note}) async {
    await _persist(id, status, note: note, methodPath: _methodFor(status));
  }

  String _methodFor(StopStatus status) => switch (status) {
    StopStatus.accepted => ZatGoApiMethods.deliveryStopsAccept,
    StopStatus.rejected => ZatGoApiMethods.deliveryStopsReject,
    StopStatus.reachedRestaurant =>
      ZatGoApiMethods.deliveryStopsReachRestaurant,
    StopStatus.pickedUp => ZatGoApiMethods.deliveryStopsPickup,
    StopStatus.outForDelivery => ZatGoApiMethods.deliveryStopsStartDelivery,
    StopStatus.failed => ZatGoApiMethods.deliveryStopsFailDelivery,
    _ => ZatGoApiMethods.deliveryStopsUpdate,
  };

  Future<void> markArrived(String id) =>
      setStatus(id, StopStatus.outForDelivery);

  Future<void> markEnRoute(String id) =>
      setStatus(id, StopStatus.outForDelivery);

  Future<void> markFailed(String id) => setStatus(id, StopStatus.failed);

  Future<PodCapture> capturePod({
    required String stopId,
    required PodMethod method,
    String? otpCode,
    String? signedBy,
    String? photoNote,
    String? podPhoto,
    double? paidAmount,
  }) async {
    final pod = PodCapture(
      stopId: stopId,
      method: method,
      otpCode: otpCode,
      signedBy: signedBy,
      photoNote: photoNote,
      capturedAt: DateTime.now(),
    );
    await _persist(
      stopId,
      StopStatus.delivered,
      podMethod: method,
      otpCode: otpCode,
      signedBy: signedBy,
      photoNote: photoNote,
      podPhoto: podPhoto,
      paidAmount: paidAmount,
      methodPath: ZatGoApiMethods.deliveryStopsCompleteDelivery,
    );
    _pods[stopId] = pod;
    return pod;
  }

  Future<void> shareLocation({
    required double lat,
    required double lng,
    double speedKmh = 0,
  }) async {
    final session = _session;
    final args = {'lat': lat, 'lng': lng, 'speed_kmh': speedKmh};
    if (session != null && session.connected) {
      try {
        final env = await session.store.callMethod(
          ZatGoApiMethods.deliveryTrackingPing,
          args: args,
        );
        if (env.data is Map) _applyPerformance(env.data as Map);
      } catch (e) {
        await OfflineCache.enqueue(ZatGoApiMethods.deliveryTrackingPing, args);
        rethrow;
      }
    } else {
      await OfflineCache.enqueue(ZatGoApiMethods.deliveryTrackingPing, args);
    }
    _lastLat = lat;
    _lastLng = lng;
    final now = DateTime.now();
    final label =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _trail.insert(
      0,
      TrackingPing(
        atLabel: label,
        lat: lat,
        lng: lng,
        speedKmh: speedKmh,
        note: 'Location shared',
      ),
    );
    if (_trail.length > 20) _trail.removeLast();
  }

  Future<void> _persist(
    String id,
    StopStatus status, {
    PodMethod? podMethod,
    String? otpCode,
    String? signedBy,
    String? photoNote,
    String? podPhoto,
    String? note,
    double? paidAmount,
    required String methodPath,
  }) async {
    final args = <String, dynamic>{'name': id};
    // Alias methods (accept/pickup/complete_delivery/…) set status server-side.
    // Only stops.update takes an explicit status kwarg.
    if (methodPath == ZatGoApiMethods.deliveryStopsUpdate) {
      args['status'] = stopStatusLabel(status);
    }
    if (podMethod != null) args['pod_method'] = _podMethodLabel(podMethod);
    if (otpCode != null) args['pod_otp'] = otpCode;
    if (signedBy != null) args['pod_signed_by'] = signedBy;
    if (photoNote != null) args['pod_note'] = photoNote;
    if (note != null) args['pod_note'] = note;
    if (podPhoto != null) args['pod_photo'] = podPhoto;
    if (paidAmount != null) args['paid_amount'] = paidAmount;

    final session = _session;
    if (session != null && session.connected) {
      try {
        await session.store.callMethod(methodPath, args: args);
      } catch (e) {
        await OfflineCache.enqueue(methodPath, args);
        _setStatusLocal(id, status, podMethod: podMethod, signedBy: signedBy);
        rethrow;
      }
    } else {
      await OfflineCache.enqueue(methodPath, args);
    }
    _setStatusLocal(
      id,
      status,
      podMethod: podMethod,
      signedBy: signedBy,
      podPhoto: podPhoto,
      paidAmount: paidAmount,
    );
  }

  void _setStatusLocal(
    String id,
    StopStatus status, {
    PodMethod? podMethod,
    String? signedBy,
    String? podPhoto,
    double? paidAmount,
  }) {
    final i = _stops.indexWhere((s) => s.id == id);
    if (i < 0) return;
    final prev = _stops[i];
    _stops = [..._stops]
      ..[i] = prev.copyWith(
        status: status,
        podMethod: podMethod != null ? _podMethodLabel(podMethod) : null,
        podSignedBy: signedBy,
        podPhoto: podPhoto,
        paidAmount: paidAmount,
        balance: paidAmount != null
            ? (prev.codAmount - paidAmount).clamp(0, double.infinity)
            : null,
      );
    unawaited(OfflineCache.saveStops([for (final s in _stops) s.toCacheMap()]));
  }
}

class DeliveryController extends Notifier<int> {
  late final DeliveryRepo repo;
  Timer? _pollTimer;
  Set<String> _knownIds = {};
  bool _seeded = false;
  List<DeliveryStop> lastNewStops = const [];

  static const _pollEvery = Duration(seconds: 12);

  @override
  int build() {
    repo = DeliveryRepo();
    ref.listen<DeliverySession>(deliverySessionProvider, (prev, next) {
      Future.microtask(() async {
        await _refresh(notifyNew: false);
        _restartPolling();
      });
    });
    Future.microtask(() async {
      await _refresh(notifyNew: false);
      _restartPolling();
    });
    ref.onDispose(() {
      _pollTimer?.cancel();
    });
    return 0;
  }

  void _restartPolling() {
    _pollTimer?.cancel();
    final session = ref.read(deliverySessionProvider);
    if (!session.connected) {
      _seeded = false;
      _knownIds = {};
      return;
    }
    _pollTimer = Timer.periodic(_pollEvery, (_) {
      unawaited(_refresh(notifyNew: true));
    });
  }

  Future<void> _refresh({required bool notifyNew}) async {
    final session = ref.read(deliverySessionProvider);
    final before = {..._knownIds};
    await repo.refreshFromErpnext(session);
    final after = {for (final s in repo.listStops()) s.id};

    if (!_seeded) {
      _knownIds = after;
      _seeded = true;
      _bump();
      return;
    }

    final newIds = after.difference(before);
    lastNewStops = [
      for (final id in newIds)
        if (repo.getStop(id) != null) repo.getStop(id)!,
    ];
    _knownIds = after;
    _bump();

    if (notifyNew && lastNewStops.isNotEmpty) {
      for (final stop in lastNewStops) {
        await DeliveryNotificationService.newOrder(
          orderNumber: stop.orderNumber,
          customer: stop.customerName,
        );
      }
      final first = lastNewStops.first;
      final extra = lastNewStops.length - 1;
      deliveryMessengerKey.currentState?.clearSnackBars();
      deliveryMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            extra > 0
                ? 'New order ${first.orderNumber} (+$extra more)'
                : 'New order ${first.orderNumber} · ${first.customerName}',
          ),
          duration: const Duration(seconds: 6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _bump() => state = state + 1;

  Future<void> refresh() => _refresh(notifyNew: false);

  Future<void> setStatus(String id, StopStatus status, {String? note}) async {
    await repo.setStatus(id, status, note: note);
    _bump();
  }

  Future<void> markArrived(String id) async {
    await repo.markArrived(id);
    _bump();
  }

  Future<void> markEnRoute(String id) async {
    await repo.markEnRoute(id);
    _bump();
  }

  Future<PodCapture> capturePod({
    required String stopId,
    required PodMethod method,
    String? otpCode,
    String? signedBy,
    String? photoNote,
    String? podPhoto,
    double? paidAmount,
  }) async {
    final pod = await repo.capturePod(
      stopId: stopId,
      method: method,
      otpCode: otpCode,
      signedBy: signedBy,
      photoNote: photoNote,
      podPhoto: podPhoto,
      paidAmount: paidAmount,
    );
    _bump();
    return pod;
  }

  Future<void> markFailed(String id) async {
    await repo.markFailed(id);
    _bump();
  }

  Future<void> shareLocation({
    required double lat,
    required double lng,
    double speedKmh = 0,
  }) async {
    await repo.shareLocation(lat: lat, lng: lng, speedKmh: speedKmh);
    _bump();
  }
}

final deliveryControllerProvider = NotifierProvider<DeliveryController, int>(
  DeliveryController.new,
);

final stopsProvider = Provider<List<DeliveryStop>>((ref) {
  ref.watch(deliveryControllerProvider);
  return ref.read(deliveryControllerProvider.notifier).repo.listStops();
});

final routeSummaryProvider = Provider<RouteSummary>((ref) {
  ref.watch(deliveryControllerProvider);
  return ref.read(deliveryControllerProvider.notifier).repo.route;
});

final loadErrorProvider = Provider<String?>((ref) {
  ref.watch(deliveryControllerProvider);
  return ref.read(deliveryControllerProvider.notifier).repo.lastError;
});

final offlineModeProvider = Provider<bool>((ref) {
  ref.watch(deliveryControllerProvider);
  return ref.read(deliveryControllerProvider.notifier).repo.offlineMode;
});

final statusCountsProvider = Provider<Map<StopStatus, int>>((ref) {
  ref.watch(deliveryControllerProvider);
  return ref.read(deliveryControllerProvider.notifier).repo.statusCounts();
});

final stopProvider = Provider.family<DeliveryStop?, String>((ref, id) {
  ref.watch(deliveryControllerProvider);
  return ref.read(deliveryControllerProvider.notifier).repo.getStop(id);
});

final podProvider = Provider.family<PodCapture?, String>((ref, id) {
  ref.watch(deliveryControllerProvider);
  return ref.read(deliveryControllerProvider.notifier).repo.getPod(id);
});

final trackingProvider = Provider<List<TrackingPing>>((ref) {
  ref.watch(deliveryControllerProvider);
  return ref.read(deliveryControllerProvider.notifier).repo.trackingTrail();
});

final assignedCountProvider = Provider<int>((ref) {
  ref.watch(deliveryControllerProvider);
  final counts =
      ref.read(deliveryControllerProvider.notifier).repo.statusCounts();
  return counts[StopStatus.assigned] ?? 0;
});

final livePollingProvider = Provider<bool>((ref) {
  ref.watch(deliveryControllerProvider);
  final session = ref.watch(deliverySessionProvider);
  return session.connected;
});
