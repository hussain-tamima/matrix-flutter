import 'package:element_x/features/share/cubit/share_state.dart';
export 'package:element_x/features/share/cubit/share_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/share/repo/share_repo.dart';

class ShareCubit extends Cubit<ShareState> {
  ShareCubit(this._repo, {required String text})
    : super(ShareState(text: text, rooms: _repo.rooms()));

  final ShareRepo _repo;

  void updateText(String text) =>
      emit(ShareState(text: text, rooms: state.rooms));

  void send(String roomId) {
    final text = state.text.trim();
    if (text.isEmpty) {
      return;
    }
    _repo.share(roomId, text);
    emit(ShareState(text: state.text, rooms: state.rooms, sent: true));
  }
}
