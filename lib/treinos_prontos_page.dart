import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TreinosProntosPage extends StatefulWidget {
  const TreinosProntosPage({Key? key}) : super(key: key);

  @override
  State<TreinosProntosPage> createState() => _TreinosProntosPageState();
}

class _TreinosProntosPageState extends State<TreinosProntosPage> {
  List<Map<String, dynamic>> treinosProntos = [];
  bool isLoading = true;
  bool isAddingTreino = false;
  int? treinoEmAdicao;

  @override
  void initState() {
    super.initState();
    _carregarTreinosProntos();
  }

  Future<void> _carregarTreinosProntos() async {
    try {
      setState(() => isLoading = true);
      
      // Buscar treinos públicos reais da API
      final response = await http.get(
        Uri.parse('https://airfit.online/api/buscar_treinos_prontos.php'),
      );

      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> treinosData = data['treinos'] ?? [];
          
          // Converter para List<Map<String, dynamic>>
          final List<Map<String, dynamic>> treinos = treinosData.map((treino) {
            return Map<String, dynamic>.from(treino);
          }).toList();

          setState(() {
            treinosProntos = treinos;
            isLoading = false;
          });
          
          print('Treinos prontos carregados: ${treinosProntos.length}');
        } else {
          print('Erro na API: ${data['message']}');
          setState(() => isLoading = false);
          _mostrarErro('Erro ao carregar treinos: ${data['message']}');
        }
      } else {
        print('Erro HTTP: ${response.statusCode}');
        setState(() => isLoading = false);
        _mostrarErro('Erro de conexão (${response.statusCode})');
      }
    } catch (e) {
      print('Erro ao carregar treinos prontos: $e');
      setState(() => isLoading = false);
      _mostrarErro('Erro de conexão: $e');
    }
  }

  Future<void> _adicionarTreinoAosMeusTreinos(Map<String, dynamic> treino) async {
    try {
      setState(() {
        isAddingTreino = true;
        treinoEmAdicao = int.tryParse(treino['id'].toString());
      });

      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');

      if (usuarioId == null) {
        _mostrarErro('Usuário não identificado');
        return;
      }

      // Chamar a API real para duplicar o treino
      final responseTreino = await http.post(
        Uri.parse('https://airfit.online/api/duplicar_treino_via_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': usuarioId,
          'treino_original_id': int.tryParse(treino['id'].toString()) ?? 0,
          'nome_treino': treino['nome_treino'],
        }),
      );

      print('Resposta duplicar treino: ${responseTreino.body}');

      if (responseTreino.statusCode == 200) {
        final result = jsonDecode(responseTreino.body);
        print('Resposta completa da API: $result');
        if (result['success'] == true) {
          final exerciciosDuplicados = result['exercicios_duplicados'] ?? 0;
          _mostrarSucesso('Treino "${treino['nome_treino']}" adicionado com sucesso! $exerciciosDuplicados exercícios copiados.');
        } else {
          _mostrarErro('Erro ao adicionar treino: ${result['message']}');
        }
      } else {
        print('Erro HTTP: ${responseTreino.statusCode}');
        print('Corpo da resposta: ${responseTreino.body}');
        _mostrarErro('Erro ao conectar com o servidor (${responseTreino.statusCode})');
      }
    } catch (e) {
      print('Erro ao adicionar treino: $e');
      _mostrarErro('Erro ao adicionar treino: $e');
    } finally {
      setState(() {
        isAddingTreino = false;
        treinoEmAdicao = null;
      });
    }
  }

  void _mostrarSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Treinos Prontos',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1F2937)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFF8FAFC), const Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6),
                ),
              )
            : treinosProntos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center_outlined,
                          size: 64,
                          color: const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum treino pronto disponível',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tente novamente mais tarde',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: treinosProntos.length,
                    itemBuilder: (context, index) {
                      final treino = treinosProntos[index];
                      final isAdicionando = isAddingTreino && treinoEmAdicao == int.tryParse(treino['id'].toString());
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header do treino
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF3B82F6),
                                    const Color(0xFF60A5FA),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.fitness_center,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          treino['nome_treino'] ?? 'Treino',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${treino['total_exercicios'] ?? 0} exercícios',
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Lista de exercícios
                            if (treino['exercicios'] != null && (treino['exercicios'] as List).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Exercícios incluídos:',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF374151),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ...(treino['exercicios'] as List).take(3).map((exercicio) => 
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6),
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                exercicio['nome_exercicio'] ?? 'Exercício',
                                                style: GoogleFonts.inter(
                                                  color: const Color(0xFF6B7280),
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if ((treino['exercicios'] as List).length > 3)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          '+ ${(treino['exercicios'] as List).length - 3} exercícios mais',
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF9CA3AF),
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            
                            // Botão de adicionar
                            Container(
                              padding: const EdgeInsets.all(16),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isAdicionando ? null : () => _adicionarTreinoAosMeusTreinos(treino),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: isAdicionando
                                      ? const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text('Adicionando...'),
                                          ],
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.add, size: 18),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Adicionar aos Meus Treinos',
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
} 