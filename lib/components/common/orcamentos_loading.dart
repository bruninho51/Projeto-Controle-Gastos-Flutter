import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

const _phrases = [
  'Organizando suas finanças...',
  'Calculando seus gastos fixos...',
  'Analisando seus orçamentos...',
  'Sincronizando os dados...',
  'Preparando seu resumo mensal...',
  'Verificando suas metas...',
  'Carregando seus investimentos...',
  'Tudo sob controle por aqui...',
];

class OrcamentosLoading extends StatefulWidget {
  final String? message;

  const OrcamentosLoading({
    super.key,
    this.message,
  });

  @override
  State<OrcamentosLoading> createState() => _OrcamentosLoadingState();
}

class _OrcamentosLoadingState extends State<OrcamentosLoading>
    with TickerProviderStateMixin {
  late final AnimationController _scale;
  late final AnimationController _phrase;
  Timer? _phraseTimer;

  int _phraseIndex = 0;

  static const _primary = Color(0xFF283593);
  static const _light   = Color(0xFF3949AB);
  static const _muted   = Color(0xFF7986CB);

  @override
  void initState() {
    super.initState();

    _scale  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat(reverse: true);
    _phrase = AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))..repeat();

    if (widget.message == null) {
      _phraseTimer = Timer.periodic(const Duration(milliseconds: 3500), (_) {
        if (!mounted) return;
        setState(() => _phraseIndex = (_phraseIndex + 1) % _phrases.length);
        _phrase.forward(from: 0);
      });
    }
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    _scale.dispose();
    _phrase.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_scale, _phrase]),
        builder: (_, __) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone pulsante
              Transform.scale(
                scale: 0.9 + _scale.value * 0.2,
                child: Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A237E).withOpacity(0.08),
                    border: Border.all(color: _light.withOpacity(0.4), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primary,
                      border: Border.all(color: _light, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'R\$',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Frase ou mensagem
              SizedBox(
                height: 22,
                child: widget.message != null
                    ? Text(
                  widget.message!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _primary,
                  ),
                )
                    : _PhraseWidget(
                  phrase: _phrases[_phraseIndex],
                  progress: _phrase.value,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'AGUARDE',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2.5,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 16),
              // Barras
              const _MiniBarChart(),
            ],
          );
        },
      ),
    );
  }
}

// ── Frase animada ─────────────────────────────────────────

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
    if (progress < 0.15) return (1 - progress / 0.15) * 8;
    if (progress > 0.85) return -((progress - 0.85) / 0.15) * 8;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _opacity.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, _offsetY),
        child: const Text(
          '',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF283593),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Barras mini ───────────────────────────────────────────

class _MiniBarChart extends StatefulWidget {
  const _MiniBarChart();

  @override
  State<_MiniBarChart> createState() => _MiniBarChartState();
}

class _MiniBarChartState extends State<_MiniBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  final _heights   = [8.0, 14.0, 20.0, 16.0, 10.0, 18.0, 12.0, 17.0];
  final _opacities = [0.25, 0.40, 1.0, 0.65, 0.35, 0.80, 0.40, 0.65];

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
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Transform.scale(
              alignment: Alignment.bottomCenter,
              scaleY: 0.6 + t * 0.4,
              child: Container(
                width: 3,
                height: _heights[i],
                decoration: BoxDecoration(
                  color: const Color(0xFF283593).withOpacity(_opacities[i]),
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