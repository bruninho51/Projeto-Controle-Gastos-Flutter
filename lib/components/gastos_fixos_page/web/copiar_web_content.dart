import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/copiar_gastos_fixos_service.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/copiar_web_gastos.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/copiar_web_origem.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:provider/provider.dart';

/// Tela web de cópia de gastos fixos: escolha da origem e seleção dos gastos
/// lado a lado, com o total a copiar no rodapé.
class CopiarWebContent extends StatefulWidget {
  final List<WebCrumb> breadcrumb;
  final String destinoNome;
  final int destinoId;
  final List<OrcamentoResponseDto> orcamentos;
  final VoidCallback onBack;

  /// Chamado com `true` quando a cópia terminou (para recarregar a lista).
  final ValueChanged<bool> onConcluido;

  const CopiarWebContent({
    super.key,
    required this.breadcrumb,
    required this.destinoNome,
    required this.destinoId,
    required this.orcamentos,
    required this.onBack,
    required this.onConcluido,
  });

  @override
  State<CopiarWebContent> createState() => _CopiarWebContentState();
}

class _CopiarWebContentState extends State<CopiarWebContent> {
  OrcamentoResponseDto? _origem;
  List<GastoFixoResponseDto> _gastos = [];
  final Set<int> _selecionados = {};
  bool _carregando = false;
  bool _processando = false;
  Object? _erro;

  ApiService get _api => Provider.of<ApiService>(context, listen: false);

  Future<void> _selecionarOrigem(OrcamentoResponseDto o) async {
    if (o.id == _origem?.id) return;
    setState(() {
      _origem = o;
      _gastos = [];
      _selecionados.clear();
      _carregando = true;
      _erro = null;
    });
    try {
      final gastos = await _api.getGastosFixos(orcamentoId: o.id);
      // Ignora a resposta se outro orçamento foi escolhido enquanto carregava.
      if (!mounted || _origem?.id != o.id) return;
      setState(() {
        _gastos = gastos;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted || _origem?.id != o.id) return;
      setState(() {
        _erro = e;
        _carregando = false;
      });
    }
  }

  void _alternar(GastoFixoResponseDto g) => setState(() {
        if (!_selecionados.remove(g.id)) _selecionados.add(g.id);
      });

  void _alternarTodos() => setState(() {
        if (_selecionados.length == _gastos.length) {
          _selecionados.clear();
        } else {
          _selecionados.addAll(_gastos.map((g) => g.id));
        }
      });

  Future<void> _copiar() async {
    setState(() => _processando = true);
    final escolhidos =
        _gastos.where((g) => _selecionados.contains(g.id)).toList();
    try {
      final erros = await copiarGastosFixos(_api, widget.destinoId, escolhidos);
      if (!mounted) return;
      if (erros == 0) {
        final n = escolhidos.length;
        OrcamentosSnackBar.success(
            context: context,
            message:
                '$n gasto${n == 1 ? '' : 's'} copiado${n == 1 ? '' : 's'} com sucesso!');
      } else {
        OrcamentosSnackBar.error(
            context: context,
            message: '$erros gasto(s) não puderam ser copiados.');
      }
      widget.onConcluido(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processando = false);
      OrcamentosSnackBar.error(
          context: context, message: 'Erro ao copiar gastos: $e');
    }
  }

  /// Largura mínima para exibir os dois painéis lado a lado.
  static const double _larguraDuasColunas = 900;

  @override
  Widget build(BuildContext context) {
    final origem = CopiarWebOrigem(
      orcamentos: widget.orcamentos,
      selecionadoId: _origem?.id,
      onSelecionar: _selecionarOrigem,
    );
    final gastos = CopiarWebGastos(
      origem: _origem,
      carregando: _carregando,
      processando: _processando,
      erro: _erro,
      gastos: _gastos,
      selecionados: _selecionados,
      onAlternar: _alternar,
      onAlternarTodos: _alternarTodos,
      onCancelar: widget.onBack,
      onCopiar: _copiar,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebBreadcrumb(itens: widget.breadcrumb),
          const SizedBox(height: 14),
          Row(
            children: [
              WebBackButton(onTap: widget.onBack),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Copiar gastos fixos',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kWebTexto)),
                    SizedBox(height: 2),
                    Text(
                        'Escolha o orçamento de origem e marque os gastos que deseja copiar',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Text.rich(
                    TextSpan(children: [
                      TextSpan(
                          text: 'Copiar para  ',
                          style: TextStyle(color: Colors.grey[600])),
                      TextSpan(
                          text: widget.destinoNome,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, color: kWebTexto)),
                    ]),
                    style: const TextStyle(fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              if (c.maxWidth < _larguraDuasColunas) {
                return Column(children: [
                  Expanded(child: origem),
                  const SizedBox(height: 16),
                  Expanded(flex: 2, child: gastos),
                ]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 4, child: origem),
                  const SizedBox(width: 20),
                  Expanded(flex: 7, child: gastos),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
