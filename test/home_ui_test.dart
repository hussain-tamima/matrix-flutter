import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/local_storage/session_store.dart';
import 'package:element_x/features/announcement/cubit/announcement_cubit.dart';
import 'package:element_x/features/home/cubit/home_cubit.dart';
import 'package:element_x/features/home/view/home_screen.dart';
import 'package:element_x/theme/app_theme.dart';
import 'package:element_x/theme/rop_assets.dart';
import 'package:element_x/widgets/app_drawer.dart';
import 'package:element_x/widgets/ltr_brand_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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

  tearDownAll(resetDependencies);

  testWidgets('home uses full-bleed artwork and responsive navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpHome(tester, theme: AppTheme.light(useInter: false));

    final artwork = tester.widget<LtrBrandImage>(
      find.byWidgetPredicate(
        (widget) =>
            widget is LtrBrandImage && widget.asset == RopAssets.homeGlass,
      ),
    );
    expect(artwork.fit, BoxFit.cover);
    expect(artwork.alignment, const Alignment(0.15, -0.05));
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).extendBodyBehindAppBar,
      isTrue,
    );

    tester.view.physicalSize = const Size(1000, 800);
    await tester.pumpAndSettle();

    expect(find.byType(AppNavigationPanel), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).extendBodyBehindAppBar,
      isFalse,
    );
  });
}

Future<void> _pumpHome(WidgetTester tester, {required ThemeData theme}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<HomeCubit>()),
            BlocProvider(create: (_) => sl<AnnouncementCubit>()),
          ],
          child: const HomeScreen(),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MaterialApp.router(
          theme: theme,
          routerConfig: router,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
