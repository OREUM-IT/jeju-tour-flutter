import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jeju_tour_flutter/core/course_planner.dart';
import 'package:jeju_tour_flutter/core/evidence.dart';
import 'package:jeju_tour_flutter/core/models.dart';
import 'package:jeju_tour_flutter/core/store.dart';

void main() {
  test('Hike requests never accidentally submit challenge stages', () {
    final request = PlanRequest(startDate: DateTime(2026, 11, 17))
      ..stages = ['p1947'];
    expect(request.toJson()['stages'], isEmpty);
    request.challenge = true;
    expect(request.toJson()['stages'], ['p1947']);
    expect(request.toJson()['startDate'], '2026-11-17');
  });
  test('Coordinates reject invalid or missing values', () {
    expect(coordinate({'lat': 91, 'lon': 126}), isNull);
    expect(coordinate({'lat': null, 'lon': 126}), isNull);
    expect(coordinate({'lat': 33.5, 'lon': 126.5})?.latitude, 33.5);
  });
  test('Courses preserve selection order, dates, and opening time', () {
    final first = Place({
      'id': 'a',
      'name': 'A',
      'cat': 'cafe',
      'lat': 33.5,
      'lon': 126.5,
      'stay': 60,
      'open': 600,
      'close': 660,
    });
    final second = Place({
      'id': 'b',
      'name': 'B',
      'cat': 'food',
      'lat': 33.52,
      'lon': 126.55,
      'stay': 60,
      'open': 540,
      'close': 660,
    });
    final plan = buildCourse(
      startDate: DateTime(2026, 12, 31),
      days: [
        [first, second],
        [],
      ],
      transport: 'bus',
      title: 'Trip',
    );
    final days = objects(plan['days']);
    final steps = objects(days.first['steps']);
    expect(steps.map((s) => s['title']), ['A', 'B']);
    expect(steps.first['time'], '10:00');
    expect(number(object(steps[1]['travel'])['min']), greaterThan(15));
    expect(days[1]['date'], '2027-01-01');
    expect((plan['warnings'] as List).length, 2);
  });
  test(
    'Saved trips survive reload and can be restored after removal',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first = TripStore(prefs);
      final item = await first.save('제주', 'plan', {'days': []});
      final second = TripStore(prefs);
      expect(second.items.single.title, '제주');
      await second.remove(item.id);
      expect(TripStore(prefs).items, isEmpty);
      await second.restore(item);
      expect(TripStore(prefs).items.single.id, item.id);
    },
  );
  test('Corrupt saved JSON does not prevent application startup', () async {
    SharedPreferences.setMockInitialValues({TripStore.key: '{bad json'});
    final store = TripStore(await SharedPreferences.getInstance());
    expect(store.items, isEmpty);
  });
  test('Photo preparation does not invent missing EXIF data', () {
    final image = img.Image(width: 20, height: 10);
    final result = prepareEvidence(Uint8List.fromList(img.encodePng(image)));
    expect(result['photo'], startsWith('data:image/jpeg;base64,'));
    expect(result['exif'], isNull);
    expect(img.decodeImage(result['preview'] as Uint8List)?.width, 20);
  });
  test('Malformed evidence images are rejected', () {
    expect(
      () => prepareEvidence(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
