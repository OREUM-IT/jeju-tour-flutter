import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:jeju_tour_flutter/core/api.dart';

void main() {
  test('Preserves /api prefix and UTF-8 Korean in a JSON POST', () async {
    final api = OreumApi(
      baseUri: Uri.parse('https://test.local/api/'),
      client: MockClient((request) async {
        expect(request.url.path, '/api/plan');
        expect(request.method, 'POST');
        expect(jsonDecode(request.body)['places'], ['성산일출봉']);
        return http.Response.bytes(
          utf8.encode('{"success":true,"data":{"title":"한라산"}}'),
          200,
        );
      }),
    );
    addTearDown(api.close);
    expect(
      (await api.post('/plan', {
        'places': ['성산일출봉'],
      }))['title'],
      '한라산',
    );
  });
  test('API rejection retains validation evidence', () async {
    final api = OreumApi(
      client: MockClient(
        (_) async => http.Response(
          '{"success":false,"message":"invalid","data":{"checks":[]}}',
          400,
        ),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.get('/challenge/start'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'invalid')
            .having((e) => e.data, 'data', {'checks': []}),
      ),
    );
  });
  test(
    'Rejects successful HTTP responses without a success envelope',
    () async {
      final api = OreumApi(
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      addTearDown(api.close);
      await expectLater(api.get('/meta'), throwsA(isA<ApiException>()));
    },
  );
  test('HTML proxy failures produce an actionable error', () async {
    final api = OreumApi(
      client: MockClient(
        (_) async => http.Response('<html>Not found</html>', 404),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.get('/meta'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('JSON'),
        ),
      ),
    );
  });
  test('Times out instead of leaving a loading state indefinitely', () async {
    final api = OreumApi(
      timeout: const Duration(milliseconds: 5),
      client: MockClient((_) => Completer<http.Response>().future),
    );
    addTearDown(api.close);
    await expectLater(
      api.get('/meta'),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('다시 시도'),
        ),
      ),
    );
  });
}
