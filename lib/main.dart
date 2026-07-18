import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/offline_cache.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await OfflineCache.init();
  await DeliveryNotificationService.init();
  runApp(const ProviderScope(child: DeliveryApp()));
}
