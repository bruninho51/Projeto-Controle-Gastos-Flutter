import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/gastos_variados_page/categoria_visual.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_resumo.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Tabela densa de lançamentos, agrupada por dia.
class GastosWebTable extends StatelessWidget {
  final List<GastoVariadoResponseDto> gastos;
  final Future<void> Function(GastoVariadoResponseDto) onTapItem;

  const GastosWebTable({
    super.key,
    required this.gastos,
    required this.onTapItem,
  });

  Map<DateTime, List<GastoVariadoResponseDto>> _agrupar() {
    final grupos = <DateTime, List<GastoVariadoResponseDto>>{};
    for (final g in gastos) {
      final d = DateTime(g.dataPgto.year, g.dataPgto.month, g.dataPgto.day);
      grupos.putIfAbsent(d, () => []).add(g);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agrupar();
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      decoration: webCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _CabecalhoColunas(),
          for (final entry in grupos.entries) ...[
            _CabecalhoDia(
              dia: entry.key,
              total: entry.value
                  .fold<double>(0, (s, g) => s + GastosResumo.valorDe(g)),
              fmt: fmt,
            ),
            for (final g in entry.value)
              _LinhaGasto(gasto: g, fmt: fmt, onTap: () => onTapItem(g)),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mostrando ${gastos.length} '
                '${gastos.length == 1 ? 'lançamento' : 'lançamentos'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _estiloColuna =
    TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey);

class _CabecalhoColunas extends StatelessWidget {
  const _CabecalhoColunas();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: const [
          SizedBox(width: 56, child: Text('Hora', style: _estiloColuna)),
          SizedBox(width: 52),
          Expanded(flex: 3, child: Text('Descrição', style: _estiloColuna)),
          Expanded(flex: 3, child: Text('Categoria', style: _estiloColuna)),
          SizedBox(
              width: 110,
              child: Text('Valor',
                  textAlign: TextAlign.right, style: _estiloColuna)),
          SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _CabecalhoDia extends StatelessWidget {
  final DateTime dia;
  final double total;
  final NumberFormat fmt;

  const _CabecalhoDia({
    required this.dia,
    required this.total,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final data = DateFormat("d 'de' MMMM", 'pt_BR').format(dia);
    final semana = DateFormat('EEEE', 'pt_BR').format(dia);

    return Container(
      color: const Color(0xFFF8F9FC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: data,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: kWebTexto)),
                TextSpan(
                    text: ', $semana',
                    style: TextStyle(color: Colors.grey[600])),
              ]),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(fmt.format(total),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kWebRoxo)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _LinhaGasto extends StatelessWidget {
  final GastoVariadoResponseDto gasto;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _LinhaGasto({
    required this.gasto,
    required this.fmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = corDoGasto(gasto);
    final valor = GastosResumo.valorDe(gasto);
    final isPatrimonio =
        gasto.categoriaGasto.tipo == TipoCategoriaGasto.patrimonio;
    final d = gasto.dataPgto;
    final temHora = d.hour != 0 || d.minute != 0;

    return InkWell(
      onTap: onTap,
      hoverColor: cor.withOpacity(0.04),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: Text(temHora ? DateFormat('HH:mm').format(d) : '—',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ),
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconeDaCategoria(gasto.categoriaGasto.nome),
                  color: cor, size: 18),
            ),
            Expanded(
              flex: 3,
              child: Text(gasto.descricao.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kWebTexto)),
            ),
            Expanded(
              flex: 3,
              child: Text(gasto.categoriaGasto.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
            SizedBox(
              width: 110,
              child: Text(
                isPatrimonio ? fmt.format(valor) : '- ${fmt.format(valor)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPatrimonio ? cor : Colors.grey[800]),
              ),
            ),
            SizedBox(
              width: 32,
              child: Icon(Icons.chevron_right_rounded,
                  size: 20, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
