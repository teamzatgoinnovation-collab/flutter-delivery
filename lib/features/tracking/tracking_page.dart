import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/delivery_repo.dart';
import '../../services/location_service.dart';
import '../../widgets/sign_out_action.dart';

class TrackingPage extends ConsumerStatefulWidget {
  const TrackingPage({super.key});

  @override
  ConsumerState<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends ConsumerState<TrackingPage> {
  bool _busy = false;
  bool _auto = false;
  String? _message;
  Timer? _timer;
  final _location = LocationService();

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _share() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final fix = await _location.current();
      if (fix == null) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _message = 'Location permission denied or GPS off';
        });
        return;
      }
      await ref
          .read(deliveryControllerProvider.notifier)
          .shareLocation(lat: fix.lat, lng: fix.lng, speedKmh: fix.speedKmh);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Location shared';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Share failed: $e';
      });
    }
  }

  void _toggleAuto(bool on) {
    _timer?.cancel();
    setState(() => _auto = on);
    if (on) {
      _share();
      _timer = Timer.periodic(const Duration(seconds: 45), (_) => _share());
    }
  }

  @override
  Widget build(BuildContext context) {
    final pings = ref.watch(trackingProvider);
    final route = ref.watch(routeSummaryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracking'),
        actions: const [SignOutAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: _Stat(label: 'Points', value: '${route.points}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(label: 'Bonus', value: '${route.bonus}'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stat(
                  label: 'Distance',
                  value: '${route.distanceKm.toStringAsFixed(1)} km',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Auto share while on this tab'),
            subtitle: const Text('Every 45s (foreground only)'),
            value: _auto,
            onChanged: _busy ? null : _toggleAuto,
          ),
          FilledButton.icon(
            onPressed: _busy ? null : _share,
            icon: const Icon(Icons.my_location),
            label: Text(_busy ? 'Sharing…' : 'Share my location'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
            Text(
              _message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text('Recent pings', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (pings.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No location shared yet.'),
              ),
            )
          else
            ...pings.map((ping) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Text(
                      ping.atLabel.split(':').first,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  title: Text(ping.note),
                  subtitle: Text(
                    '${ping.atLabel} · ${ping.lat.toStringAsFixed(4)}, '
                    '${ping.lng.toStringAsFixed(4)} · '
                    '${ping.speedKmh.toStringAsFixed(0)} km/h',
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
