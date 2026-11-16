import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jeju_tour_flutter/core/api.dart';
import 'package:jeju_tour_flutter/core/store.dart';
import 'package:jeju_tour_flutter/features/builder.dart';
import 'package:jeju_tour_flutter/ui/jeju_map.dart';

void main() {
  testWidgets('Builder shows a live map of the day while composing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final api = OreumApi(
      client: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'places': [
                {
                  'id': 'a',
                  'name': '성산일출봉',
                  'cat': 'heal',
                  'lat': 33.4581,
                  'lon': 126.9425,
                },
                {
                  'id': 'b',
                  'name': '섭지코지',
                  'cat': 'heal',
                  'lat': 33.4240,
                  'lon': 126.9310,
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    addTearDown(api.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BuilderPage(api: api, store: TripStore(prefs)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 담기 전에도 지도가 보이고, 후보 장소가 점으로 표시된다.
    expect(find.byType(JejuMap), findsOneWidget);
    await tester.ensureVisible(find.byType(JejuMap));
    await tester.pumpAndSettle();
    expect(find.byTooltip('성산일출봉'), findsOneWidget);

    await tester.ensureVisible(find.byTooltip('성산일출봉 담기'));
    await tester.tap(find.byTooltip('성산일출봉 담기'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('섭지코지 담기'));
    await tester.tap(find.byTooltip('섭지코지 담기'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(JejuMap));
    await tester.pumpAndSettle();
    expect(find.textContaining('1일차 동선 · 직선거리 약'), findsOneWidget);
    expect(find.byTooltip('1'), findsOneWidget);
    expect(find.byTooltip('2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
