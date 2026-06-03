import 'package:flutter/material.dart';

class AnimatedBarChart extends StatefulWidget {
  const AnimatedBarChart({super.key});

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  final _heights = [14.0, 22.0, 32.0, 26.0, 18.0, 30.0, 20.0, 28.0];
  final _opacities = [0.35, 0.50, 1.0, 0.7, 0.45, 0.85, 0.50, 0.70];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

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
                  color: Colors.white.withValues(alpha: _opacities[i]),
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
