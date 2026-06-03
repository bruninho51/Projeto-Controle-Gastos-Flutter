import 'dart:async';
import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/splash/components/animated_bar_chart.dart';
import 'package:orcamentos_app/features/splash/components/animated_coin.dart';
import 'package:orcamentos_app/features/splash/components/animated_phrase.dart';
import 'package:orcamentos_app/features/shared/components/animated_wave_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _wave1;
  late final AnimationController _wave2;
  late final AnimationController _wave3;
  late final AnimationController _coin;
  late final AnimationController _phrase;
  late final Timer _phraseTimer;

  static const _bg = Color(0xFF283593);
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

  static final _loadingLayers = [
    WaveLayer(
      baseY: 0.35,
      amplitude: 20,
      frequency: 2.0,
      color: const Color(0xFF3949AB).withValues(alpha: 0.5),
    ),
    WaveLayer(
      baseY: 0.50,
      amplitude: 16,
      frequency: 2.0,
      color: const Color(0xFF283593).withValues(alpha: 0.75),
    ),
    const WaveLayer(
      baseY: 0.62,
      amplitude: 12,
      frequency: 2.0,
      color: Color(0xFF1A237E),
    ),
  ];

  int _phraseIndex = 0;

  @override
  void initState() {
    super.initState();
    _wave1 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _wave2 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _wave3 = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _coin = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    _phrase = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
    _phraseTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
      if (!mounted) return;
      setState(() => _phraseIndex = (_phraseIndex + 1) % _phrases.length);
      _phrase.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _phraseTimer.cancel();
    _wave1.dispose();
    _wave2.dispose();
    _wave3.dispose();
    _coin.dispose();
    _phrase.dispose();
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
                bottom: 0,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 180,
                  child: AnimatedWaveBackground(
                    w1: _wave1,
                    w2: _wave2,
                    w3: _wave3,
                    layers: _loadingLayers,
                  ),
                ),
              ),
              Positioned(
                bottom: 155,
                left: 32,
                right: 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['fixos', 'variados', 'investimentos']
                      .map(
                        (t) => Text(
                          t,
                          style: const TextStyle(
                            fontSize: 11,
                            letterSpacing: 1.5,
                            color: Colors.white,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedCoin(progress: _coin.value),
                      const SizedBox(height: 28),
                      AnimatedPhrase(
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
                      const AnimatedBarChart(),
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
