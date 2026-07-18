import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local alerts when a new delivery order is assigned (foreground / tray).
class DeliveryNotificationService {
  DeliveryNotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _ready = false;
  static int _id = 1000;

  static const _androidChannel = AndroidNotificationChannel(
    'delivery_orders',
    'Delivery orders',
    description: 'New assigned delivery stops',
    importance: Importance.high,
  );

  static Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const linux = LinuxInitializationSettings(defaultActionName: 'Open');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: ios,
        macOS: ios,
        linux: linux,
      ),
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(_androidChannel);
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    _ready = true;
  }

  static Future<void> newOrder({
    required String orderNumber,
    required String customer,
  }) async {
    try {
      await init();
      await _plugin.show(
        _id++,
        'New delivery order',
        '$orderNumber · $customer',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          linux: const LinuxNotificationDetails(),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (_) {
      // Desktop/Linux may lack a notification daemon — in-app banner still works.
    }
  }
}
