import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.data});
  final String message;
  final Object? data;
  @override
  String toString() => message;
}

/// The original service remains the backend. Web deployments proxy /api.
class OreumApi {
  OreumApi({
    http.Client? client,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 60),
  }) : _client = client ?? http.Client(),
       baseUri = baseUri ?? defaultBaseUri();
  final http.Client _client;
  final Uri baseUri;
  final Duration timeout;
  static Uri defaultBaseUri() {
    const configured = String.fromEnvironment('API_BASE_URL');
    final base = configured.isNotEmpty
        ? configured
        : kIsWeb
        ? '${Uri.base.origin}/api/'
        : 'https://jeju-tour-six.vercel.app/api/';
    return Uri.parse(base.endsWith('/') ? base : '$base/');
  }

  Future<dynamic> get(String path) => request('GET', path);
  Future<dynamic> post(String path, Json body) =>
      request('POST', path, body: body);
  Future<dynamic> request(String method, String path, {Json? body}) async {
    try {
      final uri = baseUri.resolve(path.replaceFirst(RegExp(r'^/+'), ''));
      final req = http.Request(method, uri);
      req.headers['Accept'] = 'application/json';
      if (body != null) {
        req.headers['Content-Type'] = 'application/json; charset=utf-8';
        req.body = jsonEncode(body);
      }
      final response = await _client
          .send(req)
          .then(http.Response.fromStream)
          .timeout(timeout);
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) throw ApiException('서버 응답 형식이 올바르지 않습니다.');
      final envelope = object(decoded);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          envelope['success'] != true) {
        throw ApiException(
          string(envelope['message'], '요청에 실패했습니다. (${response.statusCode})'),
          data: envelope['data'],
        );
      }
      return envelope['data'];
    } on TimeoutException {
      throw ApiException('응답이 늦어지고 있어요. 잠시 후 다시 시도해 주세요.');
    } on FormatException {
      throw ApiException('API 연결을 확인해 주세요. 서버에서 JSON 응답을 받지 못했습니다.');
    } on http.ClientException {
      throw ApiException('서버에 연결할 수 없습니다. 인터넷 연결을 확인해 주세요.');
    }
  }

  void close() => _client.close();
}
