import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _wave1;
  late final AnimationController _wave2;
  late final AnimationController _wave3;
  late final AnimationController _coin;
  late final AnimationController _phrase;
  late final Timer _phraseTimer;

  static const _bg     = Color(0xFF283593);
  static const _white40 = Color(0x66FFFFFF);

  static const _phrases = [
    'Organizando suas finanças...',
    'Calculando seus gastos fixos...',
    'Analisando seus orçamentos...',
    'Sincronizando os dados...',
    'Preparando seu resumo mensal...',
    'Verificando suas metas...',
    'Carregando seus investimentos...',
    'Tudo sob controle por aqui...',
  ];

  int _phraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _wave1  = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
    _wave2  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat(reverse: true);
    _wave3  = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _coin   = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();

    _phrase = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))
      ..repeat();

    _phraseTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      setState(() => _phraseIndex = (_phraseIndex + 1) % _phrases.length);
      _phrase.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _phraseTimer.cancel();
    _wave1.dispose(); _wave2.dispose(); _wave3.dispose();
    _coin.dispose(); _phrase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: Listenable.merge([_wave1, _wave2, _wave3, _coin, _phrase]),
        builder: (_, __) {
          return Stack(
            children: [
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: SizedBox(
                  height: 180,
                  child: CustomPaint(
                    painter: _WavePainter(
                      w1: _wave1.value,
                      w2: _wave2.value,
                      w3: _wave3.value,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 155, left: 32, right: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['fixos', 'variados', 'investimentos'].map((t) =>
                      Text(t, style: const TextStyle(
                        fontSize: 11, letterSpacing: 1.5,
                        color: Colors.white,
                      )),
                  ).toList(),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CoinWidget(progress: _coin.value),
                      const SizedBox(height: 28),
                      _PhraseWidget(
                        phrase: _phrases[_phraseIndex],
                        progress: _phrase.value,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'CARREGANDO ORÇAMENTOS',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.5,
                          color: _white40,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const _BarChart(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Moeda ────────────────────────────────────────────────

class _CoinWidget extends StatelessWidget {
  final double progress;
  const _CoinWidget({required this.progress});

  static const _dark  = Color(0xFF1A237E);
  static const _light = Color(0xFF3949AB);

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(progress * 2 * pi),
      child: Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _dark,
          border: Border.all(color: _light, width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24, width: 1.5),
          ),
          alignment: Alignment.center,
          child: const Text(
            'R\$',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Frase animada ────────────────────────────────────────

class _PhraseWidget extends StatelessWidget {
  final String phrase;
  final double progress;
  const _PhraseWidget({required this.phrase, required this.progress});

  double get _opacity {
    if (progress < 0.15) return progress / 0.15;
    if (progress > 0.85) return 1 - (progress - 0.85) / 0.15;
    return 1.0;
  }

  double get _offsetY {
    if (progress < 0.15) return (1 - progress / 0.15) * 10;
    if (progress > 0.85) return -((progress - 0.85) / 0.15) * 10;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Opacity(
        opacity: _opacity.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, _offsetY),
          child: Text(
            phrase,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Ondas ────────────────────────────────────────────────

class _WavePainter extends CustomPainter {
  final double w1, w2, w3;
  const _WavePainter({required this.w1, required this.w2, required this.w3});

  Path _wave(Size size, double t, double baseY, double amp) {
    final path = Path();
    path.moveTo(0, baseY + sin(t * pi) * amp);
    for (double x = 0; x <= size.width; x++) {
      final y = baseY + sin((x / size.width * 2 * pi) + t * pi) * amp;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _wave(size, w1, size.height * 0.35, 20),
      Paint()..color = const Color(0xFF3949AB).withOpacity(0.5),
    );
    canvas.drawPath(
      _wave(size, w2, size.height * 0.50, 16),
      Paint()..color = const Color(0xFF283593).withOpacity(0.75),
    );
    canvas.drawPath(
      _wave(size, w3, size.height * 0.62, 12),
      Paint()..color = const Color(0xFF1A237E),
    );
  }

  @override
  bool shouldRepaint(_WavePainter old) => true;
}

// ── Barras ───────────────────────────────────────────────

class _BarChart extends StatefulWidget {
  const _BarChart();
  @override
  State<_BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<_BarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  final _heights   = [14.0, 22.0, 32.0, 26.0, 18.0, 30.0, 20.0, 28.0];
  final _opacities = [0.35, 0.50,  1.0,  0.7,  0.45, 0.85, 0.50, 0.70];

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_heights.length, (i) {
          final delay = i / _heights.length;
          final t = ((_c.value - delay) % 1.0).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.5),
            child: Transform.scale(
              alignment: Alignment.bottomCenter,
              scaleY: 0.6 + t * 0.4,
              child: Container(
                width: 4,
                height: _heights[i],
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_opacities[i]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}