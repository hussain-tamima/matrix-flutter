import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/forward/cubit/forward_cubit.dart';
import 'package:element_x/features/forward/repo/forward_repo.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeForwardRepo implements ForwardRepo {
  @override
  TimelineEvent? event(String eventId) => null;

  @override
  List<MatrixRoom> destinations(String fromRoomId) => const [];

  @override
  Future<void> send(String roomId, String sourceEventId) async {}
}

void main() {
  test('ForwardCubit send is a no-op when event is missing', () async {
    final cubit = ForwardCubit(_FakeForwardRepo(), 'room-a', 'missing');
    await cubit.send('room-b');
    expect(cubit.state.sentTo, isNull);
    await cubit.close();
  });
}
