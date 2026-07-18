import 'package:delivery/app.dart';
import 'package:delivery/data/offline_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await OfflineCache.init();
  });

  testWidgets('Delivery app redirects to login when signed out', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: DeliveryApp()));
    await tester.pumpAndSettle();

    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
