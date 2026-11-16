import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../ui/common.dart';
import '../ui/jeju_map.dart';
import 'planner.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key, required this.store});
  final TripStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PageBody(
      children: [
        const PageHeading('내 일정', '저장한 제주 여행을 언제든 다시 꺼내 보세요.'),
        const Notice('이 기기의 브라우저·앱에 저장됩니다. 브라우저 데이터나 앱 데이터를 지우면 일정도 삭제됩니다.'),
        if (store.items.isEmpty)
          const Panel(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 50),
              child: Column(
                children: [
                  Icon(Icons.bookmarks_outlined, size: 48, color: moss),
                  SizedBox(height: 20),
                  Text('아직 저장한 일정이 없어요.'),
                  SizedBox(height: 8),
                  Text('등반 플래너나 코스 빌더에서 일정을 저장해 보세요.'),
                ],
              ),
            ),
          ),
        for (final item in store.items)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: Icon(
                item.kind == 'route' ? Icons.route : Icons.calendar_month,
                color: moss,
              ),
              title: Text(item.title),
              subtitle: Text('${dateLabel(item.savedAt)} 저장'),
              trailing: IconButton(
                tooltip: '저장 삭제',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  try {
                    await store.remove(item.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('저장 목록에서 삭제했어요.'),
                          action: SnackBarAction(
                            label: '되돌리기',
                            onPressed: () async {
                              try {
                                await store.restore(item);
                              } catch (e) {
                                if (context.mounted) toast(context, '$e');
                              }
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) toast(context, '$e');
                  }
                },
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: Text(item.title)),
                    body: PageBody(
                      children: [
                        if (item.kind == 'route') ...[
                          JejuMap(line: coordinates(item.data['line'])),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 24,
                            runSpacing: 16,
                            children: [
                              Stat(
                                '거리',
                                '${object(item.data['stats'])['distanceKm']} km',
                              ),
                              Stat(
                                '획득 고도',
                                '${object(item.data['stats'])['gainM']} m',
                              ),
                              Stat(
                                '예상 시간',
                                durationLabel(
                                  number(object(item.data['stats'])['estMin']),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          PlanDetail(
                            plan: item.data,
                            store: store,
                            allowSave: false,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
