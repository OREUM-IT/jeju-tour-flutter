import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'models.dart';

/// Explicit estimates: these are never presented as real-time road/bus data.
Json buildCourse({
  required DateTime startDate,
  required List<List<Place>> days,
  required String transport,
  required String title,
}) {
  final output = <Json>[];
  final warnings = <String>[];
  double totalKm = 0;
  const distance = Distance();
  for (var day = 0; day < days.length; day++) {
    var clock = 9 * 60;
    var dayKm = 0.0;
    LatLng? previous;
    final steps = <Json>[];
    for (final place in days[day]) {
      final point = place.position;
      final directKm = previous != null && point != null
          ? distance.as(LengthUnit.Kilometer, previous, point)
          : 0.0;
      final km = directKm * (transport == 'foot' ? 1.2 : 1.35);
      final speed = transport == 'foot'
          ? 4.5
          : transport == 'bus'
          ? 20.0
          : 35.0;
      final travel = directKm == 0
          ? 0
          : (km / speed * 60).ceil() + (transport == 'bus' ? 15 : 5);
      clock += travel;
      if (place.raw['open'] is num &&
          place.raw['close'] is num &&
          number(place.raw['close']) > number(place.raw['open'])) {
        clock = math.max(clock, number(place.raw['open']).toInt());
        if (clock + place.duration > number(place.raw['close'])) {
          warnings.add(
            '${day + 1}일차 ${place.name}: 예상 방문 시간이 안내된 영업시간을 벗어납니다.',
          );
        }
      }
      steps.add({
        'title': place.name,
        'type': place.category,
        'time': timeLabel(clock),
        'end': timeLabel(clock + place.duration),
        'dur': place.duration,
        'desc': '${place.categoryLabel} · ${place.hours}',
        'place': {
          ...place.raw,
          'hours': {'today': place.hours},
        },
        'travel': {
          'km': double.parse(km.toStringAsFixed(1)),
          'min': travel,
          'estimated': true,
        },
      });
      clock += place.duration;
      dayKm += km;
      if (point != null) previous = point;
    }
    if (clock > 20 * 60) {
      warnings.add('${day + 1}일차 일정이 20시를 넘어요. 방문지를 줄이거나 다른 날로 나누어 주세요.');
    }
    totalKm += dayKm;
    output.add({
      'day': day + 1,
      'date': dateLabel(startDate.add(Duration(days: day))),
      'title': '${day + 1}일차 · 직접 고른 ${steps.length}곳',
      'steps': steps,
      'km': double.parse(dayKm.toStringAsFixed(1)),
      'route': days[day]
          .where((p) => p.position != null)
          .map((p) => [p.position!.latitude, p.position!.longitude])
          .toList(),
    });
  }
  return {
    'planId': 'course-${DateTime.now().microsecondsSinceEpoch}',
    'product': {'label': '${days.length}일 자유 코스'},
    'summary': {'title': title, 'totalDriveKm': totalKm.round()},
    'days': output,
    'warnings': [
      '이동 시간·거리는 좌표 기반 추정치입니다. 실제 도로·대중교통 시간표와 다를 수 있어요.',
      ...warnings,
    ],
    'courseDraft': {
      'startDate': dateLabel(startDate),
      'transport': transport,
      'days': days.map((d) => d.map((p) => p.raw).toList()).toList(),
    },
  };
}
