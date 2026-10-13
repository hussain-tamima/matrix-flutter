import 'package:easy_localization/easy_localization.dart';
import 'package:element_x/core/config/app_config.dart';
import 'package:element_x/core/di/di.dart';
import 'package:element_x/core/local_storage/session_store.dart';
import 'package:element_x/features/createroom/cubit/createroom_cubit.dart';
import 'package:element_x/features/createroom/view/createroom_screen.dart';
import 'package:element_x/features/joinroom/cubit/joinroom_cubit.dart';
import 'package:element_x/features/joinroom/view/joinroom_screen.dart';
import 'package:element_x/features/startchat/cubit/startchat_cubit.dart';
import 'package:element_x/features/startchat/view/startchat_screen.dart';
import 'package:element_x/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  tearDownAll(resetDependencies);

  testWidgets('new chat, create room, and join room are usable', (
    tester,
  ) async {
    final stage = ValueNotifier<Widget>(const SizedBox.shrink());
    addTearDown(stage.dispose);
    final startChat = sl<StartChatCubit>();
    final createRoom = sl<CreateRoomCubit>();
    final joinRoom = sl<JoinRoomCubit>();
    addTearDown(startChat.close);
    addTearDown(createRoom.close);
    addTearDown(joinRoom.close);

    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: AppTheme.light(useInter: false),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: ValueListenableBuilder<Widget>(
              valueListenable: stage,
              builder: (context, screen, _) => screen,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    stage.value = BlocProvider.value(
      value: startChat,
      child: const StartChatScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('New chat'), findsOneWidget);
    expect(find.text('Name or Matrix ID'), findsOneWidget);
    expect(find.text('New room'), findsOneWidget);
    expect(find.text('Join with an address'), findsOneWidget);
    expect(find.text('Public rooms'), findsOneWidget);
    expect(
      find.text('People you already chat with will show up here.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'ada');
    await tester.pump();
    expect(find.text('Message this ID'), findsOneWidget);
    expect(
      find.text('@ada:${AppConfig.defaultHomeserver}'),
      findsOneWidget,
    );
    expect(find.text('New room'), findsNothing);

    await tester.enterText(find.byType(TextField), '@ada:example.org');
    await tester.pump();
    expect(find.text('Message this ID'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '#ops:example.org');
    await tester.pump();
    expect(find.text('Join this address'), findsOneWidget);

    stage.value = BlocProvider.value(
      value: createRoom,
      child: const CreateRoomScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('New room'), findsOneWidget);
    expect(find.text('Anyone with the address can join'), findsOneWidget);
    FilledButton createButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Create room'),
    );
    expect(createButton().onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'Operations');
    await tester.pump();
    expect(createButton().onPressed, isNotNull);

    stage.value = BlocProvider.value(
      value: joinRoom,
      child: const JoinRoomScreen(initialAddress: '#ops:example.org'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Join a room'), findsOneWidget);
    expect(find.text('Resolve an alias'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Join'))
          .onPressed,
      isNotNull,
    );
  });
}
