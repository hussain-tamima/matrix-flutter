import 'package:element_x/features/signedout/cubit/signedout_state.dart';
export 'package:element_x/features/signedout/cubit/signedout_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/signedout/repo/signedout_repo.dart';

class SignedOutCubit extends Cubit<SignedOutState> {
  SignedOutCubit(SignedOutRepo repo) : super(SignedOutState(repo.message()));
}
