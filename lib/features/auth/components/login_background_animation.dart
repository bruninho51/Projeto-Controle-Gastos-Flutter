import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/shared/components/animated_wave_background.dart';

class LoginBackgroundAnimation extends StatelessWidget {
  final Animation<double> w1;
  final Animation<double> w2;
  final Animation<double> w3;

  const LoginBackgroundAnimation({
    super.key,
    required this.w1,
    required this.w2,
    required this.w3,
  });

  static final _layers = [
    WaveLayer(
      baseY: 0.18,
      amplitude: 28,
      frequency: 1.8,
      color: const Color(0xFF3949AB).withValues(alpha: 0.18),
    ),
    WaveLayer(
      baseY: 0.38,
      amplitude: 22,
      frequency: 2.2,
      color: const Color(0xFF1A237E).withValues(alpha: 0.20),
    ),
    WaveLayer(
      baseY: 0.72,
      amplitude: 18,
      frequency: 1.5,
      color: const Color(0xFF1A237E).withValues(alpha: 0.28),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedWaveBackground(
        w1: w1,
        w2: w2,
        w3: w3,
        layers: _layers,
      ),
    );
  }
}
