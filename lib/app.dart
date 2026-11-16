import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/api.dart';
import 'core/models.dart';
import 'core/store.dart';
import 'features/planner.dart';
import 'features/builder.dart';
import 'features/saved.dart';
import 'features/challenge.dart';
import 'features/intro.dart';
import 'features/routes.dart';
import 'features/weather.dart';
import 'ui/common.dart';

class OreumApp extends StatefulWidget {
  const OreumApp({
    super.key,
    required this.api,
    required this.store,
    this.introDuration = const Duration(seconds: 10),
  });
  final OreumApi api;
  final TripStore store;

  /// 시작 화면(여행 출발 로딩) 표시 시간. `Duration.zero`이면 건너뜁니다.
  final Duration introDuration;
  @override
  State<OreumApp> createState() => _OreumAppState();
}

class _OreumAppState extends State<OreumApp> {
  late ThemeMode themeMode = ThemeMode.values.firstWhere(
    (m) => m.name == widget.store.preferences.getString('oreum.flutter.theme'),
    orElse: () => ThemeMode.system,
  );
  late bool introDone = widget.introDuration == Duration.zero;
  ThemeData theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme.fromSeed(
      seedColor: moss,
      brightness: brightness,
      primary: dark ? const Color(0xFFDAB58F) : accent,
      secondary: moss,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colors,
      scaffoldBackgroundColor: dark
          ? const Color(0xFF171E1C)
          : const Color(0xFFF6F6F1),
      fontFamily: 'Pretendard',
      fontFamilyFallback: const ['Noto Sans KR', 'Malgun Gothic', 'sans-serif'],
      appBarTheme: AppBarTheme(
        backgroundColor: dark
            ? const Color(0xFF171E1C)
            : const Color(0xFFF6F6F1),
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: dark ? Colors.white : ink,
        ),
        titleLarge: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        bodyMedium: const TextStyle(fontSize: 14, height: 1.6),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: dark ? const Color(0xFF232E2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF1C2622) : const Color(0xFFF8F8F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '오름잇 · OREUM IT',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: theme(Brightness.light),
    darkTheme: theme(Brightness.dark),
    themeMode: themeMode,
    home: AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeOutCubic,
      child: introDone
          ? _Home(
              key: const ValueKey('home'),
              api: widget.api,
              store: widget.store,
              themeMode: themeMode,
              onReplay: () => setState(() => introDone = false),
              onTheme: (value) {
                setState(() => themeMode = value);
                widget.store.preferences.setString(
                  'oreum.flutter.theme',
                  value.name,
                );
              },
            )
          : IntroPage(
              key: const ValueKey('intro'),
              duration: widget.introDuration,
              onDone: () => setState(() => introDone = true),
            ),
    ),
  );
}

