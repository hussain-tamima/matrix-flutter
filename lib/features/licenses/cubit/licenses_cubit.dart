import 'package:element_x/features/licenses/cubit/licenses_state.dart';
export 'package:element_x/features/licenses/cubit/licenses_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/licenses/repo/licenses_repo.dart';

class LicensesCubit extends Cubit<LicensesState> {
  LicensesCubit(LicensesRepo repo) : super(LicensesState(repo.packages()));
}
