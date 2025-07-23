import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'lista_exercicios_categoria_page.dart';
import 'grupos_categoria_page.dart';
import 'optimized_gif_widget.dart';

class AdicionarExercicioPage extends StatefulWidget {
  const AdicionarExercicioPage({Key? key}) : super(key: key);

  @override
  State<AdicionarExercicioPage> createState() => _AdicionarExercicioPageState();
}

class _AdicionarExercicioPageState extends State<AdicionarExercicioPage> {
  List<String> categorias = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    buscarCategorias();
  }

  Future<void> buscarCategorias() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http.get(
        Uri.parse('https://airfit.online/api/buscar_categorias.php'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            categorias = data.cast<String>();
            isLoading = false;
          });
        } else if (data is Map && data.containsKey('erro')) {
          setState(() {
            errorMessage = data['erro'];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Erro ao buscar categorias: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro de conexão: $e';
        isLoading = false;
      });
    }
  }

  void _onCategoriaTap(String categoria) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final response = await http.get(
        Uri.parse('https://airfit.online/api/buscar_grupos.php?categoria=${Uri.encodeQueryComponent(categoria)}'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );
      Navigator.of(context).pop(); // Fecha o loading
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          // Tem grupos, navega para nova tela de grupos
          final exercicioSelecionado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GruposCategoriaPage(categoria: categoria, grupos: List<String>.from(data)),
            ),
          );
          if (exercicioSelecionado != null) {
            Navigator.pop(context, exercicioSelecionado);
          }
        } else {
          // Não tem grupos, vai direto para lista de exercícios
          final exercicioSelecionado = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ListaExerciciosCategoriaPage(categoria: categoria),
            ),
          );
          if (exercicioSelecionado != null) {
            Navigator.pop(context, exercicioSelecionado);
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao buscar grupos:  {response.statusCode}')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão ao buscar grupos: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Exercício'),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        titleTextStyle: const TextStyle(
          color: Color(0xFF374151),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Carregando categorias...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Erro ao carregar categorias',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: buscarCategorias,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (categorias.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma categoria encontrada',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Não há categorias de exercícios cadastradas.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return _buildCategorias();
  }

  Widget _buildCategorias() {
    return RefreshIndicator(
      onRefresh: buscarCategorias,
      child: ListView(
        children: [
          const Text(
            'Selecione uma categoria:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...categorias.map((categoria) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    categoria,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  leading: const Icon(
                    Icons.fitness_center,
                    color: Color(0xFF374151),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF374151),
                  ),
                  onTap: () => _onCategoriaTap(categoria),
                ),
              )),
        ],
      ),
    );
  }
} 