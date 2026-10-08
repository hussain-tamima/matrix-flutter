import 'package:element_x/core/auth/session_manager.dart';
import 'package:element_x/core/routes/route_paths.dart';
import 'package:element_x/features/splash/repo/splash_repo.dart';

class SplashRepoImpl implements SplashRepo {
  SplashRepoImpl(this._session);

  final SessionManager _session;

  @override
  String nextRoute() {
    if (!_session.isLoggedIn) {
      return RoutePaths.login;
    }
    if (_session.lockEnabled && !_session.unlocked) {
      return RoutePaths.lock;
    }
    return RoutePaths.home;
  }
}
