import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamentos_web_resumo.dart';
import 'package:orcamentos_app/features/budgets/utils/budget_progress.dart';
import 'package:orcamentos_app/features/budgets/utils/orcamentos_aba.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

const _indigo = Color(0xFF1A237E);

/// Tabela de orçamentos com abas (ativos, encerrados, todos).
class OrcamentosWebTable extends StatelessWidget {
  final List<OrcamentoResponseDto> orcamentos;
  final Map<int, ContagemGastos> contagens;
  final OrcamentosAba aba;
  final String ordenadoPor;
  final ValueChanged<OrcamentosAba> onAba;
  final ValueChanged<OrcamentoResponseDto> onAbrir;
  final ValueChanged<OrcamentoResponseDto> onFixos;
  final ValueChanged<OrcamentoResponseDto> onVariados;

  const OrcamentosWebTable({
    super.key,
    required this.orcamentos,
    required this.contagens,
    required this.aba,
    required this.ordenadoPor,
    required this.onAba,
    required this.onAbrir,
    required this.onFixos,
    required this.onVariados,
  });

  @override
  Widget build(BuildContext context) {
    final n = orcamentos.length;

    return Container(
      decoration: webCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _Abas(
              aba: aba, quantidade: n, ordenadoPor: ordenadoPor, onAba: onAba),
          const Divider(height: 1),
          const _CabecalhoColunas(),
          for (final o in orcamentos)
            _Linha(
              orcamento: o,
              contagem: contagens[o.id],
              onAbrir: () => onAbrir(o),
              onFixos: () => onFixos(o),
              onVariados: () => onVariados(o),
            ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Mostrando 1 a $n de $n orçamento${n == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                Text(
                  'Clique no número de fixos ou variados para abrir os lançamentos',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Abas extends StatelessWidget {
  final OrcamentosAba aba;
  final int quantidade;
  final String ordenadoPor;
  final ValueChanged<OrcamentosAba> onAba;

  const _Abas({
    required this.aba,
    required this.quantidade,
    required this.ordenadoPor,
    required this.onAba,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
      child: Row(
        children: [
          for (final a in OrcamentosAba.values)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onAba(a),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: a == aba ? _indigo.withOpacity(0.08) : null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (a == aba && a == OrcamentosAba.ativos) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                              color: Color(0xFF10B981), shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(a.rotulo,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  a == aba ? FontWeight.w700 : FontWeight.w500,
                              color: a == aba ? _indigo : Colors.grey[700])),
                      if (a == aba) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$quantidade',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _indigo)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const Spacer(),
          Text('Ordenado por $ordenadoPor',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
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
    return Container(
      color: const Color(0xFFF8F9FC),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: const [
          Expanded(flex: 4, child: Text('Orçamento', style: _estiloColuna)),
          Expanded(flex: 3, child: Text('Utilização', style: _estiloColuna)),
          SizedBox(
              width: 100,
              child: Text('Orçado',
                  textAlign: TextAlign.right, style: _estiloColuna)),
          SizedBox(
              width: 110,
              child: Text('Saldo',
                  textAlign: TextAlign.right, style: _estiloColuna)),
          SizedBox(
              width: 70,
              child: Text('Fixos',
                  textAlign: TextAlign.center, style: _estiloColuna)),
          SizedBox(
              width: 80,
              child: Text('Variados',
                  textAlign: TextAlign.center, style: _estiloColuna)),
          SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final OrcamentoResponseDto orcamento;
  final ContagemGastos? contagem;
  final VoidCallback onAbrir;
  final VoidCallback onFixos;
  final VoidCallback onVariados;

  const _Linha({
    required this.orcamento,
    required this.contagem,
    required this.onAbrir,
    required this.onFixos,
    required this.onVariados,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final orcado = OrcamentosResumo.orcadoDe(orcamento);
    final saldo = OrcamentosResumo.saldoDe(orcamento);
    final livre = OrcamentosResumo.livreDe(orcamento);
    final utilizado = OrcamentosResumo.utilizadoDe(orcamento);
    final progresso =
        calculateBudgetProgress(valorInicial: orcado, valorAtual: saldo);
    final corProgresso = getBudgetProgressColor(progresso);
    final mes = toBeginningOfSentenceCase(
        DateFormat("MMMM (yyyy)", 'pt_BR').format(orcamento.dataCriacao));

    return InkWell(
      onTap: onAbrir,
      hoverColor: _indigo.withOpacity(0.03),
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: _indigo.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        color: _indigo, size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(orcamento.nome.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kWebTexto)),
                        const SizedBox(height: 2),
                        Text(
                          '$mes · criado em '
                          '${DateFormat('dd/MM/yyyy').format(orcamento.dataCriacao)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progresso,
                        minHeight: 7,
                        color: corProgresso,
                        backgroundColor: corProgresso.withOpacity(0.15),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${(progresso * 100).toStringAsFixed(1).replaceAll('.', ',')}%'
                      ' · ${fmt.format(utilizado)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Text(fmt.format(orcado),
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, color: Colors.grey[800])),
            ),
            SizedBox(
              width: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(fmt.format(saldo),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF047857))),
                  Text('livre ${fmt.format(livre)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ),
            SizedBox(
              width: 70,
              child: Center(
                child: _Contador(
                    valor: contagem?.fixos,
                    destaque: (contagem?.fixos ?? 0) > 0,
                    onTap: onFixos),
              ),
            ),
            SizedBox(
              width: 80,
              child: Center(
                child: _Contador(
                    valor: contagem?.variados,
                    destaque: (contagem?.variados ?? 0) > 0,
                    onTap: onVariados),
              ),
            ),
            SizedBox(
              width: 40,
              child: PopupMenuButton<String>(
                tooltip: 'Mais opções',
                icon: Icon(Icons.more_vert_rounded,
                    size: 18, color: Colors.grey[600]),
                onSelected: (_) => onAbrir(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'abrir', child: Text('Ver detalhes')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botão numérico que abre a lista de lançamentos.
class _Contador extends StatelessWidget {
  final int? valor;
  final bool destaque;
  final VoidCallback onTap;

  const _Contador({
    required this.valor,
    required this.destaque,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: destaque ? _indigo.withOpacity(0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: valor == null
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Text('$valor',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: destaque ? _indigo : Colors.grey[600])),
      ),
    );
  }
}
