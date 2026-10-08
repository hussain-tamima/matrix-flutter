import 'package:dio/dio.dart';
import 'package:element_x/core/auth/session_manager.dart';

/// Attaches the stored access token. Fake repositories do not send requests.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._session);

  final SessionManager _session;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _session.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
