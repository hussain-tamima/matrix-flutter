import 'package:dio/dio.dart';

/// HTTP seam around Dio for OAuth rendezvous (MSC4108) and optional REST.
/// Matrix sync uses [MatrixStore] / the `matrix` SDK; this client carries
/// bearer auth from [SessionManager] when set after login.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> requestData<T>(
    String path,
    T Function(dynamic json) decode, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
    );
    return decode(response.data);
  }
}
