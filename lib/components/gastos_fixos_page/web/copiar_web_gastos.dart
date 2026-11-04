import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/copiar_web_origem.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/utils/formatters.dart';

/// Painel 2: gastos fixos do orçamento de origem, com seleção e rodapé de ação.
class CopiarWebGastos extends StatelessWidget {
  /// Nulo enquanto nenhum orçamento de origem foi escolhido.
  final OrcamentoResponseDto? origem;
  final bool carregando;
  final bool processando;
  final Object? erro;
  final List<GastoFixoResponseDto> gastos;
  final Set<int> selecionados;
  final ValueChanged<GastoFixoResponseDto> onAlternar;
  final VoidCallback onAlternarTodos;
  final VoidCallback onCancelar;
  final VoidCallback onCopiar;

  const CopiarWebGastos({
    super.key,
    required this.origem,
    required this.carregando,
    required this.processando,
    required this.erro,
    required this.gastos,
    required this.selecionados,
    required this.onAlternar,
    required this.onAlternarTodos,
    required this.onCancelar,
    required this.onCopiar,
  });

  double get _total => gastos
      .where((g) => selecionados.contains(g.id))
      .fold<double>(0, (s, g) => s + (double.tryParse(g.previsto) ?? 0));

  @override
  Widget build(BuildContext context) {
    final todos = gastos.isNotEmpty && selecionados.length == gastos.length;

    return Container(
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CopiarWebPasso(
                    numero: 2,
                    titulo: origem == null
                        ? 'Gastos fixos'
                        : 'Gastos fixos de ${origem!.nome}',
                  ),
                ),
                if (gastos.isNotEmpty)
                  OutlinedButton(
                    onPressed: onAlternarTodos,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kIndigo,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(todos ? 'Limpar seleção' : 'Selecionar todos',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          if (gastos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(66, 4, 24, 0),
              child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: '${selecionados.length}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, color: kWebTexto)),
                    TextSpan(text: ' de ${gastos.length} selecionados'),
                  ]),
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ),
          const SizedBox(height: 14),
          Expanded(child: _corpo()),
          _Rodape(
            total: _total,
            quantidade: selecionados.length,
            processando: processando,
            onCancelar: onCancelar,
            onCopiar: onCopiar,
          ),
        ],
      ),
    );
  }

  Widget _corpo() {
    if (origem == null) {
      return const _Mensagem(
          icone: Icons.touch_app_outlined,
          texto: 'Escolha um orçamento de origem ao lado');
    }
    if (carregando) {
      return Center(child: OrcamentosLoading(message: 'Carregando gastos...'));
    }
    if (erro != null) {
      return _Mensagem(
          icone: Icons.error_outline_rounded,
          texto: 'Erro ao carregar os gastos: $erro');
    }
    if (gastos.isEmpty) {
      return const _Mensagem(
          icone: Icons.receipt_long_outlined,
          texto: 'Este orçamento não possui gastos fixos');
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: gastos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _Linha(
        gasto: gastos[i],
        selecionado: selecionados.contains(gastos[i].id),
        onTap: () => onAlternar(gastos[i]),
      ),
    );
  }
}

class _Mensagem extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _Mensagem({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 44, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text(texto, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ]),
    );
  }
}

class _Linha extends StatelessWidget {
  final GastoFixoResponseDto gasto;
  final bool selecionado;
  final VoidCallback onTap;

  const _Linha({
    required this.gasto,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = gasto.categoriaGasto.tipo;
    final cor = tipo == TipoCategoriaGasto.patrimonio
        ? tipo.color
        : const Color(0xFF5E35B1);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selecionado ? kIndigo.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? kIndigo : Colors.grey.shade200,
            width: selecionado ? 1.8 : 1,
          ),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_outlined, color: cor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gasto.descricao.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kWebTexto)),
                const SizedBox(height: 2),
                Text(gasto.categoriaGasto.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(formatarValorDynamic(gasto.previsto),
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: kWebTexto)),
        ]),
      ),
    );
  }
}

class _Rodape extends StatelessWidget {
  final double total;
  final int quantidade;
  final bool processando;
  final VoidCallback onCancelar;
  final VoidCallback onCopiar;

  const _Rodape({
    required this.total,
    required this.quantidade,
    required this.processando,
    required this.onCancelar,
    required this.onCopiar,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total a copiar',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text.rich(TextSpan(children: [
                  TextSpan(
                      text: fmt.format(total),
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: kWebTexto)),
                  TextSpan(
                      text: '  ·  $quantidade '
                          '${quantidade == 1 ? 'gasto' : 'gastos'}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ])),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: processando ? null : onCancelar,
            style: OutlinedButton.styleFrom(
              foregroundColor: kWebTexto,
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade300),
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancelar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: quantidade == 0 || processando ? null : onCopiar,
            icon: processando
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.copy_all_rounded, size: 18),
            label: Text(
                'Copiar $quantidade ${quantidade == 1 ? 'gasto' : 'gastos'}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kIndigo,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
