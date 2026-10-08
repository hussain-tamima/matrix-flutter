import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/app/element_app.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/local_storage/session_store.dart';
import 'package:element_x/core/utils/test_keys.dart';
import 'package:element_x/features/splash/cubit/splash_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/shared_preferences'),
          (call) async => switch (call.method) {
            'getAll' => <String, Object>{},
            _ => null,
          },
        );
    await EasyLocalization.ensureInitialized();
    await initDependencies(
      sessionStore: MemorySessionStore(),
      inMemoryDatabase: true,
    );
  });

  tearDownAll(() async {
    await resetDependencies();
  });

  testWidgets('signed-out app shows sign-in and validates an empty username', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: const ElementApp(),
      ),
    );
    await tester.pump();
    await tester.pump(SplashCubit.bootDelay);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key(TestKeys.signIn)), findsOneWidget);
    await tester.tap(find.byKey(const Key(TestKeys.signIn)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key(TestKeys.continueProvider)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key(TestKeys.confirmProvider)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key(TestKeys.loginSubmit)));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username'), findsOneWidget);
    expect(find.text('Element HQ'), findsNothing);
  });
}
