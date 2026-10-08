import 'package:element_x/features/knockrequests/cubit/knockrequests_state.dart';
export 'package:element_x/features/knockrequests/cubit/knockrequests_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/core/matrix/matrix_models.dart';
import 'package:element_x/features/knockrequests/repo/knockrequests_repo.dart';

class KnockRequestsCubit extends Cubit<KnockRequestsState> {
  KnockRequestsCubit(this._repo, this._store, this.roomId)
    : super(const KnockRequestsState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final KnockRequestsRepo _repo;
  final MatrixStore _store;
  final String roomId;
  late final VoidCallback _listener;

  void load() => emit(KnockRequestsState(requests: _repo.requests(roomId)));

  void accept(KnockRequest request) => _repo.accept(request);

  void decline(KnockRequest request) => _repo.decline(request);

  String nameFor(String userId) => _repo.nameFor(userId);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
