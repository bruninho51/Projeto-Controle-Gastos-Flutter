import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/gastos_fixos_resumo.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/gastos_fixos_web_sidebar.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/gastos_fixos_web_stats.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/gastos_fixos_web_table.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Corpo da versão web: cards + tabela à esquerda e painel lateral à direita.
class GastosFixosWebContent extends StatelessWidget {
  final List<GastoFixoResponseDto> filtrados;
  final List<CategoriaGastoResponseDto> categorias;
  final String? status;
  final int? categoriaId;
  final DateTime? data;
  final ValueChanged<String?> onStatus;
  final ValueChanged<int?> onCategoria;
  final ValueChanged<DateTime?> onData;
  final VoidCallback onLimpar;
  final Future<void> Function(GastoFixoResponseDto) onTapItem;

  const GastosFixosWebContent({
    super.key,
    required this.filtrados,
    required this.categorias,
    required this.status,
    required this.categoriaId,
    required this.data,
    required this.onStatus,
    required this.onCategoria,
    required this.onData,
    required this.onLimpar,
    required this.onTapItem,
  });

  /// Largura mínima disponível para exibir o painel lateral.
  static const double larguraMinimaSidebar = 1000;
  static const double _larguraSidebar = 300;

  @override
  Widget build(BuildContext context) {
    final resumo = GastosFixosResumo.de(filtrados);

    final principal = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
      child: Column(
        children: [
          GastosFixosWebStats(resumo: resumo),
          const SizedBox(height: 20),
          GastosFixosWebTable(gastos: filtrados, onTapItem: onTapItem),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < larguraMinimaSidebar) return principal;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: principal),
          SizedBox(
            width: _larguraSidebar,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 12, 28, 32),
              child: GastosFixosWebSidebar(
                resumo: resumo,
                categorias: categorias,
                status: status,
                categoriaId: categoriaId,
                data: data,
                onStatus: onStatus,
                onCategoria: onCategoria,
                onData: onData,
                onLimpar: onLimpar,
              ),
            ),
          ),
        ],
      );
    });
  }
}
