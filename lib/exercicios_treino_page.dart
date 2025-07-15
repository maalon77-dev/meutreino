import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExerciciosTreinoPage extends StatefulWidget {
  final Map<String, dynamic> treino;
  final List<Map<String, dynamic>> exercicios;
  final VoidCallback onVoltar;

  const ExerciciosTreinoPage({
    Key? key,
    required this.treino,
    required this.exercicios,
    required this.onVoltar,
  }) : super(key: key);

  @override
  State<ExerciciosTreinoPage> createState() => _ExerciciosTreinoPageState();
}

class _ExerciciosTreinoPageState extends State<ExerciciosTreinoPage> {
  bool loading = true;
  List<Map<String, dynamic>> exerciciosApi = [];
  String? erro;

  @override
  void initState() {
    super.initState();
    _carregarExercicios();
  }

  Future<void> _carregarExercicios() async {
    setState(() {
      loading = true;
      erro = null;
    });
    try {
      final treinoId = widget.treino['id'];
      if (treinoId == null) {
        setState(() {
          erro = 'ID do treino não encontrado.';
          loading = false;
        });
        return;
      }
      
      // Usar a nova API que funciona
      final url = Uri.parse('https://airfit.online/api/get_exercicios.php?id_treino=$treinoId');
      print('URL da requisição: $url');
      
      final response = await http.get(url);
      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: "${response.body.substring(0, response.body.length > 100 ? 100 : response.body.length)}..."');
      print('Tamanho do corpo: ${response.body.length}');
      
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final bodyTrimmed = response.body.trim();
          if (bodyTrimmed.startsWith('[')) {
            try {
              final List dados = jsonDecode(bodyTrimmed);
              setState(() {
                exerciciosApi = List<Map<String, dynamic>>.from(dados);
                loading = false;
              });
              print('Exercícios carregados: ${exerciciosApi.length}');
            } catch (e) {
              print('Erro ao fazer parse do JSON: $e');
              setState(() {
                erro = 'Erro ao processar dados dos exercícios';
                loading = false;
              });
            }
          } else if (bodyTrimmed.startsWith('{')) {
            try {
              final Map<String, dynamic> dados = jsonDecode(bodyTrimmed);
              if (dados.containsKey('erro')) {
                setState(() {
                  erro = 'Erro da API: ${dados['erro']}';
                  loading = false;
                });
              } else {
                setState(() {
                  erro = 'Resposta inesperada da API';
                  loading = false;
                });
              }
            } catch (e) {
              print('Erro ao fazer parse do JSON objeto: $e');
              setState(() {
                erro = 'Erro ao processar resposta da API';
                loading = false;
              });
            }
          } else {
            print('Resposta não é JSON válido: "${bodyTrimmed.substring(0, bodyTrimmed.length > 50 ? 50 : bodyTrimmed.length)}"');
            setState(() {
              erro = 'Resposta inválida da API';
              loading = false;
            });
          }
        } else {
          print('Resposta vazia da API');
          setState(() {
            erro = 'API retornou resposta vazia';
            loading = false;
          });
        }
      } else {
        setState(() {
          erro = 'Erro ao buscar exercícios (Status: ${response.statusCode})';
          loading = false;
        });
      }
    } catch (e) {
      print('Erro de conexão: $e');
      setState(() {
        erro = 'Erro de conexão: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lista = exerciciosApi;

    return Column(
      children: [
        // Cabeçalho
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : const Color(0xFF374151),
                ),
                onPressed: widget.onVoltar,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.treino['nome_treino'] ?? 'Treino',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF374151),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.treino['total_exercicios'] != null
                          ? '${widget.treino['total_exercicios']} exercício${widget.treino['total_exercicios'].toString() == '1' ? '' : 's'} neste treino'
                          : '${lista.length} exercício${lista.length == 1 ? '' : 's'} neste treino',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista de exercícios
        Expanded(
          child: loading
              ? Center(child: CircularProgressIndicator())
              : erro != null
                  ? Center(child: Text(erro!, style: TextStyle(color: Colors.red)))
                  : lista.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum exercício encontrado',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: lista.length,
                          itemBuilder: (context, index) {
                            final exercicio = lista[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 16),
                              color: isDark ? const Color(0xFF1F2937) : Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF374151)
                                      : const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercicio['nome_do_exercicio'] ?? 'Exercício',
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: isDark ? Colors.white : const Color(0xFF374151),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    if (exercicio['numero_series'] != null || exercicio['numero_repeticoes'] != null)
                                      Text(
                                        '${exercicio['numero_series'] ?? '0'} séries x ${exercicio['numero_repeticoes'] ?? '0'} repetições',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    if (exercicio['peso'] != null)
                                      Text(
                                        'Peso: ${exercicio['peso']} kg',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    if (exercicio['tempo_descanso'] != null)
                                      Text(
                                        'Descanso: ${exercicio['tempo_descanso']} segundos',
                                        style: TextStyle(
                                          color: isDark
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
} 