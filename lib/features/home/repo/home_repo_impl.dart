import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/core/matrix/room_preview.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/home/models/room_filter.dart';
import 'package:element_x/features/home/repo/home_repo.dart';

class HomeRepoImpl implements HomeRepo {
  HomeRepoImpl(this._store, this._session);

  final MatrixStore _store;
  final SessionManager _session;

  @override
  bool get online => _store.online;

  @override
  bool get syncing => _store.syncing;

  @override
  bool get ftueSeen => _session.ftueSeen;

  @override
  List<MatrixRoom> spaces() => _store.spaces;

  @override
  List<MatrixRoom> rooms({required RoomFilter filter, String query = ''}) {
    final needle = query.trim().toLowerCase();
    final rooms = _store.rooms.where((room) {
      final matchesQuery =
          needle.isEmpty ||
          room.name.toLowerCase().contains(needle) ||
          roomPreviewText(room.lastMessage).toLowerCase().contains(needle);
      final matchesFilter = switch (filter) {
        RoomFilter.all => true,
        RoomFilter.unreads => room.unreadCount > 0,
        RoomFilter.people => room.isDirect,
        RoomFilter.rooms => !room.isDirect,
        RoomFilter.favourites => room.isFavourite,
      };
      return matchesQuery && matchesFilter;
    }).toList();
    rooms.sort(compareHomeRooms);
    return rooms;
  }
}

/// Invites stay above joined rooms. Activity only orders rooms in the same group.
int compareHomeRooms(MatrixRoom a, MatrixRoom b) {
  if (a.isInvited != b.isInvited) {
    return a.isInvited ? -1 : 1;
  }
  return b.lastActivity.compareTo(a.lastActivity);
}
