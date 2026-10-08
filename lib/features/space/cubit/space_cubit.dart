import 'package:element_x/features/space/cubit/space_state.dart';
export 'package:element_x/features/space/cubit/space_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/space/repo/space_repo.dart';

class SpaceCubit extends Cubit<SpaceState> {
  SpaceCubit(this._repo, this.spaceId) : super(const SpaceState()) {
    load();
  }

  final SpaceRepo _repo;
  final String spaceId;

  void load() {
    emit(
      SpaceState(
        summary: _repo.summary(spaceId),
        rooms: _repo.children(spaceId),
      ),
    );
  }
}
