import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api.dart';
import '../core/evidence.dart';
import '../core/location.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../ui/common.dart';
import '../ui/jeju_map.dart';

class ChallengePage extends StatefulWidget {
  const ChallengePage({super.key, required this.api, required this.store});
  final OreumApi api;
  final TripStore store;
  @override
  State<ChallengePage> createState() => _ChallengePageState();
}

class _ChallengePageState extends State<ChallengePage> {
  late Future<dynamic> meta = widget.api.get('/challenge/meta');
  late Future<dynamic> sessions = widget.api.get('/challenge/sessions');
  Future<dynamic>? hall;
  late final nickname = TextEditingController(
    text: widget.store.preferences.getString('oreum.flutter.nickname') ?? '',
  );
  final note = TextEditingController();
  String stage = 'p1947', courseId = 't-seongpanak', reason = '강풍';
  Position? position;
  Json? evidence, submitted;
  bool busy = false, agreed = false;
  String? error;
  @override
  void dispose() {
    nickname.dispose();
    note.dispose();
    super.dispose();
  }

  void reload() => setState(() {
    sessions = widget.api.get('/challenge/sessions');
    if (hall != null) hall = widget.api.get('/challenge/hall');
  });
  Future<void> locate() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final p = await currentPosition();
      if (mounted) setState(() => position = p);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pick(ImageSource source) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        requestFullMetadata: true,
      );
      if (file != null) {
        final value = await compute(prepareEvidence, await file.readAsBytes());
        if (mounted) setState(() => evidence = value);
      }
    } catch (e) {
      if (mounted) setState(() => error = '사진을 불러오지 못했어요. $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit({Json? active, bool weather = false}) async {
    if (nickname.text.trim().isEmpty ||
        position == null ||
        evidence == null ||
        !agreed) {
      setState(() => error = '닉네임, 현재 위치, 사진과 전송 동의를 확인해 주세요.');
      return;
    }
    if (DateTime.now().difference(position!.timestamp).abs() >
        const Duration(minutes: 2)) {
      setState(() => error = '위치를 다시 측정해 주세요. 인증에는 최근 2분 이내 위치를 사용합니다.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      submitted = null;
    });
    try {
      final pos = position!;
      final body = <String, dynamic>{
        'nickname': nickname.text.trim(),
        'courseId': courseId,
        'lat': pos.latitude,
        'lon': pos.longitude,
        'accuracy': pos.accuracy,
        'altitude': pos.altitude.isFinite ? pos.altitude : null,
        'gpsTime': pos.timestamp.millisecondsSinceEpoch,
        'photo': evidence!['photo'],
        'exif': evidence!['exif'],
        'demo': false,
      };
      final endpoint = weather
          ? '/challenge/sessions/${active!['id']}/weather'
          : active == null
          ? '/challenge/start'
          : '/challenge/sessions/${active['id']}/finish';
      if (weather) {
        body.addAll({
          'reason': reason,
          'note': note.text.trim(),
          'abort': true,
        });
      }
      final result = object(await widget.api.post(endpoint, body));
      if (!mounted) return;
      setState(() {
        submitted = result;
        evidence = null;
        position = null;
        agreed = false;
      });
      reload();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
          if (e is ApiException && e.data != null) submitted = object(e.data);
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const PageHeading('0 to 1947 챌린지', '바다에서 정상까지, 내 속도로 오르는 제주.'),
      ApiView(
        future: meta,
        onRetry: () => setState(() => meta = widget.api.get('/challenge/meta')),
        builder: (data) {
          final m = object(data),
              stages = objects(m['stages']),
              courses = objects(
                m['courses'],
              ).where((c) => c['stage'] == stage).toList();
          final course =
              courses.where((c) => c['id'] == courseId).firstOrNull ??
              (courses.isEmpty ? <String, dynamic>{} : courses.first);
          final actualId = string(course['id']);
          if (courseId != actualId) courseId = actualId;
          final start = coordinate(course['start']),
              end = coordinate(course['end']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: stages
                    .map(
                      (s) => ChoiceChip(
                        label: Text('${s['icon']} ${s['title']}'),
                        selected: stage == s['id'],
                        onSelected: busy
                            ? null
                            : (_) => setState(() {
                                stage = string(s['id']);
                                submitted = null;
                                agreed = false;
                              }),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FormGrid(
                      children: [
                        TextField(
                          controller: nickname,
                          maxLength: 30,
                          decoration: const InputDecoration(labelText: '내 닉네임'),
                          onChanged: (v) {
                            widget.store.preferences.setString(
                              'oreum.flutter.nickname',
                              v,
                            );
                            setState(() {});
                          },
                        ),
                        SelectField(
                          label: '도전 코스',
                          value: courseId,
                          options: {
                            for (final c in courses)
                              string(c['id']): string(c['name']),
                          },
                          onChanged: (v) => setState(() {
                            courseId = v;
                            submitted = null;
                            agreed = false;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      string(course['name']),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        Stat('거리', '${course['km'] ?? '—'} km'),
                        Stat('기준 시간', durationLabel(number(course['stdMin']))),
                        Stat(
                          '제한 시간',
                          durationLabel(number(course['limitMin'])),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (start != null || end != null)
                      JejuMap(
                        revision: courseId,
                        pins: [
                          if (start != null) MapPin(start, '출발'),
                          if (end != null) MapPin(end, '도착'),
                        ],
                      ),
                    const SizedBox(height: 20),
                    ApiView(
                      future: sessions,
                      onRetry: reload,
                      builder: (sessionData) {
                        final mine = objects(sessionData)
                            .where(
                              (s) =>
                                  nickname.text.trim().isNotEmpty &&
                                  s['nickname'] == nickname.text.trim(),
                            )
                            .toList();
                        final active = mine
                            .where(
                              (s) =>
                                  s['courseId'] == courseId &&
                                  s['status'] == 'active',
                            )
                            .firstOrNull;
                        final target = active == null ? start : end;
                        final distance = position != null && target != null
                            ? Geolocator.distanceBetween(
                                position!.latitude,
                                position!.longitude,
                                target.latitude,
                                target.longitude,
                              )
                            : null;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              active == null ? '출발점 인증' : '도착점 인증',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: busy ? null : locate,
                                  icon: const Icon(Icons.my_location),
                                  label: const Text('현재 위치 측정'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => pick(ImageSource.camera),
                                  icon: const Icon(Icons.photo_camera_outlined),
                                  label: const Text('사진 촬영'),
                                ),
                                TextButton.icon(
                                  onPressed: busy
                                      ? null
                                      : () => pick(ImageSource.gallery),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
                                  label: const Text('사진 선택'),
                                ),
                              ],
                            ),
                            if (position != null)
                              Notice(
                                '위치 정확도 ±${position!.accuracy.round()}m${distance == null ? '' : ' · 인증 지점까지 ${distance.round()}m'}\n위치와 사진은 서버에서 판정합니다.',
                              ),
                            if (evidence != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.memory(
                                  evidence!['preview'] as Uint8List,
                                  height: 210,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              if (evidence!['exif'] == null)
                                const Text(
                                  '사진에 촬영 시각·위치 메타데이터가 없습니다. 서버 검토 대상이 될 수 있어요.',
                                ),
                            ],
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: agreed,
                              onChanged: busy
                                  ? null
                                  : (v) => setState(() => agreed = v ?? false),
                              title: const Text('닉네임·위치·사진을 오름잇 인증 서버에 전송합니다.'),
                              subtitle: const Text(
                                '사진과 위치는 인증 버튼을 누를 때 전송됩니다.',
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: busy || courseId.isEmpty || !agreed
                                  ? null
                                  : () => submit(active: active),
                              icon: const Icon(Icons.verified_outlined),
                              label: Text(
                                busy
                                    ? '처리 중…'
                                    : active == null
                                    ? '출발 인증 전송'
                                    : '도착 인증 전송',
                              ),
                            ),
                            if (active != null)
                              ExpansionTile(
                                title: const Text('기상 악화로 안전 하산'),
                                children: [
                                  SelectField(
                                    label: '하산 사유',
                                    value: reason,
                                    options: {
                                      for (final r
                                          in (m['weatherReasons'] as List? ??
                                              []))
                                        '$r': '$r',
                                    },
                                    onChanged: (v) => reason = v,
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: note,
                                    decoration: const InputDecoration(
                                      labelText: '현장 상황',
                                    ),
                                    maxLines: 3,
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton(
                                    onPressed: busy || !agreed
                                        ? null
                                        : () => submit(
                                            active: active,
                                            weather: true,
                                          ),
                                    child: const Text('안전 하산 증빙 전송'),
                                  ),
                                ],
                              ),
                            if (error != null) Notice(error!, error: true),
                            if (submitted != null)
                              Notice(
                                '서버 판정: ${object(m['statusLabels'])[submitted!['status']] ?? submitted!['status'] ?? submitted!['message'] ?? '접수 결과를 진행 현황에서 확인해 주세요.'}',
                              ),
                            const SizedBox(height: 28),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '내 진행 현황',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                  ),
                                ),
                                IconButton(
                                  tooltip: '진행 현황 새로고침',
                                  onPressed: reload,
                                  icon: const Icon(Icons.refresh),
                                ),
                              ],
                            ),
                            if (mine.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Text('이 닉네임의 인증 기록이 없습니다.'),
                              ),
                            for (final s in mine)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(
                                  Icons.emoji_events_outlined,
                                  color: accent,
                                ),
                                title: Text(
                                  string(
                                    s['courseName'] ??
                                        objects(m['courses'])
                                            .where(
                                              (c) => c['id'] == s['courseId'],
                                            )
                                            .firstOrNull?['name'],
                                    string(s['courseId']),
                                  ),
                                ),
                                subtitle: Text(
                                  '${object(m['statusLabels'])[s['status']] ?? s['status']}${s['tier'] == null ? '' : ' · ${object(object(m['tiers'])[s['tier']])['label'] ?? s['tier']}'}',
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ExpansionTile(
                title: const Text('배지 기준'),
                children: object(m['tiers']).entries
                    .map(
                      (e) => ListTile(
                        title: Text(
                          '${object(e.value)['icon']} ${object(e.value)['label']}',
                        ),
                        subtitle: Text(
                          object(e.value)['f'] == null
                              ? '완주 인증'
                              : '기준 시간의 ${(number(object(e.value)['f']) * 100).round()}% 이내',
                        ),
                      ),
                    )
                    .toList(),
              ),
              ExpansionTile(
                title: const Text('명예의 전당'),
                onExpansionChanged: (open) {
                  if (open && hall == null) {
                    setState(() => hall = widget.api.get('/challenge/hall'));
                  }
                },
                children: [
                  if (hall != null)
                    ApiView(
                      future: hall!,
                      onRetry: reload,
                      builder: (data) {
                        final entries = data is List
                            ? objects(data)
                            : objects(
                                object(data)['entries'] ??
                                    object(data)['people'],
                              );
                        return entries.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('아직 표시할 완주 기록이 없습니다.'),
                              )
                            : Column(
                                children: entries
                                    .map(
                                      (e) => ListTile(
                                        leading: const Icon(Icons.emoji_events),
                                        title: Text(string(e['nickname'])),
                                        subtitle: Text(
                                          string(
                                            e['title'] ?? e['status'],
                                            '완주 기록',
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              );
                      },
                    ),
                ],
              ),
            ],
          );
        },
      ),
    ],
  );
}
