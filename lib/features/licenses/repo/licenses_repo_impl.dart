import 'package:element_x/features/licenses/repo/licenses_repo.dart';

class LicensesRepoImpl implements LicensesRepo {
  @override
  List<String> packages() {
    return const [
      'Flutter — BSD-3-Clause',
      'flutter_bloc — MIT',
      'go_router — BSD-3-Clause',
      'dio — MIT',
      'get_it — MIT',
      'hive_ce — Apache-2.0',
      'matrix-rust-sdk — Apache-2.0',
    ];
  }
}
