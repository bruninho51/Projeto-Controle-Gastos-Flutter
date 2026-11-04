import 'package:flutter/material.dart';

/// Peças compartilhadas pelas telas de detalhe de gasto na web.

class WebSelo extends StatelessWidget {
  final String texto;
  final Color cor;
  final bool ponto;

  const WebSelo({required this.texto, required this.cor, this.ponto = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (ponto) ...[
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Text(texto,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: cor)),
      ]),
    );
  }
}

class WebChipValor extends StatelessWidget {
  final String texto;
  final Color cor;

  const WebChipValor({required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: cor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(texto,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: cor)),
      ),
    );
  }
}

class WebLinhaDetalhe extends StatelessWidget {
  final IconData icon;
  final String rotulo;
  final Widget valor;
  final VoidCallback? onEdit;
  final bool bloqueada;
  final bool primeira;

  const WebLinhaDetalhe({
    required this.icon,
    required this.rotulo,
    required this.valor,
    this.onEdit,
    this.bloqueada = false,
    this.primeira = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            top: primeira
                ? BorderSide(color: Colors.grey.shade200)
                : BorderSide.none,
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 14),
            SizedBox(
              width: 190,
              child: Text(rotulo,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700])),
            ),
            Expanded(child: valor),
            if (bloqueada)
              Icon(Icons.lock_outline_rounded,
                  size: 17, color: Colors.grey[500])
            else if (onEdit != null)
              Icon(Icons.edit_outlined, size: 17, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}

class WebBordaTracejada extends CustomPainter {
  final Color cor;

  WebBordaTracejada(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final caminho = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, const Radius.circular(14)));
    for (final m in caminho.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(WebBordaTracejada old) => old.cor != cor;
}

class WebAcaoDetalhe extends StatelessWidget {
  final VoidCallback onTap;
  final Color cor;
  final String label;
  final Widget icone;

  const WebAcaoDetalhe({
    required this.onTap,
    required this.cor,
    required this.label,
    required this.icone,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(children: [
          icone,
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: cor)),
        ]),
      ),
    );
  }
}
