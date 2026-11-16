import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../ui/common.dart';

/// 첫 진입 시 보여주는 여행 출발 시작 화면.
///
/// [duration] 동안 김포→제주 비행 진행도와 준비 단계를 보여준 뒤
/// [onDone]을 호출합니다. 사용자는 언제든 건너뛸 수 있습니다.
class IntroPage extends StatefulWidget {
  const IntroPage({
    super.key,
    required this.onDone,
    this.duration = const Duration(seconds: 10),
  });
  final VoidCallback onDone;
  final Duration duration;
  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> with TickerProviderStateMixin {
  late final progress = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool finished = false;

  static const stages = [
    (0.00, '여행 가방을 챙기고 있어요'),
    (0.15, '김포공항에서 탑승 수속 중이에요'),
    (0.30, '제주행 비행기가 이륙했어요'),
    (0.48, '구름 위에서 한라산 날씨를 확인하고 있어요'),
    (0.64, '오름과 올레길 코스를 펼치고 있어요'),
    (0.80, '곧 제주국제공항에 착륙해요'),
    (0.95, '제주에 도착했어요. 여행을 시작해요!'),
  ];

  @override
  void initState() {
    super.initState();
    entrance.forward();
    float.repeat(reverse: true);
    progress
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _finish();
      })
      ..forward();
  }

  void _finish() {
    if (finished) return;
    finished = true;
    widget.onDone();
  }

  @override
  void dispose() {
    progress.dispose();
    float.dispose();
    entrance.dispose();
    super.dispose();
  }

  String stage(double p) =>
      stages.lastWhere((s) => p >= s.$1, orElse: () => stages.first).$2;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final fg = dark ? Colors.white : const Color(0xFF191F28);
    final muted = dark ? const Color(0xFFB0B8C1) : const Color(0xFF4E5968);
    final line = dark ? const Color(0xFF33403C) : const Color(0xFFE5E8EB);
    final track = dark ? const Color(0xFF26302D) : const Color(0xFFF2F4F6);
    final bg = dark ? const Color(0xFF171E1C) : const Color(0xFFF9FAFB);
    final fade = CurvedAnimation(parent: entrance, curve: Curves.easeOutCubic);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(foregroundColor: muted),
                      child: const Text('건너뛰기'),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: AnimatedBuilder(
                        animation: Listenable.merge([float, entrance]),
                        builder: (context, child) {
                          final dy = reduceMotion
                              ? 0.0
                              : math.sin(float.value * math.pi) * -8;
                          return Opacity(
                            opacity: fade.value,
                            child: Transform.translate(
                              offset: Offset(0, dy + (1 - fade.value) * 16),
                              child: Transform.scale(
                                scale: .9 + fade.value * .1,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _LogoTile(dark: dark),
                      ),
                    ),
                  ),
                  FadeTransition(
                    opacity: fade,
                    child: AnimatedBuilder(
                      animation: progress,
                      builder: (context, _) {
                        final p = progress.value;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'OREUM IT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.6,
                                color: fg,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: line),
                            const SizedBox(height: 20),
                            Text(
                              '우리 이제\n같이 제주로 떠나는 사이!',
                              style: TextStyle(
                                fontSize: 28,
                                height: 1.3,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.6,
                                color: fg,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '바다에서 정상까지, 테마별 제주 여행을 시작해 보세요!',
                              style: TextStyle(fontSize: 15, color: muted),
                            ),
                            const SizedBox(height: 28),
                            _BoardingPass(
                              progress: p,
                              dark: dark,
                              fg: fg,
                              muted: muted,
                              line: line,
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 350),
                                    transitionBuilder: (child, a) =>
                                        FadeTransition(
                                          opacity: a,
                                          child: SlideTransition(
                                            position: Tween(
                                              begin: const Offset(0, .3),
                                              end: Offset.zero,
                                            ).animate(a),
                                            child: child,
                                          ),
                                        ),
                                    layoutBuilder: (current, previous) => Stack(
                                      alignment: Alignment.centerLeft,
                                      children: [...previous, ?current],
                                    ),
                                    child: Text(
                                      stage(p),
                                      key: ValueKey(stage(p)),
                                      semanticsLabel: stage(p),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: fg,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${(p * 100).floor()}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: muted,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Semantics(
                              label: '여행 준비 진행률',
                              value: '${(p * 100).floor()}%',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: p,
                                  minHeight: 4,
                                  color: fg,
                                  backgroundColor: track,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        );
                      },
                    ),
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

/// 투어 내비게이터식 단색 앱 아이콘 타일. 한라산·오름 능선과 바다 물결.
class _LogoTile extends StatelessWidget {
  const _LogoTile({required this.dark});
  final bool dark;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '오름잇',
    child: Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF4F9A86) : moss,
        borderRadius: BorderRadius.circular(28),
      ),
      child: CustomPaint(painter: _JejuGlyph()),
    ),
  );
}

