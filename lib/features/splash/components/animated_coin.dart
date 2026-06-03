import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedCoin extends StatelessWidget {
  final double progress;

  const AnimatedCoin({super.key, required this.progress});

  static const _dark = Color(0xFF1A237E);
  static const _light = Color(0xFF3949AB);

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(progress * 2 * pi),
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _dark,
          border: Border.all(color: _light, width: 2),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 42,
          height: 42,
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
