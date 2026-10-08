import 'package:element_x/features/migration/cubit/migration_state.dart';
export 'package:element_x/features/migration/cubit/migration_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:element_x/features/migration/repo/migration_repo.dart';

class MigrationCubit extends Cubit<MigrationState> {
  MigrationCubit(MigrationRepo repo) : super(MigrationState(repo.summary()));
}
