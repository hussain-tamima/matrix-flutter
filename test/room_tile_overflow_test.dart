import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/theme/app_theme.dart';
import 'package:element_x/widgets/room_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('room tile trailing column fits a short tile', (tester) async {
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    addTearDown(() => FlutterError.onError = previous);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(useInter: false),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: 40,
              child: RoomTile(
                room: MatrixRoom(
                  id: '!r:example',
                  name: 'Operations',
                  lastActivity: DateTime(2026, 10, 8, 16, 12),
                  lastMessage: 'hello',
                  unreadCount: 3,
                ),
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(errors, isEmpty);
    expect(find.text('3'), findsOneWidget);
  });
}
