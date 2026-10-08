import 'package:dio/dio.dart';

/// HTTP client for an MSC4108 rendezvous session URL.
class RendezvousClient {
  RendezvousClient(this._dio, this.sessionUrl);

  final Dio _dio;
  final Uri sessionUrl;
  String? _etag;

  Future<Map<String, Object?>> sendEncrypted(
    Map<String, Object?> encryptedEnvelope,
  ) async {
    final response = await _dio.postUri<Map<String, dynamic>>(
      sessionUrl,
      data: encryptedEnvelope,
      options: Options(
        headers: _conditionalHeaders(ifMatch: true),
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    _captureEtag(response);
    return Map<String, Object?>.from(response.data ?? {});
  }

  Future<Map<String, Object?>?> pollEncrypted({
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final response = await _dio.getUri<Map<String, dynamic>>(
        sessionUrl,
        options: Options(
          headers: _conditionalHeaders(ifMatch: false),
          validateStatus: (status) =>
              status != null && (status == 200 || status == 304),
        ),
      );
      _captureEtag(response);
      if (response.statusCode == 304) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        continue;
      }
      final data = response.data;
      if (data == null || data.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        continue;
      }
      return Map<String, Object?>.from(data);
    }
    return null;
  }

  Map<String, String> _conditionalHeaders({required bool ifMatch}) {
    final etag = _etag;
    if (etag == null) {
      return const {};
    }
    return ifMatch ? {'If-Match': etag} : {'If-None-Match': etag};
  }

  void _captureEtag(Response<dynamic> response) {
    final etag = response.headers.value('etag');
    if (etag != null && etag.isNotEmpty) {
      _etag = etag;
    }
  }
}
