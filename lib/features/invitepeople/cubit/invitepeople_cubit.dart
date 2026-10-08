import 'package:element_x/features/invitepeople/cubit/invitepeople_state.dart';
export 'package:element_x/features/invitepeople/cubit/invitepeople_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/features/invitepeople/repo/invitepeople_repo.dart';

class InvitePeopleCubit extends Cubit<InvitePeopleState> {
  InvitePeopleCubit(this._repo, this._store, this.roomId)
    : super(const InvitePeopleState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final InvitePeopleRepo _repo;
  final MatrixStore _store;
  final String roomId;
  late final VoidCallback _listener;
  final List<String> _invited = [];

  void load() {
    emit(
      InvitePeopleState(
        people: _repo.candidates(roomId),
        invited: List.of(_invited),
      ),
    );
  }

  void invite(String userId) {
    _repo.invite(roomId, userId);
    _invited.add(userId);
    load();
  }

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
