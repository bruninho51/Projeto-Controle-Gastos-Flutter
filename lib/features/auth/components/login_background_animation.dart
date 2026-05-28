import 'dart:math';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([w1, w2, w3]),
        builder: (_, __) => CustomPaint(
          painter: BackgroundWavePainter(
            w1: w1.value,
            w2: w2.value,
            w3: w3.value,
          ),
        ),
      ),
    );
  }
}

class BackgroundWavePainter extends CustomPainter {
  final double w1, w2, w3;
  const BackgroundWavePainter({
    required this.w1,
    required this.w2,
    required this.w3,
  });

  Path _wave(Size size, double t, double baseY, double amp, double freq) {
    final path = Path();
    path.moveTo(0, baseY + sin(t * pi) * amp);
    for (double x = 0; x <= size.width; x++) {
      final y = baseY + sin((x / size.width * freq * pi) + t * pi) * amp;
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
      _wave(size, w1, size.height * 0.18, 28, 1.8),
      Paint()..color = const Color(0xFF3949AB).withValues(alpha: 0.18),
    );
    canvas.drawPath(
      _wave(size, w2, size.height * 0.38, 22, 2.2),
      Paint()..color = const Color(0xFF1A237E).withValues(alpha: 0.20),
    );
    canvas.drawPath(
      _wave(size, w3, size.height * 0.72, 18, 1.5),
      Paint()..color = const Color(0xFF1A237E).withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(BackgroundWavePainter old) =>
      old.w1 != w1 || old.w2 != w2 || old.w3 != w3;
}
