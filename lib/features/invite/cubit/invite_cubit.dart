import 'package:element_x/features/invite/cubit/invite_state.dart';
export 'package:element_x/features/invite/cubit/invite_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/invite/repo/invite_repo.dart';

class InviteCubit extends Cubit<InviteState> {
  InviteCubit(InviteRepo repo, String roomId)
    : super(InviteState(room: repo.room(roomId)));
}
