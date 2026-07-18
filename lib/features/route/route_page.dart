import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/delivery_repo.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/sign_out_action.dart';

class RoutePage extends ConsumerWidget {
  const RoutePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final route = ref.watch(routeSummaryProvider);
    final stops = ref.watch(stopsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route'),
        actions: const [SignOutAction()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route.routeName, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Text('${route.vehicle} · ${route.etaLabel}'),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: route.stopCount == 0
                        ? 0
                        : route.deliveredCount / route.stopCount,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${route.deliveredCount}/${route.stopCount} delivered · '
                    '${route.pendingCount} pending · '
                    '${route.distanceKm.toStringAsFixed(1)} km · '
                    '${route.points} pts',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('Stop order', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...stops.map((stop) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Text(
                  '${stop.sequence}',
                  style: theme.textTheme.titleMedium,
                ),
                title: Text(stop.customerName),
                subtitle: Text(stop.windowLabel),
                trailing: StatusChip(status: stop.status),
                onTap: () => context.go('/orders/${stop.id}'),
              ),
            );
          }),
        ],
      ),
    );
  }
}
