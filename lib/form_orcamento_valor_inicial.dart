import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:orcamentos_app/http.dart';
import 'package:orcamentos_app/formatters.dart';
import 'package:orcamentos_app/refatorado/orcamentos_snackbar.dart';

class FormOrcamentoValorInicialPage extends StatefulWidget {
  final String apiToken;
  final double valorInicial;
  final int orcamentoId;

  const FormOrcamentoValorInicialPage({
    Key? key,
    required this.apiToken,
    required this.orcamentoId,
    required this.valorInicial,
  }) : super(key: key);

  @override
  _FormOrcamentoValorInicialPageState createState() => _FormOrcamentoValorInicialPageState();
}

class _FormOrcamentoValorInicialPageState extends State<FormOrcamentoValorInicialPage> {
  final _valorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late double _valorInicial;
  bool _isSubmitting = false;
  final _focusNode = FocusNode();

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _valorInicial = widget.valorInicial;
  }

  @override
  void dispose() {
    _valorController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatarValor(String value) {
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedValue.isNotEmpty) {
      double parsedValue = double.tryParse(cleanedValue) ?? 0.0;
      parsedValue = parsedValue / 100;
      return _formatador.format(parsedValue);
    }
    return '';
  }

  String _converterParaFormatoNumerico(String valorFormatado) {
    return valorFormatado
        .replaceAll('R\$', '')
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
  }

  Future<void> _updateValorInicial(int orcamentoId, double valorInicial) async {
    setState(() => _isSubmitting = true);
    
    try {
      final client = await MyHttpClient.create();
      final response = await client.patch(
        'orcamentos/$orcamentoId',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
        },
        body: jsonEncode({
          'valor_inicial': valorInicial.toString(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Valor inicial atualizado com sucesso!',
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Falha ao atualizar: ${response.statusCode}');
      }
    } catch (e) {
      OrcamentosSnackBar.error(
        context: context,
        message: 'Erro: ${e.toString()}',
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _openValueDialog(String action) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Digite o valor para $action'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _valorController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o valor';
                }
                String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (double.tryParse(cleanedValue) == null) {
                  return 'Por favor, insira um valor válido';
                }
                return null;
              },
              onChanged: (value) {
                String formattedValue = _formatarValor(value);
                _valorController.value = TextEditingValue(
                  text: formattedValue,
                  selection: TextSelection.collapsed(offset: formattedValue.length),
                );
              },
              decoration: const InputDecoration(
                labelText: 'Valor',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                _valorController.clear();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  double valor = double.tryParse(
                      _converterParaFormatoNumerico(_valorController.text)) ?? 0.0;
                  
                  setState(() {
                    if (action == 'Inserir Novo Valor Inicial') {
                      _valorInicial = valor;
                    } else if (action == 'Somar ao Valor Inicial') {
                      _valorInicial += valor;
                    } else if (action == 'Subtrair do Valor Inicial') {
                      _valorInicial -= valor;
                    }
                  });

                  _updateValorInicial(widget.orcamentoId, _valorInicial);
                  Navigator.pop(context, true);
                  _valorController.clear();
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(String title, Color color, IconData icon, String action) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openValueDialog(action),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Valor Inicial',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10), // Ajuste sutil no padding inferior
            child: Container(
              padding: const EdgeInsets.all(18), // Padding interno aumentado em 2px
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14), // Bordas ligeiramente mais arredondadas
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1), // Sombra mais suave
                    spreadRadius: 1,
                    blurRadius: 6,
                    offset: const Offset(0, 2), // Sombra mais próxima do card
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14), // Container do ícone um pouco maior
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 30, // Ícone ligeiramente maior
                      color: Colors.indigo[700],
                    ),
                  ),
                  const SizedBox(width: 18), // Espaçamento aumentado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VALOR INICIAL',
                          style: TextStyle(
                            fontSize: 13, // Fonte um pouco menor
                            fontWeight: FontWeight.w700, // Negrito mais forte
                            color: Colors.grey[600],
                            letterSpacing: 1.0, // Espaçamento entre letras aumentado
                          ),
                        ),
                        const SizedBox(height: 6), // Espaçamento aumentado
                        Text(
                          formatarValor(_valorInicial),
                          style: TextStyle(
                            fontSize: 26, // Fonte um pouco maior
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[900], // Cor mais alinhada ao tema
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ações disponíveis',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
                children: [
                  _buildActionCard(
                    'Definir novo valor',
                    Colors.blue,
                    Icons.edit,
                    'Inserir Novo Valor Inicial',
                  ),
                  _buildActionCard(
                    'Adicionar valor',
                    Colors.green,
                    Icons.add,
                    'Somar ao Valor Inicial',
                  ),
                  _buildActionCard(
                    'Subtrair valor',
                    Colors.red,
                    Icons.remove,
                    'Subtrair do Valor Inicial',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}