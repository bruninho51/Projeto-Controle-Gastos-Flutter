import 'dart:math';
import 'package:flutter/material.dart';

class WaveLayer {
  final double baseY;
  final double amplitude;
  final double frequency;
  final Color color;

  const WaveLayer({
    required this.baseY,
    required this.amplitude,
    required this.frequency,
    required this.color,
  });
}

class AnimatedWaveBackground extends StatelessWidget {
  final Animation<double> w1;
  final Animation<double> w2;
  final Animation<double> w3;
  final List<WaveLayer> layers;

  const AnimatedWaveBackground({
    super.key,
    required this.w1,
    required this.w2,
    required this.w3,
    required this.layers,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([w1, w2, w3]),
      builder: (_, __) => CustomPaint(
        painter: WaveBackgroundPainter(
          w1: w1.value,
          w2: w2.value,
          w3: w3.value,
          layers: layers,
        ),
      ),
    );
  }
}

class WaveBackgroundPainter extends CustomPainter {
  final double w1, w2, w3;
  final List<WaveLayer> layers;

  const WaveBackgroundPainter({
    required this.w1,
    required this.w2,
    required this.w3,
    required this.layers,
  });

  Path _wave(Size size, double t, WaveLayer layer) {
    final baseY = layer.baseY * size.height;
    final path = Path();
    path.moveTo(0, baseY + sin(t * pi) * layer.amplitude);
    for (double x = 0; x <= size.width; x++) {
      final y = baseY +
          sin((x / size.width * layer.frequency * pi) + t * pi) *
              layer.amplitude;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final wValues = [w1, w2, w3];
    for (int i = 0; i < layers.length && i < wValues.length; i++) {
      canvas.drawPath(
        _wave(size, wValues[i], layers[i]),
        Paint()..color = layers[i].color,
      );
    }
  }

  @override
  bool shouldRepaint(WaveBackgroundPainter old) =>
      old.w1 != w1 || old.w2 != w2 || old.w3 != w3;
}
