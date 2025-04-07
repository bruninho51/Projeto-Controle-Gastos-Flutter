import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/http.dart';
import 'package:orcamentos_app/formatters.dart';

class FormOrcamentoValorInicialPage extends StatefulWidget {
  final String apiToken;
  final double valorInicial;
  final int orcamentoId;

  const FormOrcamentoValorInicialPage({Key? key, required this.apiToken, required this.orcamentoId, required this.valorInicial}) : super(key: key);

  @override
  _FormOrcamentoValorInicialPageState createState() =>
      _FormOrcamentoValorInicialPageState();
}

class _FormOrcamentoValorInicialPageState
    extends State<FormOrcamentoValorInicialPage> {
  TextEditingController _valorController = TextEditingController();
  late double _valorInicial;

  final _formKey = GlobalKey<FormState>(); // Para validar o formulário
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _valorInicial = widget.valorInicial; // Inicializando com o valor recebido
  }

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  String _formatarValor(String value) {
    // Remove todos os caracteres não numéricos, exceto o ponto
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Converte para double e formata
    if (cleanedValue.isNotEmpty) {
      double parsedValue = double.tryParse(cleanedValue) ?? 0.0;
      parsedValue = parsedValue / 100; // Converte centavos para reais
      return _formatador.format(parsedValue);
    }
    return '';
  }

  String converterParaFormatoNumerico(String valorFormatado) {
    // Remove o símbolo da moeda (R$) e espaços em branco
    String valorSemSimbolo = valorFormatado.replaceAll('R\$', '').trim();

    // Substitui a vírgula (separador decimal) por ponto
    String valorComPonto = valorSemSimbolo.replaceAll('.', '').replaceAll(',', '.');

    return valorComPonto;
  }

  void _updateValorInicial(orcamentoId, valorInicial) async {

    print("valor inicial novo : $valorInicial");
    final client = await MyHttpClient.create();

    final response = await client.patch(
      'orcamentos/$orcamentoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',  // Certifique-se de que o apiToken não é nulo
      },
      body: jsonEncode({
        'valor_inicial': "$valorInicial",  // Corrigido para o nome correto da chave
      }),
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      // Se o orçamento for salvo com sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento salvo com sucesso!')),
      );
      Navigator.pop(context, true); // Retorna à tela anterior
    } else {
      Navigator.pop(context, false);
      print(response.body.toString());
      // Se a requisição falhar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao alterar o orçamento')),
      );
    }
  }

  // Método para abrir o modal e executar a ação (somar, subtrair ou substituir)
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
                // Remove a formatação para validar o número
                String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (double.tryParse(cleanedValue) == null) {
                  return 'Por favor, insira um valor válido';
                }
                return null;
              },
              onChanged: (value) {
                // Formata o valor enquanto o usuário digita
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
                // Verifica se a validação do formulário foi bem-sucedida
                if (_formKey.currentState!.validate()) {
                  double valor = double.tryParse(converterParaFormatoNumerico(_valorController.text)) ?? 0.0;
                  print("valor controller: ${converterParaFormatoNumerico(_valorController.text)}");
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

                  _valorController.clear(); // Limpa o campo de texto
                } else {
                  // Se o formulário não for válido, não faz nada e mantém o erro
                }
              },
              child: const Text('Confirmar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Fecha o modal sem ação
                _valorController.clear(); // Limpa o campo de texto
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  // Método para criar os cards com ícones
  Widget _buildDashboardCard(String title, Color color, IconData icon, String action) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: () => _openValueDialog(action),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1), // Cor de fundo do ícone
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Cor da AppBar
      appBar: AppBar(
        backgroundColor: Colors.blue[50], // Cor da AppBar
        title: const Text('Formulário de Valor Inicial'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exibição do valor inicial
            Text(
              'Valor Inicial: ${formatarValor(_valorInicial)}',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Grid de Cards para interações (duas colunas)
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 colunas
                  crossAxisSpacing: 20.0, // Espaço entre os cards
                  mainAxisSpacing: 20.0, // Espaço entre os cards
                  childAspectRatio: 1.0, // Tamanho igual para os cards
                ),
                itemCount: 3,
                itemBuilder: (context, index) {
                  switch (index) {
                    case 0:
                      return _buildDashboardCard(
                        'Inserir Novo Valor Inicial',
                        Colors.blue,
                        Icons.input,
                        'Inserir Novo Valor Inicial',
                      );
                    case 1:
                      return _buildDashboardCard(
                        'Somar ao Valor Inicial',
                        Colors.green,
                        Icons.add,
                        'Somar ao Valor Inicial',
                      );
                    case 2:
                      return _buildDashboardCard(
                        'Subtrair do Valor Inicial',
                        Colors.red,
                        Icons.remove,
                        'Subtrair do Valor Inicial',
                      );
                    default:
                      return Container();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
