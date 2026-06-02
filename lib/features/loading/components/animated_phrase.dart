import 'package:flutter/material.dart';

class AnimatedPhrase extends StatelessWidget {
  final String phrase;
  final double progress;

  const AnimatedPhrase({
    super.key,
    required this.phrase,
    required this.progress,
  });

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
