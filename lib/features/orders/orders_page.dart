import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/delivery_repo.dart';
import '../../models/delivery_models.dart';
import '../../widgets/status_chip.dart';
import '../../widgets/sign_out_action.dart';

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  StopStatus? _filter;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(deliveryControllerProvider);
    final repo = ref.read(deliveryControllerProvider.notifier).repo;
    final stops = repo.listStops(status: _filter, query: _search.text);
    final loadError = ref.watch(loadErrorProvider);
    final offline = ref.watch(offlineModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stops'),
        actions: const [SignOutAction()],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(deliveryControllerProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (offline)
              const Card(
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.cloud_off),
                  title: Text('Offline — cached list'),
                ),
              ),
            if (loadError != null)
              Card(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.55),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(loadError),
                ),
              ),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search order, customer, phone',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  const SizedBox(width: 6),
                  for (final s in [
                    StopStatus.assigned,
                    StopStatus.accepted,
                    StopStatus.pickedUp,
                    StopStatus.outForDelivery,
                    StopStatus.delivered,
                    StopStatus.failed,
                  ]) ...[
                    FilterChip(
                      label: Text(stopStatusLabel(s)),
                      selected: _filter == s,
                      onSelected: (_) => setState(() => _filter = s),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (stops.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No stops match this filter.'),
                ),
              )
            else
              ...stops.map((stop) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        foregroundColor: theme.colorScheme.onPrimaryContainer,
                        child: Text('${stop.sequence}'),
                      ),
                      title: Text(stop.customerName),
                      subtitle: Text(
                        '${stop.orderNumber}\n'
                        '${stop.address} · ${stop.windowLabel}',
                      ),
                      isThreeLine: true,
                      trailing: StatusChip(status: stop.status),
                      onTap: () => context.go('/orders/${stop.id}'),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
