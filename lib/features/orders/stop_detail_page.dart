import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/delivery_repo.dart';
import '../../models/delivery_models.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/sign_out_action.dart';

class StopDetailPage extends ConsumerStatefulWidget {
  const StopDetailPage({super.key, required this.stopId});

  final String stopId;

  @override
  ConsumerState<StopDetailPage> createState() => _StopDetailPageState();
}

class _StopDetailPageState extends ConsumerState<StopDetailPage> {
  final _noteController = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _launch(Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      setState(() => _message = 'Could not open $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stop = ref.watch(stopProvider(widget.stopId));
    final theme = Theme.of(context);

    if (stop == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Stop')),
        body: const Center(child: Text('Stop not found')),
      );
    }

    final done = stop.status == StopStatus.delivered;
    final controller = ref.read(deliveryControllerProvider.notifier);
    final next = nextStatuses(stop.status);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/orders'),
        ),
        title: Text(stop.orderNumber),
        actions: [
          const SignOutAction(),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: StatusChip(status: stop.status)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(stop.customerName, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text('${stop.address}, ${stop.city}'),
          if (stop.phone != null && stop.phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(stop.phone!, style: theme.textTheme.bodyMedium),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (stop.phone != null && stop.phone!.isNotEmpty) ...[
                FilledButton.tonalIcon(
                  onPressed: () =>
                      _launch(Uri(scheme: 'tel', path: stop.phone)),
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _launch(
                    Uri(
                      scheme: 'sms',
                      path: stop.phone,
                      queryParameters: {'body': 'Your delivery is on the way.'},
                    ),
                  ),
                  icon: const Icon(Icons.sms_outlined),
                  label: const Text('SMS'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    final phone = stop.phone!.replaceAll(RegExp(r'[^\d+]'), '');
                    _launch(Uri.parse('https://wa.me/$phone'));
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
              ],
              FilledButton.icon(
                onPressed: () {
                  final q = Uri.encodeComponent(
                    '${stop.address}, ${stop.city}',
                  );
                  if (stop.lat != 0 && stop.lng != 0) {
                    _launch(
                      Uri.parse(
                        'https://www.google.com/maps/dir/?api=1&destination=${stop.lat},${stop.lng}',
                      ),
                    );
                  } else {
                    _launch(
                      Uri.parse(
                        'https://www.google.com/maps/search/?api=1&query=$q',
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.navigation),
                label: const Text('Navigate'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kv('Order', stop.orderNumber),
                  if (stop.invoiceNumber != null)
                    _kv('Invoice', stop.invoiceNumber!),
                  _kv('Window', stop.windowLabel),
                  _kv('Items', stop.itemsSummary),
                  if (stop.paymentMethod != null)
                    _kv('Payment', stop.paymentMethod!),
                  _kv('COD', stop.codAmount.toStringAsFixed(2)),
                  _kv('Balance', stop.balance.toStringAsFixed(2)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!done &&
              stop.status != StopStatus.failed &&
              stop.status != StopStatus.rejected &&
              stop.status != StopStatus.cancelled) ...[
            Text('Update status', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in next)
                  if (s != StopStatus.delivered)
                    FilledButton.tonal(
                      onPressed: _busy
                          ? null
                          : () => _runAction(
                              () => controller.setStatus(stop.id, s),
                              stopStatusLabel(s),
                            ),
                      child: Text(stopStatusLabel(s)),
                    ),
              ],
            ),
            if (next.contains(StopStatus.delivered)) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _busy ? null : () => _complete(stop),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Mark delivered'),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _runAction(
                      () => controller.setStatus(stop.id, StopStatus.failed),
                      'Marked failed',
                    ),
              child: Text(
                'Mark failed',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          ] else if (done)
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Delivered.'),
              ),
            ),
          if (_busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_message != null) ...[
            const SizedBox(height: 12),
            Text(
              _message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runAction(Future<void> Function() action, String okMsg) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = okMsg;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Update failed: $e';
      });
    }
  }

  Future<void> _complete(DeliveryStop stop) async {
    final controller = ref.read(deliveryControllerProvider.notifier);
    final note = _noteController.text.trim();
    await _runAction(
      () => controller.capturePod(
        stopId: stop.id,
        method: PodMethod.none,
        photoNote: note.isEmpty ? 'Delivered' : note,
        paidAmount: stop.codAmount > 0 ? stop.codAmount : null,
      ),
      'Delivered · +10 points',
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
