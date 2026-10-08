import 'package:element_x/features/messages/cubit/pins_state.dart';
export 'package:element_x/features/messages/cubit/pins_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/messages/repo/messages_repo.dart';
import 'package:flutter/foundation.dart';
import 'package:element_x/core/matrix/matrix_models.dart';

class PinsCubit extends Cubit<PinsState> {
  PinsCubit(this._repo, this._store, this.roomId) : super(const PinsState()) {
    _listener = load;
    _store.addListener(_listener);
    load();
  }

  final MessagesRepo _repo;
  final MatrixStore _store;
  final String roomId;
  late final VoidCallback _listener;

  void load() => emit(PinsState(events: _repo.pins(roomId)));

  void unpin(TimelineEvent event) => _repo.pin(event.id, pinned: false);

  String nameFor(String senderId) => _repo.senderName(senderId);

  @override
  Future<void> close() {
    _store.removeListener(_listener);
    return super.close();
  }
}
