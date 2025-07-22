import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ListaExerciciosCategoriaPage extends StatefulWidget {
  final String categoria;
  final String? grupo;

  const ListaExerciciosCategoriaPage({Key? key, required this.categoria, this.grupo}) : super(key: key);

  @override
  State<ListaExerciciosCategoriaPage> createState() => _ListaExerciciosCategoriaPageState();
}

class _ListaExerciciosCategoriaPageState extends State<ListaExerciciosCategoriaPage> {
  List<Map<String, dynamic>> exercicios = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    buscarExercicios();
  }

  Future<void> buscarExercicios() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      String url = 'https://airfit.online/api/exercicios_categoria.php?categoria=${Uri.encodeQueryComponent(widget.categoria)}';
      if (widget.grupo != null && widget.grupo!.isNotEmpty) {
        url += '&grupo=${Uri.encodeQueryComponent(widget.grupo!)}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            exercicios = data.cast<Map<String, dynamic>>();
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
          errorMessage = 'Erro ao buscar exercícios: ${response.statusCode}';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grupo != null && widget.grupo!.isNotEmpty
            ? 'Exercícios - ${widget.grupo}'
            : 'Exercícios - ${widget.categoria}'),
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
        padding: const EdgeInsets.all(12),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: buscarExercicios,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }
    if (exercicios.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum exercício encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Não há exercícios cadastrados nesta categoria ou grupo.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: exercicios.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final exercicio = exercicios[index];
        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _mostrarDialogoConfirmacao(exercicio);
          },
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  _buildExercicioImage(exercicio),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      exercicio['nome_do_exercicio'] ?? 'Exercício',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF3B82F6)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExercicioImage(Map<String, dynamic> exercicio) {
    String? fotoGif = exercicio['foto_gif'];
    if (fotoGif != null && fotoGif.isNotEmpty) {
      // Corrige se o caminho for relativo
      if (!fotoGif.startsWith('http')) {
        fotoGif = 'https://airfit.online/$fotoGif';
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          fotoGif,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholderImage(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 64,
              height: 64,
              color: Colors.grey.shade100,
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Icon(Icons.fitness_center, color: Colors.grey, size: 32),
    );
  }

  void _mostrarDialogoConfirmacao(Map<String, dynamic> exercicio) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GIF do exercício em tamanho maior
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildExercicioImageDialog(exercicio),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Nome do exercício
                Text(
                  exercicio['nome_do_exercicio'] ?? 'Exercício',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                
                // Texto de confirmação
                const Text(
                  'Tem certeza que deseja adicionar este exercício ao treino?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Fecha o dialog
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Fecha o dialog
                          _adicionarExercicio(exercicio);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Sim, Adicionar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExercicioImageDialog(Map<String, dynamic> exercicio) {
    String? fotoGif = exercicio['foto_gif'];
    if (fotoGif != null && fotoGif.isNotEmpty) {
      // Corrige se o caminho for relativo
      if (!fotoGif.startsWith('http')) {
        fotoGif = 'https://airfit.online/$fotoGif';
      }
      return Image.network(
        fotoGif,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _placeholderImageDialog(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 200,
            height: 200,
            color: Colors.grey.shade100,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
      );
    }
    return _placeholderImageDialog();
  }

  Widget _placeholderImageDialog() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Icon(Icons.fitness_center, color: Colors.grey, size: 64),
    );
  }

  void _adicionarExercicio(Map<String, dynamic> exercicio) {
    // Retorna o exercício selecionado para a página anterior
    Navigator.pop(context, exercicio);
  }


} 