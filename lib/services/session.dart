import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zatgo_dart_sdk/zatgo_dart_sdk.dart';

class DeliverySession extends ChangeNotifier {
  DeliverySession() {
    final base = const String.fromEnvironment(
      'FRAPPE_BASE_URL',
      defaultValue: 'https://demo.zatgo.online',
    );
    baseUrl = base.replaceAll(RegExp(r'/$'), '');
    Future.microtask(_hydratePrefs);
  }

  final ErpnextSessionStore store = ErpnextSessionStore();

  String baseUrl = 'https://demo.zatgo.online';
  String? user;
  String? fullName;
  String? lastError;
  String? lastUserHint;
  bool allowMockWithoutLogin = false;
  bool prefsReady = false;

  bool get connected => store.connected;
  bool get canEnterApp => connected;

  Future<void> _hydratePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBase = prefs.getString('delivery_base_url');
    if (savedBase != null && savedBase.isNotEmpty) {
      baseUrl = savedBase.replaceAll(RegExp(r'/$'), '');
    }
    lastUserHint = prefs.getString('delivery_last_user');
    prefsReady = true;
    notifyListeners();
  }

  Future<void> _persistPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('delivery_base_url', baseUrl);
    if (user != null) {
      await prefs.setString('delivery_last_user', user!);
    }
  }

  void updateBaseUrl(String value) {
    baseUrl = value.replaceAll(RegExp(r'/$'), '');
    unawaited(_persistPrefs());
    notifyListeners();
  }

  Future<ErpnextLoginResult> login({
    required String usr,
    required String pwd,
  }) async {
    final result = await store.login(baseUrl: baseUrl, usr: usr, pwd: pwd);
    if (result is ErpnextLoginOk) {
      user = result.session.user;
      fullName = result.session.fullName;
      baseUrl = result.session.baseUrl;
      lastError = null;
      allowMockWithoutLogin = false;
      await _persistPrefs();
    } else if (result is ErpnextLoginFail) {
      user = null;
      fullName = null;
      lastError = result.message;
    }
    notifyListeners();
    return result;
  }

  Future<void> logout() async {
    await store.logout();
    user = null;
    fullName = null;
    lastError = null;
    allowMockWithoutLogin = false;
    notifyListeners();
  }

  void continueOffline() {
    allowMockWithoutLogin = true;
    lastError = null;
    notifyListeners();
  }

  Future<ErpnextPingResult> ping() => erpnextPing(baseUrl);
}

final deliverySessionProvider = ChangeNotifierProvider<DeliverySession>((ref) {
  return DeliverySession();
});
