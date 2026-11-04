import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/features/shared/components/web/web_detalhe_widgets.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/utils/formatters.dart';

const _corCategoria = Color(0xFF8E24AA);

/// Card principal: selos, nome, campos editáveis e observações.
class GastoVariadoWebPrincipal extends StatelessWidget {
  final String descricao;
  final dynamic valor;
  final DateTime? dataPgto;
  final String categoriaNome;
  final TipoCategoriaGasto tipo;
  final String? observacoes;
  final bool isPatrimonio;
  final bool isAtivo;
  final VoidCallback onEditNome;
  final VoidCallback onEditValor;
  final VoidCallback onEditData;
  final VoidCallback onEditCategoria;
  final VoidCallback onEditObservacoes;

  const GastoVariadoWebPrincipal({
    super.key,
    required this.descricao,
    required this.valor,
    required this.dataPgto,
    required this.categoriaNome,
    required this.tipo,
    required this.observacoes,
    required this.isPatrimonio,
    required this.isAtivo,
    required this.onEditNome,
    required this.onEditValor,
    required this.onEditData,
    required this.onEditCategoria,
    required this.onEditObservacoes,
  });

  @override
  Widget build(BuildContext context) {
    final data = dataPgto == null
        ? 'Não informado'
        : DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(dataPgto!);
    final temObs = observacoes != null && observacoes!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              WebSelo(
                  texto: isPatrimonio ? 'Aporte' : 'Gasto variado',
                  cor: _corCategoria),
              WebSelo(
                texto: isAtivo ? 'Orçamento ativo' : 'Orçamento encerrado',
                cor:
                    isAtivo ? const Color(0xFF059669) : const Color(0xFF546E7A),
                ponto: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: isAtivo ? onEditNome : null,
            borderRadius: BorderRadius.circular(8),
            child: Text(
              descricao.toUpperCase(),
              style: const TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w800, color: kWebTexto),
            ),
          ),
          const SizedBox(height: 24),
          WebLinhaDetalhe(
            icon: Icons.attach_money_rounded,
            rotulo: isPatrimonio ? 'Valor guardado' : 'Valor pago',
            valor: Text(formatarValorDynamic(valor),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kWebTexto)),
            onEdit: isAtivo ? onEditValor : null,
            primeira: true,
          ),
          WebLinhaDetalhe(
            icon: Icons.calendar_today_outlined,
            rotulo: isPatrimonio ? 'Data do aporte' : 'Data de pagamento',
            valor: Text(data,
                style: const TextStyle(fontSize: 15, color: kWebTexto)),
            onEdit: isAtivo ? onEditData : null,
          ),
          WebLinhaDetalhe(
            icon: Icons.category_outlined,
            rotulo: 'Categoria',
            valor: WebChipValor(texto: categoriaNome, cor: _corCategoria),
            onEdit: isAtivo ? onEditCategoria : null,
          ),
          WebLinhaDetalhe(
            icon: tipo.icon,
            rotulo: 'Tipo',
            valor: WebChipValor(texto: tipo.label, cor: tipo.color),
            bloqueada: true,
          ),
          const SizedBox(height: 32),
          const Text('Observações',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: kWebTexto)),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isAtivo ? onEditObservacoes : null,
            child: CustomPaint(
              painter: WebBordaTracejada(Colors.grey.shade300),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 140),
                padding: const EdgeInsets.all(24),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF9FE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  temObs
                      ? observacoes!
                      : (isAtivo
                          ? 'Clique para adicionar uma observação sobre este gasto...'
                          : 'Nenhuma observação'),
                  style: TextStyle(
                      fontSize: 14,
                      color: temObs ? kWebTexto : Colors.grey[600]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}




