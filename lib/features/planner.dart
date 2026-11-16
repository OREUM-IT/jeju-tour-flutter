import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../ui/common.dart';
import '../ui/jeju_map.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key, required this.api, required this.store});
  final OreumApi api;
  final TripStore store;
  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final form = PlanRequest();
  late Future<dynamic> meta = widget.api.get('/meta');
  bool busy = false;
  String? error;
  Json? plan;
  Future<void> generate() async {
    if (form.challenge && form.stages.isEmpty) {
      setState(() => error = '도전할 챌린지 단계를 하나 이상 골라 주세요.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = object(await widget.api.post('/plan', form.toJson()));
      if (objects(result['days']).isEmpty) {
        throw ApiException('일정이 비어 있어요. 조건을 바꾸어 다시 조회해 주세요.');
      }
      if (mounted) setState(() => plan = result);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      if (plan == null) ...[
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/hallasan-green.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: .63),
                        Colors.black.withValues(alpha: .08),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 56,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '오름잇  ·  OREUM IT',
                      style: TextStyle(
                        color: Colors.white,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '한라산도 올레도,\n하루 일정으로 짜드려요',
                      style: TextStyle(
                        fontSize: MediaQuery.sizeOf(context).width > 700
                            ? 42
                            : 29,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '바다 0m에서 백록담 1,947m까지.\n날씨와 이동 시간을 보고 나만의 제주를 계획하세요.',
                      style: TextStyle(color: Colors.white, height: 1.7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ] else
        PageHeading(
          '나의 제주 여행',
          string(object(plan!['summary'])['title']),
          trailing: TextButton.icon(
            onPressed: () => setState(() => plan = null),
            icon: const Icon(Icons.tune),
            label: const Text('조건 수정'),
          ),
        ),
      if (plan == null)
        Panel(
          child: ApiView(
            future: meta,
            onRetry: () => setState(() => meta = widget.api.get('/meta')),
            builder: (data) {
              final hubs = {
                for (final h in objects(object(data)['hubs']))
                  string(h['id']): string(h['name']),
              };
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '어떤 제주를 만나고 싶나요?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  FormGrid(
                    children: [
                      SelectField(
                        label: '참여 방식',
                        value: form.challenge ? 'challenge' : 'hike',
                        options: const {
                          'hike': '한라산 등반 일정만',
                          'challenge': '0 to 1947 챌린지',
                        },
                        onChanged: (v) =>
                            setState(() => form.challenge = v == 'challenge'),
                      ),
                      SelectField(
                        label: '기간',
                        value: '${form.nights}',
                        options: {
                          for (var n = 1; n <= 4; n++) '$n': '$n박 ${n + 1}일',
                        },
                        onChanged: (v) =>
                            setState(() => form.nights = int.parse(v)),
                      ),
                      DateField(
                        value: form.startDate,
                        onChanged: (v) => setState(() => form.startDate = v),
                      ),
                    ],
                  ),
                  if (form.challenge)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            const {
                                  'zero': '올레길 · 0m',
                                  'p600': '둘레길 · 600m',
                                  'p1100': '어승생악 · 1,100m',
                                  'p1700': '윗세오름 · 1,700m',
                                  'p1947': '백록담 · 1,947m',
                                }.entries
                                .map(
                                  (e) => FilterChip(
                                    label: Text(e.value),
                                    selected: form.stages.contains(e.key),
                                    onSelected: (v) => setState(() {
                                      v
                                          ? form.stages.add(e.key)
                                          : form.stages.remove(e.key);
                                    }),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('상세 조건'),
                    childrenPadding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      FormGrid(
                        children: [
                          SelectField(
                            label: '출발지',
                            value: form.hub,
                            options: hubs,
                            onChanged: (v) => form.hub = v,
                          ),
                          SelectField(
                            label: '교통수단',
                            value: form.transport,
                            options: const {'rent': '렌터카', 'bus': '버스'},
                            onChanged: (v) => form.transport = v,
                          ),
                          SelectField(
                            label: '등산로',
                            value: form.trail,
                            options: const {
                              'fastest': '자동 추천',
                              'seongpanak': '성판악',
                              'gwaneumsa': '관음사',
                              'eorimok': '어리목',
                              'yeongsil': '영실',
                              'donnaeko': '돈내코',
                              'eoseungsaeng': '어승생악',
                            },
                            onChanged: (v) => form.trail = v,
                          ),
                          SelectField(
                            label: '걷는 속도',
                            value: form.pace,
                            options: const {
                              'easy': '천천히',
                              'normal': '보통',
                              'fast': '빠르게',
                            },
                            onChanged: (v) => form.pace = v,
                          ),
                          _timeField(
                            '도착 시각',
                            form.arrivalTime,
                            (v) => form.arrivalTime = v,
                          ),
                          _timeField(
                            '귀가 시각',
                            form.departTime,
                            (v) => form.departTime = v,
                          ),
                          TextFormField(
                            initialValue: form.places.join(', '),
                            decoration: const InputDecoration(
                              labelText: '가고 싶은 곳',
                              hintText: '성산일출봉, 오설록',
                            ),
                            onChanged: (v) => form.places = _split(v),
                          ),
                          TextFormField(
                            initialValue: form.foods.join(', '),
                            decoration: const InputDecoration(
                              labelText: '먹고 싶은 것',
                              hintText: '흑돼지, 고기국수',
                            ),
                            onChanged: (v) => form.foods = _split(v),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('날씨가 나쁘면 등반일 바꾸기'),
                        value: form.autoSwap,
                        onChanged: (v) => setState(() => form.autoSwap = v),
                      ),
                    ],
                  ),
                  if (error != null) Notice(error!, error: true),
                  FilledButton.icon(
                    onPressed: busy ? null : generate,
                    icon: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(busy ? '날씨와 동선을 확인하고 있어요…' : '일정 조회'),
                  ),
                ],
              );
            },
          ),
        ),
      if (plan != null)
        PlanDetail(
          key: ValueKey(plan!['planId']),
          plan: plan!,
          store: widget.store,
        ),
      if (plan == null) ...[
        const SizedBox(height: 28),
        FormGrid(
          children: const [
            Panel(
              child: _Benefit(
                Icons.cloud_outlined,
                '날씨 보고 등반일을',
                '비와 바람을 살펴 백록담 가는 날을 정해요.',
              ),
            ),
            Panel(
              child: _Benefit(
                Icons.landscape_outlined,
                '백록담은 하루 통째로',
                '오르고 내려오는 시간을 충분히 확보해요.',
              ),
            ),
            Panel(
              child: _Benefit(
                Icons.route_outlined,
                '맛집·숙소·이동까지',
                '코스 근처 장소와 시간표를 한 화면에서 봐요.',
              ),
            ),
          ],
        ),
      ],
    ],
  );
  List<String> _split(String text) =>
      text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  Widget _timeField(String label, String value, ValueChanged<String> change) =>
      OutlinedButton.icon(
        icon: const Icon(Icons.schedule, size: 18),
        label: Text('$label  $value'),
        onPressed: () async {
          final parts = value.split(':');
          final time = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(
              hour: int.parse(parts[0]),
              minute: int.parse(parts[1]),
            ),
          );
          if (time != null) {
            setState(() => change(timeLabel(time.hour * 60 + time.minute)));
          }
        },
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit(this.icon, this.title, this.description);
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: moss),
      const SizedBox(height: 16),
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      Text(description),
    ],
  );
}

