import 'package:flutter/material.dart';
import '../core/api.dart';
import '../core/course_planner.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../ui/common.dart';
import '../ui/jeju_map.dart';
import 'planner.dart';

class BuilderPage extends StatefulWidget {
  const BuilderPage({super.key, required this.api, required this.store});
  final OreumApi api;
  final TripStore store;
  @override
  State<BuilderPage> createState() => _BuilderPageState();
}

class _BuilderPageState extends State<BuilderPage> {
  late Future<List<Place>> places = load();
  Future<List<Place>> load() async => objects(
    object(await widget.api.get('/course/places'))['places'],
  ).map(Place.new).toList();
  String query = '', category = 'all', transport = 'rent';
  int activeDay = 0, limit = 24;
  DateTime date = DateTime.now().add(const Duration(days: 1));
  List<List<Place>> days = [[], [], []];
  Json? result;
  final title = TextEditingController(text: '나만의 제주 코스');
  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      PageHeading(
        '코스 빌더',
        '가고 싶은 곳을 담고, 날짜별 동선을 만들어요.',
        trailing: result == null
            ? null
            : TextButton(
                onPressed: () => setState(() => result = null),
                child: const Text('코스 수정'),
              ),
      ),
      if (result != null)
        PlanDetail(plan: result!, store: widget.store)
      else ...[
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormGrid(
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: '코스 이름'),
                  ),
                  DateField(
                    value: date,
                    onChanged: (v) => setState(() => date = v),
                  ),
                  SelectField(
                    label: '교통수단',
                    value: transport,
                    options: const {'rent': '렌터카', 'bus': '버스', 'foot': '도보'},
                    onChanged: (v) => setState(() => transport = v),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (var i = 0; i < days.length; i++)
                    ChoiceChip(
                      label: Text('${i + 1}일차 · ${days[i].length}곳'),
                      selected: activeDay == i,
                      onSelected: (_) => setState(() => activeDay = i),
                    ),
                  if (days.length < 7)
                    TextButton.icon(
                      onPressed: () => setState(() {
                        days.add([]);
                        activeDay = days.length - 1;
                      }),
                      icon: const Icon(Icons.add),
                      label: const Text('하루 추가'),
                    ),
                  if (days.length > 1 && days.last.isEmpty)
                    TextButton(
                      onPressed: () => setState(() {
                        days.removeLast();
                        activeDay = activeDay.clamp(0, days.length - 1);
                      }),
                      child: const Text('마지막 빈 날짜 삭제'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (days[activeDay].isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('아래 장소 목록에서 이 날에 방문할 곳을 담아 주세요.'),
                ),
              for (var i = 0; i < days[activeDay].length; i++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${i + 1}')),
                  title: Text(days[activeDay][i].name),
                  subtitle: Text(
                    '${days[activeDay][i].categoryLabel} · ${durationLabel(days[activeDay][i].duration)}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: '위로 이동',
                        onPressed: i == 0
                            ? null
                            : () => setState(() {
                                final p = days[activeDay].removeAt(i);
                                days[activeDay].insert(i - 1, p);
                              }),
                        icon: const Icon(Icons.arrow_upward, size: 20),
                      ),
                      IconButton(
                        tooltip: '코스에서 빼기',
                        onPressed: () =>
                            setState(() => days[activeDay].removeAt(i)),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: days.every((d) => d.isEmpty)
                    ? null
                    : () => setState(
                        () => result = buildCourse(
                          startDate: date,
                          days: days,
                          transport: transport,
                          title: title.text.trim().isEmpty
                              ? '나만의 제주 코스'
                              : title.text.trim(),
                        ),
                      ),
                icon: const Icon(Icons.route),
                label: const Text('일자별 시간표 만들기'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ApiView<List<Place>>(
          future: places,
          onRetry: () => setState(() => places = load()),
          builder: (all) {
            final filtered = all
                .where(
                  (p) =>
                      (category == 'all' || p.category == category) &&
                      '${p.name} ${p.hours}'.toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
            final selected = days
                .expand((d) => d)
                .where((p) => p.position != null)
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (selected.isNotEmpty) ...[
                  JejuMap(
                    revision: selected.map((p) => p.id).join(','),
                    pins: [
                      for (var i = 0; i < selected.length; i++)
                        MapPin(selected[i].position!, '${i + 1}'),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                TextField(
                  decoration: InputDecoration(
                    labelText: '제주 장소 검색',
                    hintText: '${all.length}곳에서 찾아보세요',
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() {
                    query = v;
                    limit = 24;
                  }),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.entries
                      .map(
                        (e) => ChoiceChip(
                          label: Text(e.value),
                          selected: category == e.key,
                          onSelected: (_) => setState(() {
                            category = e.key;
                            limit = 24;
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text('${filtered.length}곳 · ${activeDay + 1}일차에 담기'),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const Notice('검색 결과가 없어요. 다른 이름으로 검색해 주세요.'),
                for (final p in filtered.take(limit))
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.categoryLabel} · ${p.hours}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _details(p),
                      trailing: IconButton(
                        tooltip: days[activeDay].any((v) => v.id == p.id)
                            ? '담은 장소'
                            : '${p.name} 담기',
                        icon: Icon(
                          days[activeDay].any((v) => v.id == p.id)
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          color: moss,
                        ),
                        onPressed: () => setState(() {
                          if (!days[activeDay].any((v) => v.id == p.id)) {
                            days[activeDay].add(p);
                          }
                        }),
                      ),
                    ),
                  ),
                if (filtered.length > limit)
                  OutlinedButton(
                    onPressed: () => setState(() => limit += 24),
                    child: const Text('장소 더 보기'),
                  ),
              ],
            );
          },
        ),
      ],
    ],
  );
  void _details(Place place) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(place.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Text('${place.categoryLabel}\n${place.hours}'),
            if (object(place.raw['bf']).isNotEmpty)
              Notice(string(object(place.raw['bf'])['summary'])),
            if (place.position != null) ...[
              const SizedBox(height: 16),
              JejuMap(height: 240, pins: [MapPin(place.position!, '1')]),
              TextButton(
                onPressed: () => openLink(
                  context,
                  'https://map.kakao.com/link/map/${Uri.encodeComponent(place.name)},${place.position!.latitude},${place.position!.longitude}',
                ),
                child: const Text('카카오맵에서 상세 정보 보기'),
              ),
            ],
            FilledButton(
              onPressed: () {
                setState(() {
                  if (!days[activeDay].any((p) => p.id == place.id)) {
                    days[activeDay].add(place);
                  }
                });
                Navigator.pop(context);
              },
              child: Text('${activeDay + 1}일차에 담기'),
            ),
          ],
        ),
      ),
    ),
  );
}
