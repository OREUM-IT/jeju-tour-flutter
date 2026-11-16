import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../core/api.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../ui/common.dart';
import '../ui/jeju_map.dart';

class RoutesPage extends StatefulWidget {
  const RoutesPage({super.key, required this.api, required this.store});
  final OreumApi api;
  final TripStore store;
  @override
  State<RoutesPage> createState() => _RoutesPageState();
}

class _RoutesPageState extends State<RoutesPage> {
  late Future<dynamic> presets = widget.api.get('/route/presets');
  List<LatLng> points = [];
  final List<List<LatLng>> past = [], future = [];
  String mode = 'foot', revision = 'draw';
  String? error;
  Json? result;
  bool busy = false, saving = false, track = false;
  final name = TextEditingController(text: '나만의 제주 길');
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  void edit(List<LatLng> next) => setState(() {
    past.add(List.of(points));
    future.clear();
    points = next;
    result = null;
    track = false;
  });
  Future<void> analyze() async {
    if (points.length < 2) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final response = object(
        await widget.api.post(track ? '/route/analyze' : '/route/plan', {
          track ? 'coords' : 'points': points
              .map((p) => [p.latitude, p.longitude])
              .toList(),
          'mode': track && mode == 'line' ? 'foot' : mode,
        }),
      );
      if (mounted) setState(() => result = response);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> loadPreset(String id) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final preset = object(
        await widget.api.get('/route/presets/${Uri.encodeComponent(id)}'),
      );
      if (!mounted) return;
      setState(() {
        points = coordinates(preset['coords']);
        past.clear();
        future.clear();
        name.text = string(preset['name']);
        mode = string(preset['mode'], 'foot');
        track = true;
        result = null;
        revision = id;
      });
      await analyze();
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = object(result?['stats']);
    return PageBody(
      children: [
        const PageHeading('코스 그리기', '지도에 지점을 찍고 거리·고도·경사를 확인하세요.'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormGrid(
                children: [
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: '경로 이름'),
                  ),
                  SelectField(
                    label: '이동 방식',
                    value: mode,
                    options: const {'foot': '도보', 'bike': '자전거', 'line': '직선'},
                    onChanged: (v) => setState(() {
                      mode = v;
                      result = null;
                    }),
                  ),
                  ApiView(
                    future: presets,
                    onRetry: () => setState(
                      () => presets = widget.api.get('/route/presets'),
                    ),
                    builder: (data) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: '기존 코스 불러오기',
                      ),
                      items: objects(data)
                          .map(
                            (p) => DropdownMenuItem(
                              value: string(p['id']),
                              child: Text(
                                string(p['name']),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: busy
                          ? null
                          : (v) {
                              if (v != null) loadPreset(v);
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: busy || past.isEmpty
                        ? null
                        : () => setState(() {
                            future.add(List.of(points));
                            points = past.removeLast();
                            result = null;
                            track = false;
                          }),
                    icon: const Icon(Icons.undo),
                    label: const Text('되돌리기'),
                  ),
                  OutlinedButton.icon(
                    onPressed: busy || future.isEmpty
                        ? null
                        : () => setState(() {
                            past.add(List.of(points));
                            points = future.removeLast();
                            result = null;
                            track = false;
                          }),
                    icon: const Icon(Icons.redo),
                    label: const Text('다시 실행'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () {
                            edit([]);
                            setState(
                              () => revision =
                                  'empty-${DateTime.now().microsecondsSinceEpoch}',
                            );
                          },
                    child: const Text('새로 그리기'),
                  ),
                  FilledButton.icon(
                    onPressed: busy || points.length < 2 ? null : analyze,
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(busy ? '분석 중…' : '경로 분석'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                track
                    ? '불러온 코스입니다. 새로 그리기를 누르면 지점을 직접 지정할 수 있어요.'
                    : '지도 클릭으로 지점 추가 · 현재 ${points.length}개',
              ),
              const SizedBox(height: 12),
              JejuMap(
                height: 420,
                revision: revision,
                pins: track
                    ? []
                    : [
                        for (var i = 0; i < points.length; i++)
                          MapPin(points[i], '${i + 1}'),
                      ],
                line: result != null ? coordinates(result!['line']) : points,
                onTap: busy || track
                    ? null
                    : (point) => edit([...points, point]),
              ),
              if (error != null) Notice(error!, error: true, onRetry: analyze),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                ),
              if (result != null) ...[
                const SizedBox(height: 24),
                Wrap(
                  spacing: 24,
                  runSpacing: 16,
                  children: [
                    Stat('거리', '${stats['distanceKm']} km'),
                    Stat('상승 고도', '${stats['gainM']} m'),
                    Stat('하강 고도', '${stats['lossM']} m'),
                    Stat('예상 소요', durationLabel(number(stats['estMin']))),
                    Stat('최대 오르막 경사', '${stats['maxGrade']}%'),
                  ],
                ),
                const SizedBox(height: 20),
                ElevationChart(profile: result!['profile'] as List? ?? []),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: saving
                          ? null
                          : () async {
                              setState(() => saving = true);
                              try {
                                await widget.store.save(
                                  name.text.trim().isEmpty
                                      ? '제주 경로'
                                      : name.text.trim(),
                                  'route',
                                  result!,
                                );
                                if (context.mounted) {
                                  toast(context, '내 일정에 경로를 저장했어요.');
                                }
                              } catch (e) {
                                if (context.mounted) toast(context, '$e');
                              } finally {
                                if (mounted) setState(() => saving = false);
                              }
                            },
                      icon: const Icon(Icons.bookmark_add_outlined),
                      label: const Text('경로 저장'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final line = coordinates(result!['line']);
                        final gpx =
                            '<?xml version="1.0" encoding="UTF-8"?><gpx version="1.1" creator="OREUM IT" xmlns="http://www.topografix.com/GPX/1/1"><trk><trkseg>${line.map((p) => '<trkpt lat="${p.latitude}" lon="${p.longitude}"/>').join()}</trkseg></trk></gpx>';
                        await Clipboard.setData(ClipboardData(text: gpx));
                        if (context.mounted) {
                          toast(context, 'GPX 내용을 복사했어요. .gpx 파일로 저장할 수 있습니다.');
                        }
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('GPX 복사'),
                    ),
                  ],
                ),
                if (objects(result!['cues']).isNotEmpty)
                  ExpansionTile(
                    title: const Text('구간별 길 안내'),
                    children: objects(result!['cues'])
                        .map(
                          (c) => ListTile(
                            leading: const Icon(Icons.turn_right),
                            title: Text(string(c['text'])),
                            subtitle: Text('${c['km']} km 지점'),
                          ),
                        )
                        .toList(),
                  ),
                const Notice('고도·예상 시간은 참고값입니다. 현장 탐방로와 통제 안내를 우선 확인하세요.'),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class ElevationChart extends StatelessWidget {
  const ElevationChart({super.key, required this.profile});
  final List<dynamic> profile;
  @override
  Widget build(BuildContext context) {
    final samples = profile
        .whereType<List>()
        .where((p) => p.length >= 4 && p[2] is num && p[3] is num)
        .toList();
    if (samples.length < 2) return const Notice('고도 정보가 없습니다.');
    final high = samples.map((p) => number(p[2])).reduce(math.max),
        low = samples.map((p) => number(p[2])).reduce(math.min);
    return Semantics(
      label: '고도 프로파일. 최저 ${low.round()}미터, 최고 ${high.round()}미터',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('고도 프로파일 · ${low.round()}–${high.round()}m'),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            width: double.infinity,
            child: CustomPaint(painter: _ElevationPainter(samples, high, low)),
          ),
        ],
      ),
    );
  }
}

class _ElevationPainter extends CustomPainter {
  _ElevationPainter(this.samples, this.high, this.low);
  final List<List<dynamic>> samples;
  final double high, low;
  @override
  void paint(Canvas canvas, Size size) {
    final total = math.max(number(samples.last[3]), 1),
        span = math.max(high - low, 10);
    final path = Path();
    for (var i = 0; i < samples.length; i++) {
      final x = number(samples[i][3]) / total * size.width,
          y =
              size.height -
              12 -
              ((number(samples[i][2]) - low) / span) * (size.height - 24);
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = moss.withValues(alpha: .12));
    canvas.drawPath(
      path,
      Paint()
        ..color = moss
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _ElevationPainter oldDelegate) =>
      oldDelegate.samples != samples;
}
