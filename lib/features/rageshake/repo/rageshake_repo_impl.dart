import 'package:element_x/features/rageshake/repo/rageshake_repo.dart';

class RageshakeRepoImpl implements RageshakeRepo {
  String? lastReport;

  @override
  Future<void> submit(String description) async {
    lastReport = description;
  }
}
