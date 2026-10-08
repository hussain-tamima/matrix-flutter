import 'package:element_x/features/announcement/cubit/announcement_state.dart';
export 'package:element_x/features/announcement/cubit/announcement_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/announcement/repo/announcement_repo.dart';
import 'package:flutter/foundation.dart';

class AnnouncementCubit extends Cubit<AnnouncementState> {
  AnnouncementCubit(this._repo, this._store)
    : super(AnnouncementState(announcement: _repo.current())) {
    _listener = reload;
    _store.addListener(_listener);
  }

  final AnnouncementRepo _repo;
  final MatrixStore _store;
  late final VoidCallback _listener;

  void reload() => emit(AnnouncementState(announcement: _repo.current()));

  void dismiss() => _repo.dismiss();

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
