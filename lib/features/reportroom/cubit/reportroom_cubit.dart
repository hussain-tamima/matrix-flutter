import 'package:element_x/features/reportroom/cubit/reportroom_state.dart';
export 'package:element_x/features/reportroom/cubit/reportroom_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/reportroom/repo/reportroom_repo.dart';

class ReportRoomCubit extends Cubit<ReportRoomState> {
  ReportRoomCubit(this._repo, this.roomId) : super(const ReportRoomState());

  final ReportRoomRepo _repo;
  final String roomId;

  void submit(String reason) {
    if (reason.trim().isEmpty) {
      emit(const ReportRoomState(error: 'Describe what happened'));
      return;
    }
    _repo.report(roomId, reason.trim());
    emit(const ReportRoomState(submitted: true));
  }
}
