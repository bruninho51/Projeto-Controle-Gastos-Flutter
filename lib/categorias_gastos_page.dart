import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CategoriasDeGastoPage extends StatefulWidget {
  final String apiToken;

  const CategoriasDeGastoPage({super.key, required this.apiToken});

  @override
  _CategoriasDeGastoPageState createState() => _CategoriasDeGastoPageState();
}

class _CategoriasDeGastoPageState extends State<CategoriasDeGastoPage> {
  List<dynamic> _categorias = [];
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>(); // GlobalKey para o Form
  TextEditingController _nomeCategoriaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
  }

  Future<void> _fetchCategorias() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.get(
      Uri.parse('http://192.168.1.147:3000/api/v1/categorias-gastos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      setState(() {
        _categorias = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      print("Erro ao carregar categorias: ${response.statusCode}");
    }
  }

  Future<void> _deleteCategoria(int categoriaId) async {
    final response = await http.delete(
      Uri.parse('http://192.168.1.147:3000/api/v1/categorias-gastos/$categoriaId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria apagada com sucesso!')),
      );
      setState(() {
        _categorias.removeWhere((categoria) => categoria['id'] == categoriaId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao apagar categoria!')),
      );
    }
  }

  void _showDeleteConfirmationDialog(int categoriaId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza de que deseja excluir esta categoria?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o dialog sem excluir
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o dialog
                _deleteCategoria(categoriaId); // Chama a função de exclusão
              },
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }

  // Função para criar nova categoria
  Future<void> _createCategoria(String nomeCategoria) async {
    final response = await http.post(
      Uri.parse('http://192.168.1.147:3000/api/v1/categorias-gastos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
      body: json.encode({
        'nome': nomeCategoria,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoria criada com sucesso!')),
      );
      _fetchCategorias(); // Atualiza a lista de categorias
      Navigator.of(context).pop(); // Fecha o modal
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao criar categoria!')),
      );
    }
  }

  // Função para exibir o modal para criação de categoria
  void _showCreateCategoriaDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Criar Nova Categoria'),
          content: SingleChildScrollView( // Permite o conteúdo rolar caso necessário
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400), // Limita a largura do modal
              child: Form(
                key: _formKey,  // Associa o Form com a chave global
                child: TextFormField(
                  controller: _nomeCategoriaController,
                  decoration: const InputDecoration(
                    hintText: 'Digite o nome da categoria',
                    border: OutlineInputBorder(), // Definindo a borda para o campo
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'O nome da categoria não pode ser vazio!';
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o dialog
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _createCategoria(_nomeCategoriaController.text);
                  _nomeCategoriaController.text = ""; // Limpa o campo após salvar
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Cor da AppBar
      appBar: AppBar(
        backgroundColor: Colors.blue[50], // Cor da AppBar
        title: const Text('Categorias de Gasto'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
              ? const Center(child: Text('Nenhuma categoria encontrada'))
              : ListView.builder(
                  itemCount: _categorias.length,
                  itemBuilder: (context, index) {
                    final categoria = _categorias[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Row(
                          children: [
                            const Icon(Icons.category, size: 30, color: Colors.blue),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    categoria['nome'] ?? 'Sem nome',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Botão de lixo para deletar a categoria
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _showDeleteConfirmationDialog(categoria['id']);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCategoriaDialog,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
