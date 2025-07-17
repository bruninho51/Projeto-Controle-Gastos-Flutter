import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/common/confirmation_dialog.dart';

class CategoriasDeGastoPage extends StatefulWidget {
  final String apiToken;

  const CategoriasDeGastoPage({super.key, required this.apiToken});

  @override
  _CategoriasDeGastoPageState createState() => _CategoriasDeGastoPageState();
}

class _CategoriasDeGastoPageState extends State<CategoriasDeGastoPage> {
  List<dynamic> _categorias = [];
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nomeCategoriaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchCategorias();
  }

  @override
  void dispose() {
    _nomeCategoriaController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategorias() async {
    setState(() => _isLoading = true);

    try {
      final client = await MyHttpClient.create();
      final response = await client.get(
        'categorias-gastos',
        headers: _buildHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        setState(() {
          _categorias = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Erro ao carregar categorias: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      OrcamentosSnackBar.error(
        context: context,
        message: 'Erro ao carregar categorias',
      );
    }
  }

  Future<void> _deleteCategoria(int categoriaId) async {
    try {
      final client = await MyHttpClient.create();
      final response = await client.delete(
        'categorias-gastos/$categoriaId',
        headers: _buildHeaders(),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Categoria apagada com sucesso!',
        );
        setState(() {
          _categorias.removeWhere((categoria) => categoria['id'] == categoriaId);
        });
      } else {
        throw Exception('Erro ao apagar categoria');
      }
    } catch (e) {
      OrcamentosSnackBar.error(
        context: context,
        message: 'Erro ao apagar categoria',
      );
    }
  }

  Future<void> _createCategoria(String nomeCategoria) async {
    try {
      final client = await MyHttpClient.create();
      final response = await client.post(
        'categorias-gastos',
        headers: _buildHeaders(),
        body: json.encode({'nome': nomeCategoria}),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Categoria criada com sucesso!',
        );
        _fetchCategorias();
        Navigator.of(context).pop();
        _nomeCategoriaController.clear();
      } else {
        throw Exception('Erro ao criar categoria');
      }
    } catch (e) {
      OrcamentosSnackBar.error(
        context: context,
        message: 'Erro ao criar categoria',
      );
    }
  }

  void _showCreateCategoriaDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Criar Nova Categoria'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  controller: _nomeCategoriaController,
                  decoration: const InputDecoration(
                    hintText: 'Digite o nome da categoria',
                    border: OutlineInputBorder(),
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
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _createCategoria(_nomeCategoriaController.text);
                  _nomeCategoriaController.text = "";
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.apiToken}',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Categorias de Gastos',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.indigo[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categorias.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.category, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Nenhuma categoria cadastrada',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categorias.length,
                  itemBuilder: (context, index) {
                    final categoria = _categorias[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.category,
                            color: Colors.indigo[700],
                          ),
                        ),
                        title: Text(
                          categoria['nome'] ?? 'Sem nome',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[400]),
                          onPressed: () => ConfirmationDialog.confirmAction(
                            context: context,
                            title: 'Excluir Categoria',
                            message: 'Deseja realmente excluir esta categoria?',
                            actionText: 'Excluir',
                            action: () => _deleteCategoria(categoria['id']),
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCategoriaDialog,
        backgroundColor: Colors.indigo[700],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}