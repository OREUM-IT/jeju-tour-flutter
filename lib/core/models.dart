import 'package:latlong2/latlong.dart';

typedef Json = Map<String, dynamic>;
Json object(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
List<Json> objects(Object? value) =>
    value is List ? value.whereType<Map>().map(object).toList() : [];
String string(Object? value, [String fallback = '']) =>
    value == null ? fallback : value.toString();
double number(Object? value, [double fallback = 0]) => value is num
    ? value.toDouble()
    : double.tryParse(string(value)) ?? fallback;
String dateLabel(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
String timeLabel(num minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes.toInt() % 60).toString().padLeft(2, '0')}';
String durationLabel(num minutes) =>
    '${minutes ~/ 60}시간 ${minutes.toInt() % 60}분';
LatLng? coordinate(Object? value) {
  final m = object(value);
  final lat = number(m['lat'], double.nan),
      lon = number(m['lon'] ?? m['lng'], double.nan);
  return lat.isFinite && lon.isFinite && lat.abs() <= 90 && lon.abs() <= 180
      ? LatLng(lat, lon)
      : null;
}

List<LatLng> coordinates(Object? value) => value is List
    ? value
          .whereType<List>()
          .where((p) => p.length >= 2)
          .map((p) => coordinate({'lat': p[0], 'lon': p[1]}))
          .whereType<LatLng>()
          .toList()
    : [];
const categories = {
  'all': '전체',
  'herit': '문화·명소',
  'heal': '자연·힐링',
  'activity': '체험',
  'sea': '바다',
  'food': '맛집',
  'cafe': '카페',
  'stay': '숙소',
  'hike': '올레·등산',
};

class Place {
  Place(this.raw);
  final Json raw;
  String get id => string(raw['id']);
  String get name => string(raw['name']);
  String get category => string(raw['cat']);
  String get categoryLabel => categories[category] ?? category;
  LatLng? get position => coordinate(raw);
  int get duration => number(raw['stay'], 60).toInt().clamp(10, 1440);
  String get hours => string(raw['hours'], '영업시간 확인 필요');
}

class PlanRequest {
  PlanRequest({DateTime? startDate})
    : startDate = startDate ?? DateTime.now().add(const Duration(days: 1));
  DateTime startDate;
  int nights = 3;
  bool challenge = false;
  String hub = 'airport',
      transport = 'rent',
      pace = 'normal',
      trail = 'fastest';
  String arrivalTime = '10:00', departTime = '18:30';
  bool autoSwap = true;
  List<String> stages = [], foods = [], places = [];
  Json toJson() => {
    'nights': nights,
    'startDate': dateLabel(startDate),
    'hub': hub,
    'transport': transport,
    'pace': pace,
    'trailPref': trail,
    'arrivalTime': arrivalTime,
    'departTime': departTime,
    'autoSwap': autoSwap,
    'weatherMode': 'auto',
    'hoursMode': 'prefer',
    'stages': challenge ? stages : <String>[],
    'foods': foods,
    'places': places,
    'guests': 2,
    'stays': <String>[],
  };
}

class SavedItem {
  SavedItem({
    required this.id,
    required this.title,
    required this.kind,
    required this.data,
    required this.savedAt,
  });
  final String id, title, kind;
  final Json data;
  final DateTime savedAt;
  factory SavedItem.fromJson(Json json) => SavedItem(
    id: string(json['id']),
    title: string(json['title']),
    kind: string(json['kind']),
    data: object(json['data']),
    savedAt: DateTime.parse(string(json['savedAt'])),
  );
  Json toJson() => {
    'id': id,
    'title': title,
    'kind': kind,
    'data': data,
    'savedAt': savedAt.toIso8601String(),
  };
}
