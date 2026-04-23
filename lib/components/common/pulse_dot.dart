// ─────────────────────────────────────────────────────────────────────────────
// PulseDot
//
// Bolinha verde que pulsa continuamente — útil para indicar status "ativo"
// ou conexão em tempo real.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/cupertino.dart';

enum PulseVariant { positive, negative, attention }

class PulseDot extends StatefulWidget {
  final Color startColor;
  final Color endColor;
  final Color? glowColor;
  final double size;
  final Duration duration;

  const PulseDot({
    super.key,
    required this.startColor,
    required this.endColor,
    this.glowColor,
    this.size = 7,
    this.duration = const Duration(milliseconds: 1400),
  });

  /// 🟢 Neutro positivo (ativo, ok, sucesso)
  const PulseDot.positive({Key? key})
      : this(
    key: key,
    startColor: const Color(0xFF69F0AE),
    endColor: const Color(0xFF00E676),
  );

  /// 🔴 Neutro negativo (inativo, erro, bloqueado)
  const PulseDot.negative({Key? key})
      : this(
    key: key,
    startColor: const Color(0xFFFF5252),
    endColor: const Color(0xFFD50000),
  );

  /// 🟡 Neutro atenção (pendente, alerta)
  const PulseDot.attention({Key? key})
      : this(
    key: key,
    startColor: const Color(0xFFFFF176),
    endColor: const Color(0xFFFFD600),
  );

  /// Factory baseada em enum (boa pra lógica dinâmica)
  factory PulseDot.variant(
      PulseVariant variant, {
        Key? key,
      }) {
    switch (variant) {
      case PulseVariant.positive:
        return PulseDot.positive(key: key);
      case PulseVariant.negative:
        return PulseDot.negative(key: key);
      case PulseVariant.attention:
        return PulseDot.attention(key: key);
    }
  }

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(covariant PulseDot oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Se mudar duração, atualiza controller
    if (oldWidget.duration != widget.duration) {
      _ctrl.duration = widget.duration;
      _ctrl
        ..reset()
        ..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glowBase = widget.glowColor ?? widget.startColor;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              widget.startColor,
              widget.endColor,
              _anim.value,
            ),
            boxShadow: [
              BoxShadow(
                color: glowBase.withOpacity(0.5 * _anim.value),
                blurRadius: widget.size,
                spreadRadius: 1,
              ),
            ],
          ),
        );
      },
    );
  }
}