class _Home extends StatefulWidget {
  const _Home({
    super.key,
    required this.api,
    required this.store,
    required this.themeMode,
    required this.onTheme,
    required this.onReplay,
  });
  final OreumApi api;
  final TripStore store;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onTheme;
  final VoidCallback onReplay;
  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int index = 0;
  final visited = <int>{0};
  static const labels = [
    '등반 플래너',
    '코스 빌더',
    '내 일정',
    '0 to 1947 챌린지',
    '코스 그리기',
    '실시간 기상',
  ];
  static const icons = [
    Icons.landscape_outlined,
    Icons.map_outlined,
    Icons.bookmark_outline,
    Icons.emoji_events_outlined,
    Icons.route_outlined,
    Icons.cloud_outlined,
  ];
  void select(int value) => setState(() {
    index = value;
    visited.add(value);
  });
  Widget page(int i) => switch (i) {
    0 => PlannerPage(api: widget.api, store: widget.store),
    1 => BuilderPage(api: widget.api, store: widget.store),
    2 => SavedPage(store: widget.store),
    3 => ChallengePage(api: widget.api, store: widget.store),
    4 => RoutesPage(api: widget.api, store: widget.store),
    _ => WeatherPage(api: widget.api),
  };
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1050;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 78,
        titleSpacing: 12,
        title: InkWell(
          onTap: () => select(0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 40,
                height: 40,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.landscape, color: moss, size: 32),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오름잇',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'OREUM IT',
                    style: TextStyle(fontSize: 9, letterSpacing: 2.4),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (wide)
            ...List.generate(
              6,
              (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: TextButton.icon(
                  onPressed: () => select(i),
                  style: TextButton.styleFrom(
                    backgroundColor: index == i
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                  ),
                  icon: Icon(icons[i], size: 17),
                  label: Text(labels[i]),
                ),
              ),
            ),
          PopupMenuButton<ThemeMode>(
            tooltip: '화면 모드',
            icon: const Icon(Icons.brightness_6_outlined, size: 21),
            initialValue: widget.themeMode,
            onSelected: widget.onTheme,
            itemBuilder: (_) => const [
              PopupMenuItem(value: ThemeMode.system, child: Text('시스템 설정')),
              PopupMenuItem(value: ThemeMode.light, child: Text('라이트')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('다크')),
            ],
          ),
          IconButton(
            tooltip: '이용안내',
            onPressed: _help,
            icon: const Icon(Icons.help_outline, size: 21),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: Column(
                  children: [
                    const ListTile(title: Text('오름잇 · OREUM IT')),
                    const Divider(),
                    ...List.generate(
                      6,
                      (i) => ListTile(
                        selected: index == i,
                        leading: Icon(icons[i]),
                        title: Text(labels[i]),
                        onTap: () {
                          Navigator.pop(context);
                          select(i);
                        },
                      ),
                    ),
                    const Spacer(),
                    ListTile(
                      leading: const Icon(Icons.replay),
                      title: const Text('REPLAY · 시작화면 다시 보기'),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onReplay();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('데이터 출처'),
                      onTap: () {
                        Navigator.pop(context);
                        _sources();
                      },
                    ),
                  ],
                ),
              ),
            ),
      body: Column(
        children: [
          if (!wide)
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemCount: labels.length,
                itemBuilder: (context, i) => ChoiceChip(
                  label: Text(labels[i]),
                  selected: index == i,
                  onSelected: (_) => select(i),
                ),
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: index,
              children: List.generate(
                6,
                (i) => visited.contains(i) ? page(i) : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      '오름잇 · 바다에서 정상까지, 나만의 제주',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.onReplay,
                    icon: const Icon(Icons.replay, size: 16),
                    label: const Text(
                      'REPLAY',
                      style: TextStyle(letterSpacing: 1),
                    ),
                  ),
                  TextButton(onPressed: _sources, child: const Text('데이터 출처')),
                ],
              ),
            )
          : null,
    );
  }

  void _help() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('오름잇 이용 안내'),
      content: const SingleChildScrollView(
        child: Text(
          '1. 참여 방식·기간·출발일을 고르고 일정을 조회하세요.\n\n2. 일차별 시간표와 지도를 확인하고 내 일정에 저장하세요.\n\n3. 코스 빌더에서 장소를 직접 담거나 지도에 경로를 그릴 수 있어요.\n\n4. 챌린지는 출발점과 도착점에서 실제 위치·사진으로 인증합니다.\n\n5. 출발 전 실시간 기상과 탐방 통제를 확인하세요.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            _sources();
          },
          child: const Text('데이터 출처'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
  void _sources() {
    final sources = widget.api.get('/meta');
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .75,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ApiView(
              future: sources,
              builder: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '데이터 출처',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '지도: © OpenStreetMap contributors (ODbL)\n관측: 기상청 · 예보: Open-Meteo (CC BY 4.0)',
                  ),
                  ...objects(object(data)['sources']).map(
                    (s) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(string(s['name'])),
                      subtitle: Text(
                        '${s['use'] ?? ''}${s['license'] == null ? '' : '\n${s['license']}'}',
                      ),
                    ),
                  ),
                  if (object(object(data)['storage'])['mode'] == 'memory')
                    const Notice(
                      '현재 인증 서버의 기록은 임시 저장 방식입니다. 서버 재시작 시 사라질 수 있습니다. 내 일정은 이 기기에 별도로 저장됩니다.',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
