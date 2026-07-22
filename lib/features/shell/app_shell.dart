import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/delivery_repo.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assigned = ref.watch(assignedCountProvider);
    final live = ref.watch(livePollingProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        height: 72,
        elevation: 0,
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: assigned > 0,
              label: Text('$assigned'),
              child: const Icon(Icons.local_shipping_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: assigned > 0,
              label: Text('$assigned'),
              child: const Icon(Icons.local_shipping),
            ),
            label: 'Stops',
          ),
          const NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Route',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.my_location_outlined,
              color: live ? const Color(0xFF15803D) : null,
            ),
            selectedIcon: Icon(
              Icons.my_location,
              color: live ? const Color(0xFF15803D) : null,
            ),
            label: live ? 'Live · on' : 'Live',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_ethernet_outlined),
            selectedIcon: Icon(Icons.settings_ethernet),
            label: 'API',
          ),
        ],
      ),
    );
  }
}
