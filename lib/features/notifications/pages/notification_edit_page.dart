import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/common/shared_appbar.dart';
import 'package:orcamentos_app/features/notifications/models/notification_model.dart';
import 'package:orcamentos_app/features/notifications/notifications_channel.dart';
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
        descricaoNormalizada: desc,
      );
      await NotificationsChannel.salvarMapeamento(
        descricaoOriginal: widget.notificacao.descricaoOriginal,
        descricaoNormalizada: desc,
      );
      if (mounted) {
        OrcamentosSnackBar.success(
            context: context, message: 'Notificação atualizada!');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(
            context: context, message: 'Erro ao salvar: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _apagar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Apagar notificação?',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        content: Text(
          'A notificação "${widget.notificacao.descricaoOriginal}" será removida permanentemente.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Apagar',
              style: TextStyle(
                  color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await NotificationsChannel.delete(widget.notificacao.id);
      if (mounted) {
        OrcamentosSnackBar.success(
            context: context, message: 'Notificação apagada.');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(
            context: context, message: 'Erro ao apagar: $e');
      }
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
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    children: [
                      _InfoRow(
                        label: 'Banco',
                        value: n.nomeBanco,
                        icon: Icons.account_balance_rounded,
                        color: _blue,
                      ),
                      const _Divider(),
                      _InfoRow(
                        label: 'Data',
                        value: _dateFmt.format(dataLocal),
                        icon: Icons.schedule_rounded,
                        color: Colors.grey[600]!,
                      ),
                      const _Divider(),
                      _ReadOnlyField(
                        label: 'Descrição original',
                        value: n.descricaoOriginal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionLabel(label: 'Editar informações'),
                  const SizedBox(height: 12),
                  _SectionCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Valor',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _valorCtrl,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: _blue, width: 1.5),
                                ),
                              ),
                              onChanged: (v) {
                                final formatted = _formatarValor(v);
                                if (formatted != v) {
                                  _valorCtrl.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Descrição normalizada',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _descNormalizadaCtrl,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText:
                                    'Ex: Almoço restaurante, Netflix, Mercado…',
                                hintStyle: TextStyle(
                                    color: Colors.grey[400], fontSize: 14),
                                filled: true,
                                fillColor: Colors.grey[50],
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 13),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[200]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey[200]!),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: _blue, width: 1.5),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(
                        _isSaving ? 'Salvando…' : 'Salvar alterações',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
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
                        label: const Text(
                          'Cadastrar como gasto variado',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: _blue, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.green[200]!, width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.green[700], size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Já vinculada a um gasto',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey[400],
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500),
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
