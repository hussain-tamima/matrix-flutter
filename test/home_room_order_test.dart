import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/home/repo/home_repo_impl.dart';
import 'package:flutter_test/flutter_test.dart';

MatrixRoom _room(
  String id, {
  required DateTime lastActivity,
  bool invited = false,
}) {
  return MatrixRoom(
    id: id,
    name: id,
    lastActivity: lastActivity,
    isInvited: invited,
  );
}

void main() {
  test('invites sort above newer joined rooms', () {
    final older = DateTime.utc(2020);
    final newer = DateTime.utc(2026);
    final rooms = [
      _room('joined-new', lastActivity: newer),
      _room('invite-old', lastActivity: older, invited: true),
      _room('joined-old', lastActivity: older),
    ];

    rooms.sort(compareHomeRooms);

    expect(rooms.map((room) => room.id), [
      'invite-old',
      'joined-new',
      'joined-old',
    ]);
  });
}
