import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/connection/connection_page.dart';
import 'features/login/login_page.dart';
import 'features/orders/orders_page.dart';
import 'features/orders/stop_detail_page.dart';
import 'features/route/route_page.dart';
import 'features/shell/app_shell.dart';
import 'features/today/today_page.dart';
import 'features/tracking/tracking_page.dart';
import 'services/messenger.dart';
import 'services/session.dart';
import 'theme.dart';

final _routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(deliverySessionProvider);

  return GoRouter(
    initialLocation: '/today',
    refreshListenable: session,
    redirect: (context, state) {
      final loggingIn = state.matchedLocation == '/login';
      if (!session.canEnterApp && !loggingIn) return '/login';
      if (session.canEnterApp && loggingIn) return '/today';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return StopDetailPage(stopId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/route',
                builder: (context, state) => const RoutePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tracking',
                builder: (context, state) => const TrackingPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/connection',
                builder: (context, state) => const ConnectionPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class DeliveryApp extends ConsumerWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);
    return MaterialApp.router(
      title: 'ZatGo Delivery',
      theme: buildDeliveryTheme(brightness: Brightness.light),
      darkTheme: buildDeliveryTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
      scaffoldMessengerKey: deliveryMessengerKey,
      debugShowCheckedModeBanner: false,
    );
  }
}
