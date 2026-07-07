import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/features/shared/components/confirmation_dialog.dart';

import 'package:orcamentos_app/features/notifications/models/notification_model.dart';
import 'package:orcamentos_app/features/notifications/notifications_channel.dart';
import 'package:orcamentos_app/features/notifications/services/notification_processing_service.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';

class NotificationEditPage extends StatefulWidget {
  final NotificacaoBancariaModel notificacao;
  final String apiToken;

  const NotificationEditPage({
    super.key,
    required this.notificacao,
    required this.apiToken,
  });

  @override
  State<NotificationEditPage> createState() => _NotificationEditPageState();
}

class _NotificationEditPageState extends State<NotificationEditPage> {
  late TextEditingController _valorCtrl;
  late TextEditingController _descNormalizadaCtrl;
  bool _isSaving = false;
  bool _isRetrying = false;
  late bool _erroProcessamento;

  static const _blue = Color(0xFF3949AB);
  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFmt = DateFormat("d 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR');

  @override
  void initState() {
    super.initState();
    _valorCtrl = TextEditingController(
      text: _fmt.format(widget.notificacao.valor),
    );
    _descNormalizadaCtrl = TextEditingController(
      text: widget.notificacao.descricaoNormalizada ?? '',
    );
    _erroProcessamento = widget.notificacao.erroProcessamento;
    _carregarDescricaoSalva();
  }

  Future<void> _carregarDescricaoSalva() async {
    try {
      final mapeamento = await NotificationsChannel.buscarMapeamento(
        widget.notificacao.descricaoOriginal,
      );

      if (mapeamento != null &&
          mapeamento.descricaoNormalizada.isNotEmpty &&
          mapeamento.descricaoNormalizada !=
              widget.notificacao.descricaoOriginal &&
          mounted) {
        setState(() {
          _descNormalizadaCtrl.text = mapeamento.descricaoNormalizada;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descNormalizadaCtrl.dispose();
    super.dispose();
  }

  String _formatarValor(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final numeric = (double.tryParse(digits) ?? 0) / 100;
    return _fmt.format(numeric);
  }

  String get _descricaoEfetiva {
    final digitado = _descNormalizadaCtrl.text.trim();
    if (digitado.isNotEmpty) return digitado;

    final salvo = widget.notificacao.descricaoNormalizada;
    if (salvo != null && salvo.isNotEmpty) return salvo;

    return widget.notificacao.descricaoOriginal;
  }

  double _parsedValor() {
    return double.tryParse(
          _valorCtrl.text
              .replaceAll('R\$', '')
              .trim()
              .replaceAll('.', '')
              .replaceAll(',', '.'),
        ) ??
        widget.notificacao.valor;
  }

  Future<void> _salvar() async {
    final desc = _descNormalizadaCtrl.text.trim();

    if (desc.isEmpty) {
      OrcamentosSnackBar.error(
        context: context,
        message: 'Informe uma descrição normalizada.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await NotificationsChannel.update(
        id: widget.notificacao.id,
        valor: _parsedValor(),
        descricaoOriginal: widget.notificacao.descricaoOriginal,
        descricaoNormalizada: desc,
      );

      await NotificationsChannel.salvarMapeamento(
        descricaoOriginal: widget.notificacao.descricaoOriginal,
        descricaoNormalizada: desc,
      );

      if (mounted) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Notificação atualizada!',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(
          context: context,
          message: 'Erro ao salvar: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _apagar() async {
    final confirmar = await ConfirmationDialog.show(
      context: context,
      title: 'Apagar notificação?',
      message:
          'A notificação "${widget.notificacao.descricaoOriginal}" será removida permanentemente.',
      confirmText: 'Apagar',
      cancelText: 'Cancelar',
    );

    if (confirmar != true) return;

    try {
      await NotificationsChannel.delete(widget.notificacao.id);

      if (mounted) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Notificação apagada.',
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(
          context: context,
          message: 'Erro ao apagar: $e',
        );
      }
    }
  }

  Future<void> _tentarNovamente() async {
    setState(() => _isRetrying = true);

    try {
      final service =
          Provider.of<NotificationProcessingService>(context, listen: false);

      await service.processarEvento({
        'id': widget.notificacao.id,
        'package': widget.notificacao.banco,
        'title': widget.notificacao.tituloNotificacao ?? '',
        'content': widget.notificacao.descricaoOriginal,
      });

      final atualizadas = await NotificationsChannel.getAll();
      NotificacaoBancariaModel? atualizada;
      for (final n in atualizadas) {
        if (n.id == widget.notificacao.id) {
          atualizada = n;
          break;
        }
      }

      if (!mounted) return;

      if (atualizada != null && !atualizada.erroProcessamento) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Notificação processada com sucesso!',
        );
        Navigator.of(context).pop();
      } else {
        setState(() => _erroProcessamento = true);
        OrcamentosSnackBar.error(
          context: context,
          message: 'Ainda não foi possível obter o padrão. Tente novamente mais tarde.',
        );
      }
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(
          context: context,
          message: 'Erro ao tentar novamente: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  void _abrirCadastroComoGasto() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CadastrarGastoSheet(
        notificacao: widget.notificacao,
        descricaoNormalizada: _descricaoEfetiva,
        valor: _parsedValor(),
        onSucesso: (gastoId) async {
          await NotificationsChannel.associarGasto(
            id: widget.notificacao.id,
            gastoId: gastoId,
          );

          final desc = _descricaoEfetiva;

          if (desc != widget.notificacao.descricaoOriginal) {
            await NotificationsChannel.salvarMapeamento(
              descricaoOriginal: widget.notificacao.descricaoOriginal,
              descricaoNormalizada: desc,
              gastoId: gastoId,
            );
          }

          if (mounted) {
            OrcamentosSnackBar.success(
              context: context,
              message: 'Gasto cadastrado e notificação vinculada!',
            );
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notificacao;
    final dataLocal = n.dataNotificacaoDateTime.toLocal();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          SharedAppBar(
            title: 'Editar Notificação',
            subtitle: n.nomeBanco,
            mainIcon: Icons.notifications_rounded,
            gradientColors: _gradientColors,
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
            showAvatar: false,
            actionButtons: [
              SharedAppBar.headerButton(
                onTap: _apagar,
                tooltip: 'Apagar notificação',
                isSquare: true,
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ValorDestaque(
                    valor: _parsedValor(),
                    data: dataLocal,
                    vinculado: n.vinculado,
                  ),
                  if (_erroProcessamento) ...[
                    const SizedBox(height: 16),
                    _ErroProcessamentoBanner(
                      isRetrying: _isRetrying,
                      onTentarNovamente: _tentarNovamente,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'Detalhes'),
                  const SizedBox(height: 10),
                  _SectionCard(
                    children: [
                      _InfoRow(
                        icon: Icons.account_balance_rounded,
                        color: _blue,
                        label: 'Banco',
                        value: n.nomeBanco,
                        isFirst: true,
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.schedule_rounded,
                        color: Colors.grey[600]!,
                        label: 'Data',
                        value: _dateFmt.format(dataLocal),
                      ),
                      const _Divider(),
                      _InfoRow(
                        icon: Icons.notes_rounded,
                        color: Colors.grey[500]!,
                        label: 'Descrição original',
                        value: n.descricaoOriginal,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'Editar informações'),
                  const SizedBox(height: 10),
                  _SectionCard(
                    children: [
                      _EditableRow(
                        icon: Icons.attach_money_rounded,
                        color: _blue,
                        label: 'Valor',
                        controller: _valorCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        isFirst: true,
                        onChanged: (v) {
                          final formatted = _formatarValor(v);
                          if (formatted != v) {
                            _valorCtrl.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                offset: formatted.length,
                              ),
                            );
                          }
                          setState(() {});
                        },
                      ),
                      const _Divider(),
                      _EditableRow(
                        icon: Icons.label_outline_rounded,
                        color: _blue,
                        label: 'Descrição normalizada',
                        controller: _descNormalizadaCtrl,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _salvar,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'Salvando…' : 'Salvar alterações',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  if (!n.vinculado) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _abrirCadastroComoGasto,
                        icon: const Icon(Icons.add_shopping_cart_rounded,
                            size: 18),
                        label: const Text('Cadastrar como gasto variado',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _blue,
                          side: BorderSide(color: _blue.withValues(alpha: 0.4)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Banner de erro ao obter o padrão regex
// ═══════════════════════════════════════════════════════════════════════════════
class _ErroProcessamentoBanner extends StatelessWidget {
  final bool isRetrying;
  final VoidCallback onTentarNovamente;

  const _ErroProcessamentoBanner({
    required this.isRetrying,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE65100);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: orange, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Não foi possível identificar o valor desta notificação '
                  'automaticamente.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isRetrying ? null : onTentarNovamente,
              icon: isRetrying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: orange,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                isRetrying ? 'Tentando…' : 'Tentar novamente',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: orange,
                side: BorderSide(color: orange.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Destaque do valor
// ═══════════════════════════════════════════════════════════════════════════════
class _ValorDestaque extends StatelessWidget {
  final double valor;
  final DateTime data;
  final bool vinculado;

  const _ValorDestaque({
    required this.valor,
    required this.data,
    required this.vinculado,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dataStr =
        DateFormat("d 'de' MMMM 'de' yyyy 'às' HH:mm", 'pt_BR').format(data);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF283593), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3949AB).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valor da notificação',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            fmt.format(valor),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              vinculado ? 'Vinculada' : 'Não vinculada',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dataStr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sheet "Cadastrar como gasto variado"
// ═══════════════════════════════════════════════════════════════════════════════
class _CadastrarGastoSheet extends StatefulWidget {
  final NotificacaoBancariaModel notificacao;
  final String descricaoNormalizada;
  final double valor;
  final Future<void> Function(int gastoId) onSucesso;

  const _CadastrarGastoSheet({
    required this.notificacao,
    required this.descricaoNormalizada,
    required this.valor,
    required this.onSucesso,
  });

  @override
  State<_CadastrarGastoSheet> createState() => _CadastrarGastoSheetState();
}

class _CadastrarGastoSheetState extends State<_CadastrarGastoSheet> {
  List<OrcamentoResponseDto> _orcamentos = [];
  List<CategoriaGastoResponseDto> _categorias = [];
  OrcamentoResponseDto? _orcamentoSelecionado;
  CategoriaGastoResponseDto? _categoriaSelecionada;
  DateTime _dataPgto = DateTime.now();
  bool _isLoading = true;
  bool _isSaving = false;

  static const _blue = Color(0xFF3949AB);
  final _dateFmt = DateFormat('dd/MM/yyyy');
  final _fmtValor = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _dataPgto = widget.notificacao.dataNotificacaoDateTime.toLocal();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final results = await Future.wait([
        api.getOrcamentos(encerrado: false, inativo: false),
        api.getCategorias(),
      ]);
      if (mounted) {
        setState(() {
          _orcamentos = results[0] as List<OrcamentoResponseDto>;
          _categorias = results[1] as List<CategoriaGastoResponseDto>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cadastrar() async {
    if (_orcamentoSelecionado == null) {
      OrcamentosSnackBar.error(
          context: context, message: 'Selecione um orçamento.');
      return;
    }
    if (_categoriaSelecionada == null) {
      OrcamentosSnackBar.error(
          context: context, message: 'Selecione uma categoria.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final gasto = await api.createGastoVariado(
        _orcamentoSelecionado!.id,
        GastoVariadoCreateDto(
          descricao: widget.descricaoNormalizada,
          valor: widget.valor.toStringAsFixed(2),
          dataPgto: _dataPgto,
          categoriaId: _categoriaSelecionada!.id,
          observacoes: '',
        ),
      );
      if (mounted) Navigator.of(context).pop();
      await widget.onSucesso(gasto.id);
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(
            context: context, message: 'Erro ao cadastrar: $e');
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: _blue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_shopping_cart_rounded,
                    color: _blue, size: 18),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cadastrar como gasto variado',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36)),
              ),
            ]),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Text(
                '${widget.descricaoNormalizada} · ${_fmtValor.format(widget.valor)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(
                  child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ))
            else ...[
              _SheetLabel(label: 'Orçamento'),
              const SizedBox(height: 8),
              _DropdownField<OrcamentoResponseDto>(
                hint: 'Selecionar orçamento',
                items: _orcamentos,
                value: _orcamentoSelecionado,
                itemLabel: (o) => o.nome,
                onChanged: (v) =>
                    setState(() => _orcamentoSelecionado = v),
              ),
              const SizedBox(height: 16),
              _SheetLabel(label: 'Data de pagamento'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dataPgto,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (ctx, child) => Theme(
                      data: Theme.of(ctx).copyWith(
                          colorScheme:
                              const ColorScheme.light(primary: _blue)),
                      child: child!,
                    ),
                  );
                  if (picked != null) setState(() => _dataPgto = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: _blue, size: 16),
                    const SizedBox(width: 10),
                    Text(
                      _dateFmt.format(_dataPgto),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 16),
              _SheetLabel(label: 'Categoria'),
              const SizedBox(height: 8),
              _DropdownField<CategoriaGastoResponseDto>(
                hint: 'Selecionar categoria',
                items: _categorias
                    .where((c) => c.dataInatividade == null)
                    .toList(),
                value: _categoriaSelecionada,
                itemLabel: (c) => c.nome,
                onChanged: (v) =>
                    setState(() => _categoriaSelecionada = v),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey[200]!)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar',
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isSaving ? null : _cadastrar,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Cadastrar',
                            style:
                                TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Widgets auxiliares
// ═══════════════════════════════════════════════════════════════════════════════

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 12, 16, isLast ? 16 : 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1F36))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool isFirst;
  final bool isLast;

  const _EditableRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.controller,
    this.onChanged,
    this.keyboardType,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 12, 16, isLast ? 16 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3)),
                const SizedBox(height: 2),
                TextField(
                  controller: controller,
                  onChanged: onChanged,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1F36)),
                  decoration: const InputDecoration(
                    isDense: true,
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62),
      child: Container(height: 1, color: Colors.grey[100]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey[500],
        letterSpacing: 0.8,
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String label;
  const _SheetLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.3),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String hint;
  final List<T> items;
  final T? value;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.hint,
    required this.items,
    required this.value,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint,
              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
          isExpanded: true,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child:
                  Text(itemLabel(item), style: const TextStyle(fontSize: 15)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