class _JejuGlyph extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 32;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * u
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;
    Offset o(double x, double y) => Offset(x * u, y * u);
    // 오름 + 한라산 능선
    canvas.drawPath(
      Path()
        ..moveTo(o(6, 20).dx, o(6, 20).dy)
        ..lineTo(o(10, 15).dx, o(10, 15).dy)
        ..lineTo(o(13, 17).dx, o(13, 17).dy)
        ..lineTo(o(18.5, 10).dx, o(18.5, 10).dy)
        ..lineTo(o(26, 20).dx, o(26, 20).dy),
      stroke,
    );
    // 바다 물결
    final wave = Path()..moveTo(o(6, 24.5).dx, o(6, 24.5).dy);
    for (var i = 0; i < 4; i++) {
      final x = 6.0 + i * 5;
      wave.quadraticBezierTo(
        o(x + 2.5, i.isEven ? 22.5 : 26.5).dx,
        o(x + 2.5, i.isEven ? 22.5 : 26.5).dy,
        o(x + 5, 24.5).dx,
        o(x + 5, 24.5).dy,
      );
    }
    canvas.drawPath(wave, stroke..strokeCap = StrokeCap.round);
    // 해
    canvas.drawCircle(o(24.5, 8), 1.8 * u, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_JejuGlyph old) => false;
}

/// 탑승권 모양 카드. 상단 띠·절취선·양쪽 홈이 있고, 그 안에서
/// 김포(GMP) → 제주(CJU) 비행기가 진행률을 따라 날아갑니다.
class _BoardingPass extends StatelessWidget {
  const _BoardingPass({
    required this.progress,
    required this.dark,
    required this.fg,
    required this.muted,
    required this.line,
  });
  final double progress;
  final bool dark;
  final Color fg, muted, line;

  static const headerHeight = 40.0;

  Widget _airport(String code, String name, CrossAxisAlignment align) => Column(
    crossAxisAlignment: align,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        code,
        style: TextStyle(
          fontSize: 24,
          height: 1.1,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: fg,
        ),
      ),
      Text(name, style: TextStyle(fontSize: 12, color: muted)),
    ],
  );

  Widget _field(String label, String value, CrossAxisAlignment align) => Column(
    crossAxisAlignment: align,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: muted,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: fg),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final date =
        '${now.month.toString().padLeft(2, '0')}.${now.day.toString().padLeft(2, '0')}';
    final band = dark ? const Color(0xFF4F9A86) : moss;
    const header = TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.8,
    );
    return CustomPaint(
      painter: _TicketPainter(
        notchY: headerHeight,
        fill: dark ? const Color(0xFF232E2A) : Colors.white,
        band: band,
        border: line,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: headerHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.flight_takeoff, size: 15, color: Colors.white),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'BOARDING PASS',
                      style: header,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text('OR 1947', style: header),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    _airport('GMP', '김포', CrossAxisAlignment.start),
                    const SizedBox(width: 12),
                    Expanded(child: _route(band)),
                    const SizedBox(width: 12),
                    _airport('CJU', '제주', CrossAxisAlignment.end),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _field('DATE', date, CrossAxisAlignment.start),
                    _field('GATE', '오름', CrossAxisAlignment.center),
                    _field('SEAT', '1947m', CrossAxisAlignment.end),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _route(Color color) => SizedBox(
    height: 36,
    child: LayoutBuilder(
      builder: (context, c) {
        const plane = 22.0;
        final x = (c.maxWidth - plane) * progress;
        // 이륙 후 살짝 떠올랐다가 착륙하는 포물선
        final lift = math.sin(progress * math.pi) * 8;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DashPainter(
                  progress: progress,
                  done: color,
                  rest: line,
                ),
              ),
            ),
            Positioned(
              left: x,
              top: 18 - plane / 2 - lift,
              child: Transform.rotate(
                angle: math.pi / 2,
                child: Icon(Icons.flight, size: plane, color: color),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// 둥근 모서리 + 절취선 높이의 양쪽 반원 홈을 가진 티켓 외곽.
class _TicketPainter extends CustomPainter {
  _TicketPainter({
    required this.notchY,
    required this.fill,
    required this.band,
    required this.border,
  });
  final double notchY;
  final Color fill, band, border;
  static const radius = 16.0, notch = 9.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path.combine(
      PathOperation.difference,
      Path()..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(radius),
        ),
      ),
      Path()
        ..addOval(Rect.fromCircle(center: Offset(0, notchY), radius: notch))
        ..addOval(
          Rect.fromCircle(center: Offset(size.width, notchY), radius: notch),
        ),
    );
    canvas.drawPath(outline, Paint()..color = fill);
    canvas.save();
    canvas.clipPath(outline);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, notchY),
      Paint()..color = band,
    );
    canvas.restore();
    canvas.drawPath(
      outline,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    // 절취선
    final perforation = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (double x = notch + 6; x < size.width - notch - 6; x += 9) {
      canvas.drawLine(
        Offset(x, notchY),
        Offset(math.min(x + 4, size.width - notch - 6), notchY),
        perforation,
      );
    }
  }

  @override
  bool shouldRepaint(_TicketPainter old) =>
      old.notchY != notchY ||
      old.fill != fill ||
      old.band != band ||
      old.border != border;
}

class _DashPainter extends CustomPainter {
  _DashPainter({
    required this.progress,
    required this.done,
    required this.rest,
  });
  final double progress;
  final Color done, rest;
  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final split = size.width * progress;
    final paint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (double x = 0; x < size.width; x += 8) {
      paint.color = x < split ? done : rest;
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 4, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) =>
      old.progress != progress || old.done != done || old.rest != rest;
}