class PlanDetail extends StatefulWidget {
  const PlanDetail({
    super.key,
    required this.plan,
    required this.store,
    this.allowSave = true,
  });
  final Json plan;
  final TripStore store;
  final bool allowSave;
  @override
  State<PlanDetail> createState() => _PlanDetailState();
}

class _PlanDetailState extends State<PlanDetail> {
  int dayIndex = 0;
  bool saving = false;
  @override
  Widget build(BuildContext context) {
    final days = objects(widget.plan['days']);
    if (days.isEmpty) return const Notice('저장된 일정이 비어 있습니다.');
    final day = days[dayIndex.clamp(0, days.length - 1)],
        summary = object(widget.plan['summary']);
    final steps = objects(day['steps']);
    final weather = object(day['weather']);
    final pins = <MapPin>[];
    for (var i = 0; i < steps.length; i++) {
      final point = coordinate(steps[i]['place']);
      if (point != null) {
        pins.add(MapPin(point, '${i + 1}', onTap: () => _showStep(steps[i])));
      }
    }
    final line = coordinates(day['roadLine'] ?? day['route']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 24,
                runSpacing: 16,
                children: [
                  Stat(
                    '여행 기간',
                    string(object(widget.plan['product'])['label']),
                  ),
                  Stat(
                    '추천 등반일',
                    summary['hikeDay'] == null
                        ? '자유 일정'
                        : '${summary['hikeDay']}일차',
                  ),
                  Stat('총 이동 거리', '${summary['totalDriveKm'] ?? '—'} km'),
                ],
              ),
              if (summary['hikeLabel'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(string(summary['hikeLabel'])),
                ),
              if (widget.allowSave)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton.tonalIcon(
                    onPressed: saving
                        ? null
                        : () async {
                            setState(() => saving = true);
                            try {
                              await widget.store.save(
                                string(summary['title'], '제주 여행'),
                                'plan',
                                widget.plan,
                              );
                              if (context.mounted) {
                                toast(context, '내 일정에 저장했어요.');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                toast(context, '저장하지 못했어요: $e');
                              }
                            } finally {
                              if (mounted) setState(() => saving = false);
                            }
                          },
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text('내 일정에 저장'),
                  ),
                ),
            ],
          ),
        ),
        for (final warning in (widget.plan['warnings'] as List? ?? []))
          Notice(string(warning)),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            days.length,
            (i) => ChoiceChip(
              label: Text(
                '${i + 1}일차 · ${string(days[i]['date']).substring(5)}',
              ),
              selected: i == dayIndex,
              onSelected: (_) => setState(() => dayIndex = i),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          string(day['title']),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (weather.isNotEmpty)
          Notice(
            '${string(weather['desc'])} · 산 정상 ${string(object(weather['summit'])['label'])}\n${(object(weather['summit'])['reasons'] as List? ?? []).join('\n')}',
          ),
        const SizedBox(height: 12),
        JejuMap(
          revision: '${widget.plan['planId']}:$dayIndex',
          pins: pins,
          line: line,
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < steps.length; i++)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                child: Text('${i + 1}'),
              ),
              title: Text(
                '${steps[i]['time'] ?? ''}  ${steps[i]['title'] ?? ''}',
              ),
              subtitle: Text(
                '${steps[i]['desc'] ?? ''}${number(object(steps[i]['travel'])['min']) > 0 ? '\n이동 ${object(steps[i]['travel'])['min']}분 · ${object(steps[i]['travel'])['km']}km' : ''}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showStep(steps[i]),
            ),
          ),
        const Notice('탐방 예약·통제와 실제 영업시간은 출발 전에 확인해 주세요.'),
      ],
    );
  }

  void _showStep(Json step) {
    final place = object(step['place']),
        hours = object(object(step['place'])['hours']);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                string(step['title']),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '${step['time']}–${step['end']} · ${durationLabel(number(step['dur']))}',
              ),
              const SizedBox(height: 12),
              Text(string(step['desc'])),
              for (final tip in (step['tips'] as List? ?? []))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('• $tip'),
                ),
              if (hours.isNotEmpty)
                Notice(string(hours['today'], '영업시간 확인 필요')),
              if (coordinate(place) != null)
                TextButton.icon(
                  onPressed: () => openLink(
                    context,
                    'https://map.kakao.com/link/map/${Uri.encodeComponent(string(place['name']))},${place['lat']},${place['lon']}',
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('카카오맵에서 보기'),
                ),
              if (hours['url'] != null)
                TextButton(
                  onPressed: () => openLink(context, string(hours['url'])),
                  child: const Text('영업시간·예약 정보 확인'),
                ),
              if (objects(step['alts']).isNotEmpty) ...[
                const Divider(),
                const Text('주변 대안 장소'),
                ...objects(step['alts']).map(
                  (alt) => ListTile(
                    title: Text(string(alt['name'])),
                    subtitle: Text(
                      string(object(alt['hours'])['today'], '영업시간 미확인'),
                    ),
                    onTap: coordinate(alt) == null
                        ? null
                        : () => openLink(
                            context,
                            'https://map.kakao.com/link/map/${Uri.encodeComponent(string(alt['name']))},${alt['lat']},${alt['lon']}',
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
