import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class FormularioOrcamentoPage extends StatefulWidget {
  final String apiToken;

  const FormularioOrcamentoPage({Key? key, required this.apiToken}) : super(key: key);

  @override
  _FormularioOrcamentoPageState createState() => _FormularioOrcamentoPageState();
}

class _FormularioOrcamentoPageState extends State<FormularioOrcamentoPage> {
  final _formKey = GlobalKey<FormState>();
  String _nome = '';
  final _valorInicialController = TextEditingController();

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

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final url = 'http://192.168.73.103:3000/api/v1/orcamentos';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',  // Certifique-se de que o apiToken não é nulo
        },
        body: jsonEncode({
          'nome': _nome,
          'valor_inicial': converterParaFormatoNumerico(_valorInicialController.text),  // Corrigido para o nome correto da chave
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
          const SnackBar(content: Text('Falha ao salvar o orçamento')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulário de Orçamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Campo Nome
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome do Orçamento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do orçamento';
                  }
                  return null;
                },
                onSaved: (value) {
                  _nome = value ?? '';
                },
              ),
              const SizedBox(height: 16),
              
              // Campo Valor Inicial
              TextFormField(
              decoration: const InputDecoration(
                labelText: 'Valor Inicial',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              controller: _valorInicialController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o valor inicial';
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
                _valorInicialController.value = TextEditingValue(
                  text: formattedValue,
                  selection: TextSelection.collapsed(offset: formattedValue.length),
                );
              },
            ),
              const SizedBox(height: 20),

              // Botão de Salvar
              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('Salvar Orçamento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
