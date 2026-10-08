import 'package:dio/dio.dart';
import 'package:element_x/core/auth/session_manager.dart';

/// Points [Dio] at the signed-in homeserver when known.
void configureDioHomeserver(Dio dio, SessionManager session) {
  final host = session.homeserver?.trim();
  if (host == null || host.isEmpty) {
    return;
  }
  if (host.startsWith('http://') || host.startsWith('https://')) {
    dio.options.baseUrl = host;
    return;
  }
  dio.options.baseUrl = 'https://$host';
}
