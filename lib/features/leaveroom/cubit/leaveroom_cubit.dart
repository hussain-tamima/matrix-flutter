import 'package:element_x/features/leaveroom/cubit/leaveroom_state.dart';
export 'package:element_x/features/leaveroom/cubit/leaveroom_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/leaveroom/repo/leaveroom_repo.dart';

class LeaveRoomCubit extends Cubit<LeaveRoomState> {
  LeaveRoomCubit(this._repo, this.roomId) : super(const LeaveRoomState());

  final LeaveRoomRepo _repo;
  final String roomId;

  void confirm() {
    _repo.leave(roomId);
    emit(const LeaveRoomState(left: true));
  }
}
