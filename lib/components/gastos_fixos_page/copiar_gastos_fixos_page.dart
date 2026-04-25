import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/common/orcamentos_loading.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:provider/provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Tela principal — lista de orçamentos para escolher a fonte
// ═══════════════════════════════════════════════════════════════════════════════
class CopiarGastosFixosPage extends StatefulWidget {
  final int orcamentoDestinoId;
  final String apiToken;

  const CopiarGastosFixosPage({
    super.key,
    required this.orcamentoDestinoId,
    required this.apiToken,
  });

  @override
  State<CopiarGastosFixosPage> createState() => _CopiarGastosFixosPageState();
}

class _CopiarGastosFixosPageState extends State<CopiarGastosFixosPage> {

  late ApiService apiService;

  late Future<List<OrcamentoResponseDto>> _orcamentos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      apiService = Provider.of<ApiService>(context, listen: false);
      setState(() {
        _orcamentos = _fetchOrcamentos(); // síncrono — só atribui o Future
      });
    });
  }

  Future<List<OrcamentoResponseDto>> _fetchOrcamentos() async {
    final lista = await apiService.getOrcamentos();
    return lista
        .where((o) => o.id != widget.orcamentoDestinoId)
        .toList()
      ..sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────────
          _CopiarHeader(onBack: () => Navigator.of(context).pop()),

          // ── Lista de orçamentos ───────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<OrcamentoResponseDto>>(
              future: _orcamentos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: OrcamentosLoading(message: 'Carregando...'));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erro ao carregar orçamentos ${snapshot.error}',
                          style: TextStyle(color: Colors.grey[600])));
                }
                final orcamentos = snapshot.data ?? [];
                if (orcamentos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                              color: const Color(0xFF1A237E).withOpacity(0.06),
                              shape: BoxShape.circle),
                          child: Icon(Icons.account_balance_wallet_outlined,
                              size: 48, color: const Color(0xFF3949AB).withOpacity(0.5)),
                        ),
                        const SizedBox(height: 20),
                        Text('Nenhum outro orçamento encontrado',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  physics: const BouncingScrollPhysics(),
                  itemCount: orcamentos.length,
                  itemBuilder: (context, index) {
                    final o = orcamentos[index];
                    final isEncerrado = o.dataEncerramento != null;
                    return _OrcamentoCard(
                      orcamento: o,
                      isEncerrado: isEncerrado,
                      onTap: () async {
                        final copiou = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _SelecionarGastosPage(
                              orcamentoFonteId: o.id,
                              orcamentoFonteNome: o.nome,
                              orcamentoDestinoId: widget.orcamentoDestinoId,
                              apiToken: widget.apiToken,
                            ),
                          ),
                        );
                        if (copiou == true && context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      },
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
// Tela de seleção de gastos do orçamento fonte
// ═══════════════════════════════════════════════════════════════════════════════
class _SelecionarGastosPage extends StatefulWidget {
  final int orcamentoFonteId;
  final String orcamentoFonteNome;
  final int orcamentoDestinoId;
  final String apiToken;

  const _SelecionarGastosPage({
    required this.orcamentoFonteId,
    required this.orcamentoFonteNome,
    required this.orcamentoDestinoId,
    required this.apiToken,
  });

  @override
  State<_SelecionarGastosPage> createState() => _SelecionarGastosPageState();
}

class _SelecionarGastosPageState extends State<_SelecionarGastosPage> {
  late Future<List<GastoFixoResponseDto>> _gastos;
  final Set<int> _selecionados = {};
  bool _processando = false;
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      apiService = Provider.of<ApiService>(context, listen: false);
      setState(() {
        _gastos = _fetchGastos(); // síncrono — só atribui o Future
      });
    });
  }

  Future<List<GastoFixoResponseDto>> _fetchGastos() async {
    return apiService.getGastosFixos(orcamentoId: widget.orcamentoFonteId);
  }

  Future<void> _copiar() async {
    if (_selecionados.isEmpty) {
      OrcamentosSnackBar.error(
          context: context, message: 'Selecione pelo menos um gasto.');
      return;
    }
    setState(() => _processando = true);

    try {
      final gastos = await _gastos;
      final selecionados =
      gastos.where((g) => _selecionados.contains(g.id)).toList();

      int erros = 0;
      final agora = DateTime.now();

      for (final g in selecionados) {
        // Transfere data_venc para o mesmo dia no mês atual
        DateTime? dataVencAtualizada;
        if (g.dataVenc != null) {
          try {
            final original = g.dataVenc!;
            final atualizada = DateTime(agora.year, agora.month, original.day);
            dataVencAtualizada = atualizada;
          } catch (e) {
            dataVencAtualizada = g.dataVenc!;
          }
        }

        try {
          await apiService.createGastoFixo(
            widget.orcamentoDestinoId,
            GastoFixoCreateDto(
              descricao: g.descricao,
              previsto: g.previsto,
              categoriaId: g.categoriaId,
              observacoes: g.observacoes ?? '',
              dataVenc: dataVencAtualizada,
            ),
          );
        } catch (_) {
          erros++;
        }
      }

      if (!mounted) return;

      if (erros == 0) {
        OrcamentosSnackBar.success(
            context: context,
            message:
            '${selecionados.length} gasto${selecionados.length == 1 ? '' : 's'} copiado${selecionados.length == 1 ? '' : 's'} com sucesso!');
      } else {
        OrcamentosSnackBar.error(
            context: context,
            message: '$erros gasto(s) não puderam ser copiados.');
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        OrcamentosSnackBar.error(
            context: context, message: 'Erro ao copiar gastos: $e');
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          _SelecionarHeader(
            nome: widget.orcamentoFonteNome,
            onBack: () => Navigator.of(context).pop(),
          ),

          // ── Lista de gastos com checkbox ────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<GastoFixoResponseDto>>(
              future: _gastos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: OrcamentosLoading(message: 'Carregando...'));
                }
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('Nenhum gasto fixo neste orçamento',
                        style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                  );
                }

                final gastos = snapshot.data!;

                return Column(
                  children: [
                    // Barra de selecionar todos
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Row(
                        children: [
                          Text(
                            '${_selecionados.length} de ${gastos.length} selecionados',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => setState(() {
                              if (_selecionados.length == gastos.length) {
                                _selecionados.clear();
                              } else {
                                _selecionados.addAll(gastos.map((g) => g.id));
                              }
                            }),
                            child: Text(
                              _selecionados.length == gastos.length
                                  ? 'Desmarcar todos'
                                  : 'Selecionar todos',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF3949AB),
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Lista
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                        physics: const BouncingScrollPhysics(),
                        itemCount: gastos.length,
                        itemBuilder: (context, index) {
                          final g = gastos[index];
                          final id = g.id;
                          final selected = _selecionados.contains(id);
                          return _GastoCheckItem(
                            gasto: g,
                            selected: selected,
                            onToggle: () => setState(() {
                              if (selected) {
                                _selecionados.remove(id);
                              } else {
                                _selecionados.add(id);
                              }
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // ── Botões fixos no rodapé ──────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _processando ? null : () => Navigator.of(context).pop(),
                  child: Text('Cancelar',
                      style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _processando ? null : _copiar,
                  child: _processando
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _selecionados.isEmpty
                              ? 'Prosseguir'
                              : 'Copiar ${_selecionados.length} gasto${_selecionados.length == 1 ? '' : 's'}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card de orçamento na lista de seleção de fonte
// ═══════════════════════════════════════════════════════════════════════════════
class _OrcamentoCard extends StatelessWidget {
  final OrcamentoResponseDto orcamento;
  final bool isEncerrado;
  final VoidCallback onTap;

  const _OrcamentoCard({required this.orcamento, required this.isEncerrado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorAtual = double.tryParse(orcamento.valorAtual) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: const Color(0xFF1A237E).withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                      color: isEncerrado
                          ? Colors.grey[100]
                          : const Color(0xFF1A237E).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.account_balance_wallet_rounded,
                      color: isEncerrado ? Colors.grey[400] : const Color(0xFF1A237E),
                      size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(orcamento.nome,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A1F36))),
                      const SizedBox(height: 3),
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                              color: isEncerrado ? Colors.grey[100] : const Color(0xFF43A047).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            isEncerrado ? 'Encerrado' : 'Ativo',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isEncerrado ? Colors.grey[500] : const Color(0xFF43A047)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(fmt.format(valorAtual),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ]),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Item de gasto com checkbox
// ═══════════════════════════════════════════════════════════════════════════════
class _GastoCheckItem extends StatelessWidget {
  final GastoFixoResponseDto gasto;
  final bool selected;
  final VoidCallback onToggle;

  const _GastoCheckItem({required this.gasto, required this.selected, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final previsto = double.tryParse(gasto.previsto) ?? 0.0;
    final descricao = gasto.descricao?.toString() ?? 'Sem descrição';
    final categoriaNome = gasto.categoriaGasto.nome;

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? const Color(0xFF1A237E) : Colors.transparent,
              width: 1.5),
          boxShadow: [
            BoxShadow(
                color: selected
                    ? const Color(0xFF1A237E).withOpacity(0.1)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Checkbox customizado
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1A237E) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: selected ? const Color(0xFF1A237E) : Colors.grey[300]!,
                      width: 1.5),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 12),

              // Ícone de recibo
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                    color: const Color(0xFF1A237E).withOpacity(0.07),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.receipt_long_rounded,
                    color: Color(0xFF1A237E), size: 18),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(descricao,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1F36)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (categoriaNome != null) ...[
                      const SizedBox(height: 2),
                      Text(categoriaNome,
                          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ],
                  ],
                ),
              ),

              // Valor
              Text(fmt.format(previsto),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Headers
// ═══════════════════════════════════════════════════════════════════════════════
class _CopiarHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _CopiarHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [BoxShadow(color: Color(0x551A237E), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Row(
        children: [
          _Btn(onTap: onBack, child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16)),
          const SizedBox(width: 12),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.copy_all_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Copiar Gastos Fixos',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
              Text('Selecione o orçamento de origem',
                  style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SelecionarHeader extends StatelessWidget {
  final String nome;
  final VoidCallback onBack;
  const _SelecionarHeader({required this.nome, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [BoxShadow(color: Color(0x551A237E), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Btn(onTap: onBack, child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16)),
              const SizedBox(width: 12),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.checklist_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(nome,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('Marque os gastos para copiar',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Btn({required this.child, required this.onTap});

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _pressed ? Colors.white.withOpacity(0.28) : Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: widget.child,
      ),
    );
  }
}