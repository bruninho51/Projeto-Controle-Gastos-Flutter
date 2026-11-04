import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Painel 1: lista de orçamentos de onde copiar os gastos.
class CopiarWebOrigem extends StatelessWidget {
  final List<OrcamentoResponseDto> orcamentos;
  final int? selecionadoId;
  final ValueChanged<OrcamentoResponseDto> onSelecionar;

  const CopiarWebOrigem({
    super.key,
    required this.orcamentos,
    required this.selecionadoId,
    required this.onSelecionar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CopiarWebPasso(
              numero: 1,
              titulo: 'Orçamento de origem',
              subtitulo: 'De qual orçamento copiar'),
          const SizedBox(height: 18),
          Expanded(
            child: orcamentos.isEmpty
                ? Center(
                    child: Text('Nenhum outro orçamento encontrado',
                        style: TextStyle(color: Colors.grey[600])))
                : ListView.separated(
                    itemCount: orcamentos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _Item(
                      orcamento: orcamentos[i],
                      selecionado: orcamentos[i].id == selecionadoId,
                      onTap: () => onSelecionar(orcamentos[i]),
                    ),
                  ),
          ),
          if (orcamentos.length > 6) ...[
            const SizedBox(height: 10),
            Center(
              child: Text('Role para ver orçamentos mais antigos',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ),
          ],
        ],
      ),
    );
  }
}

/// Cabeçalho numerado de um passo (círculo com o número, título e subtítulo).
class CopiarWebPasso extends StatelessWidget {
  final int numero;
  final String titulo;
  final String? subtitulo;

  const CopiarWebPasso({
    super.key,
    required this.numero,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration:
                const BoxDecoration(color: kIndigo, shape: BoxShape.circle),
            child: Text('$numero',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(titulo,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kWebTexto)),
          ),
        ]),
        if (subtitulo != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(subtitulo!,
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ),
        ],
      ],
    );
  }
}

class _Item extends StatelessWidget {
  final OrcamentoResponseDto orcamento;
  final bool selecionado;
  final VoidCallback onTap;

  const _Item({
    required this.orcamento,
    required this.selecionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final encerrado = orcamento.dataEncerramento != null;
    final corStatus =
        encerrado ? const Color(0xFF546E7A) : const Color(0xFF059669);
    final valor = double.tryParse(orcamento.valorAtual) ?? 0;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
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
              color: kIndigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: kIndigo, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orcamento.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: kWebTexto)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: corStatus.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(encerrado ? 'Encerrado' : 'Ativo',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: corStatus)),
                  ),
                  const SizedBox(width: 10),
                  Text(fmt.format(valor),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
