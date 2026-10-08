import 'package:element_x/features/roomaliasresolver/models/alias_resolution.dart';
import 'package:element_x/features/roomaliasresolver/cubit/roomaliasresolver_state.dart';
export 'package:element_x/features/roomaliasresolver/cubit/roomaliasresolver_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/roomaliasresolver/repo/roomaliasresolver_repo.dart';

class RoomAliasResolverCubit extends Cubit<RoomAliasResolverState> {
  RoomAliasResolverCubit(this._repo) : super(const RoomAliasResolverState());

  final RoomAliasResolverRepo _repo;

  Future<void> resolve(String alias) async {
    if (state.submitting) return;
    final value = alias.trim();
    if (value.isEmpty) {
      emit(
        const RoomAliasResolverState(
          resolution: AliasResolution(error: 'resolve_alias_missing'),
        ),
      );
      return;
    }
    emit(const RoomAliasResolverState(submitting: true));
    final resolution = await _repo.resolve(value);
    if (!isClosed) {
      emit(RoomAliasResolverState(resolution: resolution));
    }
  }

  void reset() {
    if (state.resolution != null && !state.submitting) {
      emit(const RoomAliasResolverState());
    }
  }
}
