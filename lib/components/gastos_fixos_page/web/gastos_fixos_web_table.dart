import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/gasto_fixo_status.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/gastos_fixos_resumo.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Tabela densa de gastos fixos, agrupada por situação (vencidos, pendentes, pagos).
class GastosFixosWebTable extends StatelessWidget {
  final List<GastoFixoResponseDto> gastos;
  final Future<void> Function(GastoFixoResponseDto) onTapItem;

  const GastosFixosWebTable({
    super.key,
    required this.gastos,
    required this.onTapItem,
  });

  static const _ordem = ['VENCIDO', 'PENDENTE', 'PAGO'];

  List<GastoFixoResponseDto> _doStatus(String status) {
    final lista = gastos.where((g) => statusDoGastoFixo(g) == status).toList();
    DateTime? data(GastoFixoResponseDto g) =>
        status == 'PAGO' ? g.dataPgto : g.dataVenc;
    lista.sort((a, b) {
      final da = data(a), db = data(b);
      if (da == null || db == null)
        return da == null ? (db == null ? 0 : 1) : -1;
      return status == 'PAGO' ? db.compareTo(da) : da.compareTo(db);
    });
    return lista;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      decoration: webCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _CabecalhoColunas(),
          for (final status in _ordem)
            ..._secao(status, _doStatus(status), fmt),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Mostrando ${gastos.length} '
                '${gastos.length == 1 ? 'item' : 'itens'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _secao(
      String status, List<GastoFixoResponseDto> itens, NumberFormat fmt) {
    if (itens.isEmpty) return const [];
    final total = itens.fold<double>(
        0,
        (s, g) =>
            s +
            (status == 'PAGO'
                ? GastosFixosResumo.pagoDe(g)
                : GastosFixosResumo.previstoDe(g)));
    return [
      _CabecalhoSecao(
          status: status, quantidade: itens.length, total: total, fmt: fmt),
      for (final g in itens)
        _Linha(gasto: g, fmt: fmt, onTap: () => onTapItem(g)),
    ];
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
          SizedBox(width: 52),
          Expanded(flex: 3, child: Text('Descrição', style: _estiloColuna)),
          Expanded(flex: 2, child: Text('Categoria', style: _estiloColuna)),
          SizedBox(width: 120, child: Text('Data', style: _estiloColuna)),
          SizedBox(
              width: 100,
              child: Text('Previsto',
                  textAlign: TextAlign.right, style: _estiloColuna)),
          SizedBox(
              width: 100,
              child: Text('Pago',
                  textAlign: TextAlign.right, style: _estiloColuna)),
          SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _CabecalhoSecao extends StatelessWidget {
  final String status;
  final int quantidade;
  final double total;
  final NumberFormat fmt;

  const _CabecalhoSecao({
    required this.status,
    required this.quantidade,
    required this.total,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final cor = corDoStatusFixo(status);
    final (titulo, icone, rotuloTotal) = switch (status) {
      'VENCIDO' => ('Vencidos', Icons.warning_amber_rounded, 'previsto'),
      'PENDENTE' => ('Pendentes', Icons.schedule_rounded, 'previsto'),
      _ => ('Pagos', Icons.check_circle_rounded, 'pago'),
    };

    return Container(
      color: const Color(0xFFF8F9FC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icone, size: 16, color: cor),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                    text: titulo,
                    style: TextStyle(fontWeight: FontWeight.w700, color: cor)),
                TextSpan(
                    text:
                        '  •  $quantidade ${quantidade == 1 ? 'item' : 'itens'}',
                    style: TextStyle(color: Colors.grey[500])),
              ]),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text('${fmt.format(total)} $rotuloTotal',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: cor)),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final GastoFixoResponseDto gasto;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _Linha({required this.gasto, required this.fmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = statusDoGastoFixo(gasto);
    final corStatus = corDoStatusFixo(status);
    final isPatrimonio =
        gasto.categoriaGasto.tipo == TipoCategoriaGasto.patrimonio;
    final corIcone = isPatrimonio ? gasto.categoriaGasto.tipo.color : corStatus;
    final icone = switch (status) {
      'VENCIDO' => Icons.warning_amber_rounded,
      'PENDENTE' => Icons.schedule_rounded,
      _ => Icons.check_circle_rounded,
    };

    final data = status == 'PAGO' ? gasto.dataPgto : gasto.dataVenc;
    final rotuloData = data == null
        ? '—'
        : '${status == 'PAGO' ? 'Pago' : status == 'VENCIDO' ? 'Venceu' : 'Vence'} '
            '${DateFormat('dd/MM/yyyy').format(data)}';

    final previsto = GastosFixosResumo.previstoDe(gasto);
    final pago = GastosFixosResumo.pagoDe(gasto);

    return InkWell(
      onTap: onTap,
      hoverColor: corIcone.withOpacity(0.04),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: corIcone.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: corIcone, size: 18),
            ),
            Expanded(
              flex: 3,
              child: Text(gasto.descricao,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kWebTexto)),
            ),
            Expanded(
              flex: 2,
              child: Text(gasto.categoriaGasto.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
            SizedBox(
              width: 120,
              child: Text(rotuloData,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ),
            SizedBox(
              width: 100,
              child: Text(fmt.format(previsto),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      decoration: status == 'PAGO' && pago != previsto
                          ? TextDecoration.lineThrough
                          : null)),
            ),
            SizedBox(
              width: 100,
              child: status == 'PAGO'
                  ? Text(fmt.format(pago),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF43A047)))
                  : Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (status == 'PENDENTE' && isPatrimonio
                                  ? corIcone
                                  : corStatus)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(status,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                color: status == 'PENDENTE' && isPatrimonio
                                    ? corIcone
                                    : corStatus)),
                      ),
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
