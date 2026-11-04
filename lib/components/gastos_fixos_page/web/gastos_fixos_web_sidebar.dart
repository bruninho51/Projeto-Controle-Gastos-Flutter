import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/gasto_fixo_status.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/gastos_fixos_resumo.dart';
import 'package:orcamentos_app/features/shared/components/web/web_categorias_card.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Painel lateral: resumo, gráfico por categoria e filtros rápidos.
class GastosFixosWebSidebar extends StatelessWidget {
  final GastosFixosResumo resumo;
  final List<CategoriaGastoResponseDto> categorias;
  final String? status;
  final int? categoriaId;
  final DateTime? data;
  final ValueChanged<String?> onStatus;
  final ValueChanged<int?> onCategoria;
  final ValueChanged<DateTime?> onData;
  final VoidCallback onLimpar;

  const GastosFixosWebSidebar({
    super.key,
    required this.resumo,
    required this.categorias,
    required this.status,
    required this.categoriaId,
    required this.data,
    required this.onStatus,
    required this.onCategoria,
    required this.onData,
    required this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ResumoCard(resumo: resumo),
        const SizedBox(height: 16),
        WebCategoriasCard(
            porCategoria: resumo.porCategoria, total: resumo.previsto),
        const SizedBox(height: 16),
        _FiltrosRapidosCard(
          categorias: categorias,
          status: status,
          categoriaId: categoriaId,
          data: data,
          onStatus: onStatus,
          onCategoria: onCategoria,
          onData: onData,
          onLimpar: onLimpar,
        ),
      ],
    );
  }
}

class _ResumoCard extends StatelessWidget {
  final GastosFixosResumo resumo;
  const _ResumoCard({required this.resumo});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    Widget linha(String rotulo, double valor, Color cor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                  child: Text(rotulo,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
              Text(fmt.format(valor),
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: cor)),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebTitulo('Resumo do mês'),
          const SizedBox(height: 10),
          linha('Previsto', resumo.previsto, kWebTexto),
          linha('Pago', resumo.pago, const Color(0xFF43A047)),
          linha('A pagar', resumo.aPagar, const Color(0xFFF4511E)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: resumo.progresso,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF43A047),
            ),
          ),
          const SizedBox(height: 6),
          Text('${(resumo.progresso * 100).round()}% pago',
              style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _FiltrosRapidosCard extends StatelessWidget {
  final List<CategoriaGastoResponseDto> categorias;
  final String? status;
  final int? categoriaId;
  final DateTime? data;
  final ValueChanged<String?> onStatus;
  final ValueChanged<int?> onCategoria;
  final ValueChanged<DateTime?> onData;
  final VoidCallback onLimpar;

  const _FiltrosRapidosCard({
    required this.categorias,
    required this.status,
    required this.categoriaId,
    required this.data,
    required this.onStatus,
    required this.onCategoria,
    required this.onData,
    required this.onLimpar,
  });

  static const _indigo = Color(0xFF1A237E);

  @override
  Widget build(BuildContext context) {
    final rotulo = TextStyle(fontSize: 12, color: Colors.grey[600]);
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final decoracao = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: borda,
      enabledBorder: borda,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebTitulo('Filtros rápidos'),
          const SizedBox(height: 14),
          Text('Status', style: rotulo),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in const ['PAGO', 'PENDENTE', 'VENCIDO'])
                ChoiceChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  selected: status == s,
                  selectedColor: corDoStatusFixo(s).withOpacity(0.15),
                  labelStyle: TextStyle(
                      color:
                          status == s ? corDoStatusFixo(s) : Colors.grey[600],
                      fontWeight: FontWeight.w600),
                  showCheckmark: false,
                  onSelected: (sel) => onStatus(sel ? s : null),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Categoria', style: rotulo),
          const SizedBox(height: 6),
          DropdownButtonFormField<int?>(
            value: categoriaId,
            isExpanded: true,
            decoration: decoracao,
            style: const TextStyle(fontSize: 13, color: kWebTexto),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todas')),
              ...categorias.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.nome, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: onCategoria,
          ),
          const SizedBox(height: 14),
          Text('Data', style: rotulo),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: data ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) onData(picked);
            },
            child: InputDecorator(
              decoration: decoracao.copyWith(
                suffixIconConstraints: const BoxConstraints(),
                suffixIcon: data == null
                    ? const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.calendar_today_rounded, size: 16),
                      )
                    : IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close_rounded, size: 16),
                        onPressed: () => onData(null),
                      ),
              ),
              child: Text(
                data == null ? 'Todas' : DateFormat('dd/MM/yyyy').format(data!),
                style: const TextStyle(fontSize: 13, color: kWebTexto),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onLimpar,
              style: OutlinedButton.styleFrom(
                foregroundColor: _indigo,
                side: const BorderSide(color: _indigo),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Limpar filtros'),
            ),
          ),
        ],
      ),
    );
  }
}
