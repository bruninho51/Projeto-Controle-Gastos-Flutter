import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

/// Total gasto em uma categoria.
class CategoriaTotal {
  final String nome;
  final double total;
  final Color cor;

  const CategoriaTotal(this.nome, this.total, this.cor);
}

class WebTitulo extends StatelessWidget {
  final String texto;
  const WebTitulo(this.texto);

  @override
  Widget build(BuildContext context) => Text(texto,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w800, color: kWebTexto));
}

class WebCategoriasCard extends StatelessWidget {
  final List<CategoriaTotal> porCategoria;
  final double total;
  const WebCategoriasCard({required this.porCategoria, required this.total});

  static const _maxFatias = 4;

  List<CategoriaTotal> get _fatias {
    if (porCategoria.length <= _maxFatias) return porCategoria;
    final outros = porCategoria
        .skip(_maxFatias - 1)
        .fold<double>(0, (s, c) => s + c.total);
    return [
      ...porCategoria.take(_maxFatias - 1),
      CategoriaTotal('Outros', outros, Colors.grey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final fatias = _fatias;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebTitulo('Gastos por categoria'),
          const SizedBox(height: 16),
          if (fatias.isEmpty || total <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Sem dados',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ),
            )
          else ...[
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 46,
                  sections: [
                    for (final f in fatias)
                      PieChartSectionData(
                        value: f.total,
                        color: f.cor,
                        radius: 22,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            for (final f in fatias)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(color: f.cor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(f.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ),
                    Text('${(f.total / total * 100).round()}%',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kWebTexto)),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
