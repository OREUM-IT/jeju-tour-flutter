import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../core/api.dart';
import '../core/location.dart';
import '../core/models.dart';
import '../ui/common.dart';
import '../ui/jeju_map.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key, required this.api});
  final OreumApi api;
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  late Future<List<dynamic>> overview = loadOverview();
  late Future<dynamic> forecast = widget.api.get('/weather');
  Future<List<dynamic>> loadOverview() => Future.wait([
    widget.api.get('/kma/status'),
    widget.api.get('/kma/aws'),
    widget.api.get('/kma/warnings'),
  ]);
  LatLng point = const LatLng(33.3617, 126.5292);
  late Future<dynamic> observation = loadPoint(point);
  Future<dynamic> loadPoint(LatLng p) => widget.api.get(
    '/kma/now?lat=${p.latitude.toStringAsFixed(5)}&lon=${p.longitude.toStringAsFixed(5)}',
  );
  String? locationError;
  bool locating = false;
  void choose(LatLng p) => setState(() {
    point = p;
    observation = loadPoint(p);
  });
  void refresh() => setState(() {
    overview = loadOverview();
    observation = loadPoint(point);
    forecast = widget.api.get('/weather');
  });
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      PageHeading(
        '실시간 기상',
        '기상청 관측값과 한라산 예보를 함께 확인하세요.',
        trailing: OutlinedButton.icon(
          onPressed: refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('새로고침'),
        ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton.tonalIcon(
            onPressed: locating
                ? null
                : () async {
                    setState(() {
                      locating = true;
                      locationError = null;
                    });
                    try {
                      final p = await currentPosition();
                      if (mounted) choose(LatLng(p.latitude, p.longitude));
                    } catch (e) {
                      if (mounted) setState(() => locationError = '$e');
                    } finally {
                      if (mounted) setState(() => locating = false);
                    }
                  },
            icon: const Icon(Icons.my_location),
            label: Text(locating ? '위치 확인 중…' : '현재 위치'),
          ),
          OutlinedButton(
            onPressed: () => choose(const LatLng(33.3617, 126.5292)),
            child: const Text('백록담'),
          ),
          OutlinedButton(
            onPressed: () => choose(const LatLng(33.507, 126.493)),
            child: const Text('제주공항'),
          ),
          OutlinedButton(
            onPressed: () => choose(const LatLng(33.248, 126.56)),
            child: const Text('서귀포'),
          ),
        ],
      ),
      if (locationError != null) Notice(locationError!, error: true),
      const SizedBox(height: 16),
      JejuMap(
        center: point,
        pins: [MapPin(point, '●')],
        onTap: choose,
        revision: '${point.latitude}:${point.longitude}',
      ),
      const SizedBox(height: 8),
      Text(
        '지도에서 지점을 누르면 해당 격자의 기상을 조회합니다.\n선택 지점 ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
      ),
      const SizedBox(height: 20),
      ApiView(
        future: observation,
        onRetry: () => choose(point),
        builder: (data) {
          final d = object(data),
              now = object(d['ncst']),
              derived = object(d['derived']);
          return Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '현재 관측 · ${_stamp(string(now['base']))}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                if (now.isEmpty)
                  const Notice('관측값을 받지 못했습니다.')
                else
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    children: [
                      Stat('기온', '${now['t1h'] ?? '—'} °C'),
                      Stat('바람', '${now['wsd'] ?? '—'} m/s'),
                      Stat('습도', '${now['reh'] ?? '—'}%'),
                      Stat('1시간 강수', '${now['rn1'] ?? '—'} mm'),
                    ],
                  ),
                if (derived['fogPossible'] == true ||
                    derived['inCloud'] == true)
                  const Notice('안개·운무 가능성이 있습니다. 현장 시야를 확인해 주세요.'),
                for (final error in d['errors'] as List? ?? [])
                  Notice(string(error), error: true),
                const SizedBox(height: 20),
                Text('초단기 예보', style: Theme.of(context).textTheme.titleMedium),
                for (final hour in objects(object(d['fcst'])['hours']))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.cloud_outlined),
                    title: Text(_stamp(string(hour['time']))),
                    subtitle: Text(
                      '${hour['t1h'] ?? '—'} °C · 바람 ${hour['wsd'] ?? '—'} m/s · 강수 ${hour['rn1'] ?? '—'}',
                    ),
                  ),
                Text(
                  '조회 시각 ${_isoTime(string(d['fetchedAt']))} · 기상청',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 20),
      ApiView<List<dynamic>>(
        future: overview,
        onRetry: refresh,
        builder: (data) {
          final status = object(data[0]),
              aws = object(data[1]),
              warnings = object(data[2]);
          if (status['configured'] != true) {
            return const Notice('기상청 API가 설정되지 않았습니다. 아래 예보를 참고해 주세요.');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (warnings['status'] != 'ok')
                Notice(string(warnings['message'], '특보 조회 상태를 확인해 주세요.')),
              for (final warning in objects(warnings['jeju']))
                Notice(
                  '${warning['region']} · ${warning['warning']} ${warning['level']}',
                ),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '제주 관측소 · ${_stamp(string(aws['tm']))}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (aws['error'] != null)
                      Notice(string(aws['error']), error: true),
                    ...objects(aws['stations']).map((station) {
                      final obs = object(station['obs']);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${station['name']} · ${station['elev']}m'),
                        subtitle: Text(
                          '기온 ${obs['ta'] ?? '—'} °C · 바람 ${obs['ws10'] ?? '—'} m/s · 강수 ${obs['rn60'] ?? '—'} mm',
                        ),
                        trailing: const Icon(Icons.location_on_outlined),
                        onTap: coordinate(station) == null
                            ? null
                            : () => choose(coordinate(station)!),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 20),
      ApiView(
        future: forecast,
        onRetry: refresh,
        builder: (data) => Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('한라산 정상 예보', style: Theme.of(context).textTheme.titleLarge),
              const Text('Open-Meteo 모델 예보 · 실측 관측값과 다를 수 있어요.'),
              const SizedBox(height: 12),
              ...object(object(data)['summit']).entries.take(7).map((entry) {
                final w = object(entry.value);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    number(w['snow']) > 0
                        ? Icons.ac_unit
                        : number(w['rain']) > 0
                        ? Icons.umbrella_outlined
                        : Icons.cloud_outlined,
                  ),
                  title: Text(entry.key),
                  subtitle: Text(
                    '${w['tmin']} ~ ${w['tmax']} °C · 강수 ${w['rain']}mm\n바람 ${w['wind']} m/s · 돌풍 ${w['gust']} m/s',
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      TextButton(
        onPressed: () =>
            openLink(context, 'https://www.jeju.go.kr/hallasan/index.htm'),
        child: const Text('한라산국립공원 탐방 통제 확인'),
      ),
    ],
  );
  String _stamp(String value) => value.length >= 12
      ? '${value.substring(4, 6)}/${value.substring(6, 8)} ${value.substring(8, 10)}:${value.substring(10, 12)} (한국)'
      : value;
  String _isoTime(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? value
        : '${dateLabel(parsed.toUtc().add(const Duration(hours: 9)))} ${timeLabel(parsed.toUtc().add(const Duration(hours: 9)).hour * 60 + parsed.minute)} (한국)';
  }
}
