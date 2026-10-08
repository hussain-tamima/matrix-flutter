import 'package:element_x/features/enterprise/cubit/enterprise_state.dart';
export 'package:element_x/features/enterprise/cubit/enterprise_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/enterprise/repo/enterprise_repo.dart';

class EnterpriseCubit extends Cubit<EnterpriseState> {
  EnterpriseCubit(EnterpriseRepo repo)
    : super(EnterpriseState(available: repo.available));
}
