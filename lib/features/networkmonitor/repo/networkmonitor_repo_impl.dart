import 'package:element_x/core/matrix/matrix_store.dart';
import 'package:element_x/features/networkmonitor/repo/networkmonitor_repo.dart';

class NetworkMonitorRepoImpl implements NetworkMonitorRepo {
  NetworkMonitorRepoImpl(this._store);

  final MatrixStore _store;

  @override
  bool get online => _store.online;

  @override
  void setOnline({required bool online}) => _store.setOnline(online: online);
}
