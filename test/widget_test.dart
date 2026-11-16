import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jeju_tour_flutter/app.dart';
import 'package:jeju_tour_flutter/core/api.dart';
import 'package:jeju_tour_flutter/core/store.dart';

void main() {
  for (final width in [360.0, 1280.0]) {
    testWidgets('Planner loads without overflow at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
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
                'hubs': [
                  {'id': 'airport', 'name': '제주국제공항'},
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(api.close);
      await tester.pumpWidget(OreumApp(api: api, store: TripStore(prefs)));
      await tester.pumpAndSettle();
      expect(find.text('오름잇'), findsOneWidget);
      expect(find.text('일정 조회'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('이용안내'));
      await tester.pumpAndSettle();
      expect(find.text('오름잇 이용 안내'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
