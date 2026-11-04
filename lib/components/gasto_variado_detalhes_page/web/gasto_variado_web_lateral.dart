import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/shared/components/web/web_detalhe_widgets.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/utils/formatters.dart';

/// Coluna lateral: valor em destaque e ações (atualizar e excluir).
class GastoVariadoWebLateral extends StatelessWidget {
  final dynamic valor;
  final DateTime? dataPgto;
  final bool isPatrimonio;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;

  /// Nulo quando o orçamento está encerrado (não permite excluir).
  final VoidCallback? onDelete;

  const GastoVariadoWebLateral({
    super.key,
    required this.valor,
    required this.dataPgto,
    required this.isPatrimonio,
    required this.refreshCtrl,
    required this.onRefresh,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = dataPgto == null
        ? 'Não informado'
        : DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR').format(dataPgto!);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B3FD6)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isPatrimonio ? 'Valor guardado' : 'Valor pago',
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
              const SizedBox(height: 18),
              Row(children: [
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: Colors.white.withOpacity(0.85)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(data,
                      style: TextStyle(
                          fontSize: 14, color: Colors.white.withOpacity(0.9))),
                ),
              ]),
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

