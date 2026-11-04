import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/features/shared/components/web/web_detalhe_widgets.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/utils/formatters.dart';

const _corCategoria = Color(0xFF5E35B1);
const _corPago = Color(0xFF059669);
const _corVencido = Color(0xFFE53935);
const _corPendente = Color(0xFFF4511E);

/// Card principal do gasto fixo: selos, nome, campos editáveis e observações.
class GastoFixoWebPrincipal extends StatelessWidget {
  final GastoFixoResponseDto gasto;
  final bool isPago;
  final bool isVencido;
  final bool isPatrimonio;
  final bool isAtivo;
  final VoidCallback onEditNome;
  final VoidCallback onEditPrevisto;
  final VoidCallback onEditPago;
  final VoidCallback onEditDataPgto;
  final VoidCallback onEditVencimento;
  final VoidCallback onEditCategoria;
  final VoidCallback onEditObservacoes;

  const GastoFixoWebPrincipal({
    super.key,
    required this.gasto,
    required this.isPago,
    required this.isVencido,
    required this.isPatrimonio,
    required this.isAtivo,
    required this.onEditNome,
    required this.onEditPrevisto,
    required this.onEditPago,
    required this.onEditDataPgto,
    required this.onEditVencimento,
    required this.onEditCategoria,
    required this.onEditObservacoes,
  });

  static String _data(DateTime? d) => d == null
      ? 'Não informado'
      : DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(d);

  @override
  Widget build(BuildContext context) {
    final tipo = gasto.categoriaGasto.tipo;
    final obs = gasto.observacoes;
    final temObs = obs != null && obs.trim().isNotEmpty;
    final statusTexto = isPago ? 'Pago' : (isVencido ? 'Vencido' : 'Pendente');
    final statusCor =
        isPago ? _corPago : (isVencido ? _corVencido : _corPendente);

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
                  texto: isPatrimonio ? 'Aporte' : 'Gasto fixo',
                  cor: _corCategoria),
              WebSelo(texto: statusTexto, cor: statusCor, ponto: true),
              WebSelo(
                texto: isAtivo ? 'Orçamento ativo' : 'Orçamento encerrado',
                cor:
                    isAtivo ? const Color(0xFF059669) : const Color(0xFF546E7A),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: isAtivo ? onEditNome : null,
            borderRadius: BorderRadius.circular(8),
            child: Text(
              gasto.descricao.toUpperCase(),
              style: const TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w800, color: kWebTexto),
            ),
          ),
          const SizedBox(height: 24),
          WebLinhaDetalhe(
            icon: Icons.attach_money_rounded,
            rotulo: 'Valor previsto',
            valor: Text(formatarValorDynamic(gasto.previsto),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kWebTexto)),
            onEdit: isAtivo ? onEditPrevisto : null,
            primeira: true,
          ),
          WebLinhaDetalhe(
            icon: isPago
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            rotulo: isPatrimonio ? 'Valor guardado' : 'Valor pago',
            valor: Text(
              isPago
                  ? formatarValorDynamic(gasto.valor!)
                  : (isPatrimonio ? 'Não guardado' : 'Não pago'),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: isPago ? FontWeight.w700 : FontWeight.w400,
                  color: isPago ? _corPago : Colors.grey[600]),
            ),
            onEdit: isPago && isAtivo ? onEditPago : null,
          ),
          if (isPago)
            WebLinhaDetalhe(
              icon: Icons.calendar_today_outlined,
              rotulo: isPatrimonio ? 'Data do aporte' : 'Data de pagamento',
              valor: Text(_data(gasto.dataPgto),
                  style: const TextStyle(fontSize: 15, color: kWebTexto)),
              onEdit: isAtivo ? onEditDataPgto : null,
            ),
          if (gasto.diferenca != null)
            WebLinhaDetalhe(
              icon: Icons.compare_arrows_rounded,
              rotulo: 'Diferença',
              valor: Text(formatarValorDynamic(gasto.diferenca!),
                  style: const TextStyle(fontSize: 15, color: kWebTexto)),
              bloqueada: true,
            ),
          WebLinhaDetalhe(
            icon: Icons.event_outlined,
            rotulo: 'Vencimento',
            valor: Row(children: [
              Text(_data(gasto.dataVenc),
                  style: const TextStyle(fontSize: 15, color: kWebTexto)),
              if (isVencido) ...[
                const SizedBox(width: 10),
                const WebSelo(texto: 'Vencido', cor: _corVencido),
              ],
            ]),
            onEdit: isAtivo ? onEditVencimento : null,
          ),
          WebLinhaDetalhe(
            icon: Icons.category_outlined,
            rotulo: 'Categoria',
            valor: WebChipValor(
                texto: gasto.categoriaGasto.nome, cor: _corCategoria),
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
                      ? obs
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
