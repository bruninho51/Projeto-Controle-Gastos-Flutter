import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/shared/components/web/web_detalhe_widgets.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/utils/formatters.dart';

/// Coluna lateral do gasto fixo: valor em destaque e ações.
class GastoFixoWebLateral extends StatelessWidget {
  final GastoFixoResponseDto gasto;
  final bool isPago;
  final bool isPatrimonio;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;

  /// Nulo quando não é possível registrar (já pago ou orçamento encerrado).
  final VoidCallback? onRegistrar;

  /// Nulo quando o orçamento está encerrado (não permite excluir).
  final VoidCallback? onDelete;

  const GastoFixoWebLateral({
    super.key,
    required this.gasto,
    required this.isPago,
    required this.isPatrimonio,
    required this.refreshCtrl,
    required this.onRefresh,
    this.onRegistrar,
    this.onDelete,
  });

  static String _data(DateTime? d) => d == null
      ? 'Não informado'
      : DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(d);

  @override
  Widget build(BuildContext context) {
    final titulo = isPago
        ? (isPatrimonio ? 'Valor guardado' : 'Valor pago')
        : 'Valor previsto';
    final valor = isPago ? gasto.valor! : gasto.previsto;
    final linhas = <(String, String)>[
      if (isPago) ('Pago em', _data(gasto.dataPgto)),
      ('Vencimento', _data(gasto.dataVenc)),
      if (isPago) ('Previsto', formatarValorDynamic(gasto.previsto)),
    ];

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: TextStyle(
                      fontSize: 14, color: Colors.white.withOpacity(0.8))),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(formatarValorDynamic(valor),
                    style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Divider(color: Colors.white.withOpacity(0.2), height: 1),
              const SizedBox(height: 14),
              for (final (rotulo, texto) in linhas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Expanded(
                      child: Text(rotulo,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.7))),
                    ),
                    Text(texto,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.95))),
                  ]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: webCardDecoration(),
          child: Column(
            children: [
              if (onRegistrar != null)
                WebAcaoDetalhe(
                  onTap: onRegistrar!,
                  cor: const Color(0xFF059669),
                  label:
                      isPatrimonio ? 'Registrar aporte' : 'Registrar pagamento',
                  icone: const Icon(Icons.payments_outlined,
                      size: 18, color: Color(0xFF059669)),
                ),
              WebAcaoDetalhe(
                onTap: onRefresh,
                cor: kWebTexto,
                label: 'Atualizar',
                icone: RotationTransition(
                  turns: refreshCtrl,
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: kWebTexto),
                ),
              ),
              if (onDelete != null)
                WebAcaoDetalhe(
                  onTap: onDelete!,
                  cor: const Color(0xFFC62828),
                  label: isPatrimonio ? 'Excluir aporte' : 'Excluir gasto',
                  icone: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: Color(0xFFC62828)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
