import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/features/shared/components/confirmation_dialog.dart';

import 'package:orcamentos_app/features/notifications/regex_patterns/models/padrao_regex_notificacao.dart';
import 'package:orcamentos_app/features/notifications/regex_patterns/repositories/padrao_regex_notificacao_repository.dart';

class RegexPatternsPage extends StatefulWidget {
  const RegexPatternsPage({super.key});

  @override
  State<RegexPatternsPage> createState() => _RegexPatternsPageState();
}

class _RegexPatternsPageState extends State<RegexPatternsPage>
    with SingleTickerProviderStateMixin {
  late Future<List<PadraoRegexNotificacao>> _future;
  late AnimationController _syncCtrl;
  bool _isSyncing = false;

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  PadraoRegexNotificacaoRepository get _repo =>
      Provider.of<PadraoRegexNotificacaoRepository>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _syncCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _future = _repo.getAllLocal();
  }

  @override
  void dispose() {
    _syncCtrl.dispose();
    super.dispose();
  }

  Future<void> _sincronizar() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    _syncCtrl.repeat();

    try {
      final atualizados = await _repo.sincronizar();
      if (mounted) {
        setState(() {
          _future = Future.value(atualizados);
        });
        OrcamentosSnackBar.success(
          context: context,
          message: 'Padrões sincronizados!',
        );
      }
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(
          context: context,
          message: 'Erro ao sincronizar: $e',
        );
      }
    } finally {
      _syncCtrl.stop();
      _syncCtrl.reset();
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _apagar(PadraoRegexNotificacao padrao) async {
    final confirmar = await ConfirmationDialog.show(
      context: context,
      title: 'Apagar padrão?',
      message:
          'O padrão de "${padrao.instituicaoFinanceira} · ${padrao.tituloNotificacao}" será removido do cache local.',
      confirmText: 'Apagar',
      cancelText: 'Cancelar',
    );
    if (confirmar != true) return;

    try {
      await _repo.deletePadrao(padrao.id!);
      if (mounted) {
        setState(() {
          _future = _repo.getAllLocal();
        });
        OrcamentosSnackBar.success(context: context, message: 'Padrão apagado.');
      }
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(context: context, message: 'Erro ao apagar: $e');
      }
    }
  }

  Future<void> _limparTudo() async {
    final confirmar = await ConfirmationDialog.show(
      context: context,
      title: 'Limpar todos os padrões?',
      message:
          'Todos os padrões de regex salvos localmente serão removidos. Eles serão gerados novamente quando necessário.',
      confirmText: 'Limpar tudo',
      cancelText: 'Cancelar',
    );
    if (confirmar != true) return;

    try {
      await _repo.limparTudo();
      if (mounted) {
        setState(() {
          _future = Future.value(const []);
        });
        OrcamentosSnackBar.success(
          context: context,
          message: 'Padrões removidos.',
        );
      }
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(context: context, message: 'Erro ao limpar: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          SharedAppBar(
            title: 'Padrões Regex',
            subtitle: 'Cache local de notificações',
            mainIcon: Icons.pattern_rounded,
            gradientColors: _gradientColors,
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
            showAvatar: false,
            actionButtons: [
              SharedAppBar.headerButton(
                onTap: _limparTudo,
                tooltip: 'Limpar tudo',
                isSquare: true,
                child: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              SharedAppBar.headerButton(
                onTap: _sincronizar,
                tooltip: 'Sincronizar',
                isSquare: true,
                child: RotationTransition(
                  turns: _syncCtrl,
                  child: Icon(
                    Icons.sync_rounded,
                    color: Colors.white.withValues(alpha: _isSyncing ? 1.0 : 0.9),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<PadraoRegexNotificacao>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return Center(
                    child: OrcamentosLoading(message: 'Carregando padrões...'),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Erro ao carregar: ${snapshot.error}',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final lista = snapshot.data ?? [];
                if (lista.isEmpty) {
                  return const _RegexPatternsEmptyState();
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final padrao = lista[index];
                    return _PadraoRegexTile(
                      padrao: padrao,
                      onDelete: () => _apagar(padrao),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Item da lista
// ═══════════════════════════════════════════════════════════════════════════════
class _PadraoRegexTile extends StatelessWidget {
  final PadraoRegexNotificacao padrao;
  final VoidCallback onDelete;

  const _PadraoRegexTile({required this.padrao, required this.onDelete});

  static final _dateFmt = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

  @override
  Widget build(BuildContext context) {
    final expirado = padrao.expirado;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      padrao.instituicaoFinanceira,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F36),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      padrao.tituloNotificacao,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: 'Apagar',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              padrao.regex,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF1A1F36),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                expirado ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                size: 14,
                color: expirado ? Colors.orange : Colors.grey[400],
              ),
              const SizedBox(width: 4),
              Text(
                expirado
                    ? 'Expirado em ${_dateFmt.format(padrao.dataExpiracao.toLocal())}'
                    : 'Expira em ${_dateFmt.format(padrao.dataExpiracao.toLocal())}',
                style: TextStyle(
                  fontSize: 11,
                  color: expirado ? Colors.orange : Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Estado vazio
// ═══════════════════════════════════════════════════════════════════════════════
class _RegexPatternsEmptyState extends StatelessWidget {
  const _RegexPatternsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF3949AB).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pattern_rounded,
                size: 34,
                color: Color(0xFF3949AB),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhum padrão salvo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Sincronize para baixar os padrões de regex usados na leitura das notificações bancárias.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
