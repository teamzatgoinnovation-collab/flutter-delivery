import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/delivery_repo.dart';
import '../../models/delivery_models.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/sign_out_action.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(routeSummaryProvider);
    final stops = ref.watch(stopsProvider);
    final counts = ref.watch(statusCountsProvider);
    final loadError = ref.watch(loadErrorProvider);
    final offline = ref.watch(offlineModeProvider);
    final next = stops.cast<DeliveryStop?>().firstWhere(
      (s) => s!.isActive,
      orElse: () => null,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZatGo Delivery'),
        actions: [
          const SignOutAction(),
          IconButton(
            tooltip: 'API connection',
            onPressed: () => context.go('/connection'),
            icon: const Icon(Icons.cloud_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(deliveryControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (offline)
              Card(
                color: theme.colorScheme.tertiaryContainer,
                child: const ListTile(
                  dense: true,
                  leading: Icon(Icons.cloud_off),
                  title: Text('Offline mode'),
                  subtitle: Text('Cached stops · sync when online'),
                ),
              ),
            Text(
              'Driver run',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(route.routeName, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${route.driverName} · ${route.vehicle}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (ref.watch(livePollingProvider)) ...[
              const SizedBox(height: 8),
              Text(
                'Live · checking for new orders every 12s',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF15803D),
                ),
              ),
            ],
            if (loadError != null) ...[
              const SizedBox(height: 12),
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.55),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    loadError,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _CountChip(
                  label: 'Assigned',
                  count: counts[StopStatus.assigned] ?? 0,
                ),
                _CountChip(
                  label: 'Accepted',
                  count: counts[StopStatus.accepted] ?? 0,
                ),
                _CountChip(
                  label: 'Picked up',
                  count: counts[StopStatus.pickedUp] ?? 0,
                ),
                _CountChip(
                  label: 'Out',
                  count: counts[StopStatus.outForDelivery] ?? 0,
                ),
                _CountChip(
                  label: 'Delivered',
                  count: counts[StopStatus.delivered] ?? 0,
                ),
                _CountChip(
                  label: 'Failed',
                  count: counts[StopStatus.failed] ?? 0,
                ),
                _CountChip(
                  label: 'Cancelled',
                  count: counts[StopStatus.cancelled] ?? 0,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Pending',
                    value: '${route.pendingCount}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: 'Completed',
                    value: '${route.deliveredCount}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: 'COD',
                    value: route.codTotal.toStringAsFixed(0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _StatTile(label: 'Points', value: '${route.points}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(label: 'Bonus', value: '${route.bonus}'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatTile(
                    label: 'Distance',
                    value: '${route.distanceKm.toStringAsFixed(1)} km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Next stop', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (next == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('All stops complete for this route.'),
                ),
              )
            else
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => context.go('/orders/${next.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${next.sequence} · ${next.orderNumber}',
                              style: theme.textTheme.labelLarge,
                            ),
                            const Spacer(),
                            StatusChip(status: next.status),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          next.customerName,
                          style: theme.textTheme.titleMedium,
                        ),
                        Text('${next.address}, ${next.city}'),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => context.go('/orders/${next.id}'),
                          child: const Text('Open stop'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label $count'),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

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
