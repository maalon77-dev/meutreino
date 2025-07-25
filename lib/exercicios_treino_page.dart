import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'treinar_page.dart';
import 'widgets/adicionar_exercicio_page.dart';
import 'widgets/optimized_gif_widget.dart';
import 'widgets/historico_evolucao_page.dart';

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
  
  // Variáveis para o histórico do treino
  int totalVezes = 0;
  String? ultimaVez;
  bool carregandoHistorico = false;

  @override
  void initState() {
    super.initState();
    _carregarExercicios();
    _carregarHistoricoTreino();
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

      // Obter o ID do usuário logado (opcional para compatibilidade)
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id') ?? 0;
      
      // Usar a nova API que funciona
      final url = usuarioId > 0 
          ? Uri.parse('https://airfit.online/api/get_exercicios.php?id_treino=$treinoId&user_id=$usuarioId')
          : Uri.parse('https://airfit.online/api/get_exercicios.php?id_treino=$treinoId');
      print('=== DEBUG CARREGAR EXERCÍCIOS ===');
      print('Treino ID: $treinoId');
      print('Usuario ID: $usuarioId');
      print('URL da requisição: $url');
      
      final response = await http.get(url);
      print('Status da resposta: ${response.statusCode}');
      
      // Sempre mostrar o corpo da resposta para debug
      print('Corpo da resposta: ${response.body}');
      
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

  String _formatarDataUltimaVez(String? dataRegistro) {
    if (dataRegistro == null) return '';
    
    try {
      final data = DateTime.parse(dataRegistro);
      
      // Array com os nomes dos dias da semana
      final diasSemana = [
        'Segunda-feira',
        'Terça-feira', 
        'Quarta-feira',
        'Quinta-feira',
        'Sexta-feira',
        'Sábado',
        'Domingo'
      ];
      
      // Retorna o nome do dia da semana
      return diasSemana[data.weekday - 1];
    } catch (e) {
      return '';
    }
  }

  void _mostrarHistoricoTreino() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.history,
                color: const Color(0xFF3B82F6),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Histórico do Treino',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (totalVezes > 0) ...[
                Text(
                  'Esse treino foi realizado $totalVezes ${totalVezes == 1 ? 'vez' : 'vezes'}',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Última vez: ${_formatarDataUltimaVez(ultimaVez)}',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ] else ...[
                Text(
                  'Ainda não realizado',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    fontSize: 16,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Fechar',
                style: TextStyle(
                  color: const Color(0xFF3B82F6),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _adicionarExercicioAoTreino(Map<String, dynamic> exercicioSelecionado) async {
    try {
      final treinoId = widget.treino['id'];
      if (treinoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: ID do treino não encontrado')),
        );
        return;
      }

      // Obter o ID do usuário logado
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      if (usuarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro: Usuário não identificado. Faça login novamente.')),
        );
        return;
      }

      // Preparar dados do exercício para inserir na tabela exercicios
      final dadosExercicio = {
        'id_treino': treinoId.toString(),
        'user_id': usuarioId.toString(), // Adicionar ID do usuário
        'nome_exercicio': exercicioSelecionado['nome_do_exercicio'] ?? 'Exercício',
        'foto_exercicio': exercicioSelecionado['foto_gif'] ?? '',
        'numero_repeticoes': '10', // Valores padrão
        'peso': '0',
        'numero_series': '3',
        'tempo_descanso': '60',
        'ordem': (exerciciosApi.length + 1).toString(), // Próxima posição na ordem
        'grupo': exercicioSelecionado['grupo'] ?? '', // Envia grupo se existir
      };

      print('Enviando dados para API: $dadosExercicio');
      
      final response = await http.post(
        Uri.parse('https://airfit.online/api/adicionar_exercicio.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: dadosExercicio,
      );
      
      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        // Verificar se a resposta é JSON válido
        String responseBody = response.body.trim();
        if (!responseBody.startsWith('{') && !responseBody.startsWith('[')) {
          print('Resposta inválida da API: $responseBody');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro: Resposta inválida da API')),
          );
          return;
        }
        
        final data = jsonDecode(responseBody);
        if (data['sucesso'] == true) {
          // Adicionar o novo exercício à lista local
          final novoExercicio = {
            'id': data['id'],
            'id_treino': treinoId,
            'user_id': usuarioId,
            'nome_do_exercicio': dadosExercicio['nome_exercicio'],
            'foto_gif': dadosExercicio['foto_exercicio'],
            'numero_repeticoes': dadosExercicio['numero_repeticoes'],
            'peso': dadosExercicio['peso'],
            'numero_series': dadosExercicio['numero_series'],
            'tempo_descanso': dadosExercicio['tempo_descanso'],
            'ordem': dadosExercicio['ordem'],
            'editado': false, // Marcar como não editado
          };

          setState(() {
            exerciciosApi.add(novoExercicio);
          });

          // Mostrar diálogo de sucesso
          _mostrarDialogoSucesso(dadosExercicio['nome_exercicio']);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao adicionar exercício: ${data['erro'] ?? 'Erro desconhecido'}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro HTTP: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Erro ao adicionar exercício: $e');
      String errorMessage = 'Erro de conexão';
      
      if (e.toString().contains('FormatException')) {
        errorMessage = 'Erro: Resposta inválida da API';
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'Erro: Sem conexão com a internet';
      } else {
        errorMessage = 'Erro: $e';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _mostrarDialogoSucesso(String nomeExercicio) {
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
                // Ícone de sucesso
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Mensagem de sucesso
                Text(
                  'Exercício adicionado com sucesso!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  nomeExercicio,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Botões
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Fecha o dialog
                          // Permanece na página do treino
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Voltar ao Treino',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.6, // Reduzido em 15% de 16
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Fecha o dialog
                          // Abre novamente a página de adicionar exercício
                          _abrirAdicionarExercicio();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Adicionar Mais',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13.6, // Reduzido em 15% de 16
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

  void _abrirAdicionarExercicio() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdicionarExercicioPage(),
      ),
    );
    // Aqui você pode tratar o resultado (exercício selecionado)
    if (resultado != null) {
      await _adicionarExercicioAoTreino(resultado);
    }
  }

  Future<void> _carregarHistoricoTreino() async {
    try {
      print('=== INICIANDO CARREGAMENTO DO HISTÓRICO ===');
      setState(() {
        carregandoHistorico = true;
      });
      
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      final treinoId = widget.treino['id'];
      
      print('Usuário ID: $usuarioId');
      print('Treino ID: $treinoId');
      
      if (usuarioId == null || treinoId == null) {
        print('Usuário ID ou Treino ID não encontrado');
        setState(() {
          carregandoHistorico = false;
        });
        return;
      }
      
      final url = Uri.parse('https://airfit.online/api/api.php?acao=historico_treino_especifico&usuario_id=$usuarioId&treino_id=$treinoId');
      print('Buscando histórico do treino: $url');
      
      final response = await http.get(url);
      print('Status da resposta do histórico: ${response.statusCode}');
      print('Corpo da resposta do histórico: ${response.body}');
      
      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        print('Dados decodificados: $dados');
        
        if (mounted) {
          setState(() {
            totalVezes = dados['total_vezes'] ?? 0;
            ultimaVez = dados['ultima_vez'];
            carregandoHistorico = false;
          });
          print('Estado atualizado - Total vezes: $totalVezes, Última vez: $ultimaVez');
        }
      } else {
        print('Erro ao buscar histórico: ${response.statusCode}');
        if (mounted) {
          setState(() {
            carregandoHistorico = false;
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar histórico do treino: $e');
      if (mounted) {
        setState(() {
          carregandoHistorico = false;
        });
      }
    }
  }

  Future<void> _salvarOrdem() async {
    try {
      final url = Uri.parse('https://airfit.online/api/reorder_exercicios.php');
      
      print('Salvando ordem dos exercícios...');
      print('Exercícios a serem enviados: ${exerciciosApi.length}');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'exercicios': exerciciosApi,
        }),
      );
      
      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['sucesso'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ordem salva com sucesso!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${responseData['erro'] ?? 'Erro desconhecido'}')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro HTTP: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Erro ao salvar ordem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro de conexão: $e')),
      );
    }
  }

  void _reordenarExercicios(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = exerciciosApi.removeAt(oldIndex);
      exerciciosApi.insert(newIndex, item);
    });
    
    _salvarOrdem();
  }

  Future<void> _editarExercicio(BuildContext context, Map<String, dynamic> exercicio, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _EditarExercicioDialog(
          exercicio: exercicio,
          index: index,
          onSave: (updatedData) {
            setState(() {
              exerciciosApi[index].addAll(updatedData);
            });
          },
        ),
      ),
        );
  }

  void _abrirHistoricoEvolucao(Map<String, dynamic> exercicio) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HistoricoEvolucaoPage(
          exercicioId: exercicio['id'],
          nomeExercicio: exercicio['nome_do_exercicio'] ?? 'Exercício',
        ),
      ),
    );
  }

  bool _isExercicioEditado(Map<String, dynamic> exercicio) {
    final editado = exercicio['editado'];
    return editado == true || editado == 1 || editado == '1';
  }

  String _getDescricaoCategoria(String categoria, String peso, String repeticoes, String series, String tempoDescanso, {String? distancia}) {
    switch (categoria) {
      case 'Com Pesos (Musculação)':
        return '$series séries • $repeticoes reps • ${peso}kg • ${tempoDescanso}s descanso';
      case 'Peso Corporal (Calistenia)':
        return '$series séries • $repeticoes repetições • ${tempoDescanso}s descanso';
      case 'Cardio / Corrida':
        return '${tempoDescanso} min • ${distancia ?? '0'}km';
      case 'Funcional':
        return '$series séries • $repeticoes reps/tempo • ${tempoDescanso}s descanso';
      case 'Alongamento / Mobilidade':
        return '$series repetições • ${tempoDescanso}s duração';
      case 'HIIT / Alta Intensidade':
        return '$series rounds • ${repeticoes}s trabalho • ${tempoDescanso}s descanso';
      case 'Isometria':
        return '$series séries • ${repeticoes}s duração • ${tempoDescanso}s descanso';
      default:
        return '$series séries • $repeticoes reps • ${peso}kg • ${tempoDescanso}s descanso';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lista = exerciciosApi;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Logo do app
            // SliverToBoxAdapter(
            //   child: Container(
            //     padding: const EdgeInsets.all(20),
            //     child: Center(
            //       child: Container(
            //         width: 80,
            //         height: 80,
            //         decoration: BoxDecoration(
            //           color: const Color(0xFF3B82F6),
            //           borderRadius: BorderRadius.circular(20),
            //           boxShadow: [
            //             BoxShadow(
            //               color: const Color(0xFF3B82F6).withOpacity(0.3),
            //               blurRadius: 12,
            //               offset: const Offset(0, 6),
            //             ),
            //           ],
            //         ),
            //         child: const Icon(
            //           Icons.fitness_center,
            //           color: Colors.white,
            //           size: 40,
            //         ),
            //       ),
            //     ),
            //   ),
            // ),

            // Cabeçalho com design moderno
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // margem menor
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: BorderRadius.circular(24), // todas as bordas arredondadas
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header com botão voltar e título
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: isDark ? Colors.white : const Color(0xFF374151),
                            ),
                            onPressed: widget.onVoltar,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.treino['nome_treino'] ?? 'Treino',
                                style: TextStyle(
                                  color: isDark ? Colors.white : const Color(0xFF111827),
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF3B82F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Ativo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (carregandoHistorico)
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          isDark ? Colors.white70 : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    )
                                  else
                                    GestureDetector(
                                      onTap: () {
                                        _mostrarHistoricoTreino();
                                      },
                                      child: Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Container dos botões com design melhorado
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1F2937) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Botão Iniciar Treino - Design Premium
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF10B981), Color(0xFF059669)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  // Verificar se todos os exercícios foram editados
                                  print('=== DEBUG INICIAR TREINO ===');
                                  for (var ex in exerciciosApi) {
                                    print('Exercício: ${ex['nome_do_exercicio']}, editado: ${ex['editado']}, tipo: ${ex['editado'].runtimeType}');
                                  }
                                  
                                  final exerciciosNaoEditados = exerciciosApi.where((ex) => !_isExercicioEditado(ex)).toList();
                                  print('Exercícios não editados: ${exerciciosNaoEditados.length}');
                                  
                                  if (exerciciosNaoEditados.isNotEmpty) {
                                    // Mostrar dialog de aviso
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          title: Row(
                                            children: [
                                              Icon(Icons.warning, color: Colors.orange, size: 24),
                                              SizedBox(width: 8),
                                              Text(
                                                'Exercícios Pendentes',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Text(
                                            'Você precisa configurar ${exerciciosNaoEditados.length} exercício(s) antes de iniciar o treino.\n\nClique no botão "EDITAR" nos exercícios destacados em vermelho para configurar os dados.',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(),
                                              child: Text(
                                                'Entendi',
                                                style: TextStyle(
                                                  color: Color(0xFF3B82F6),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  } else {
                                    // Todos os exercícios foram editados, pode iniciar o treino
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ExecucaoTreinoPage(
                                          nomeTreino: widget.treino['nome_treino'] ?? 'Treino',
                                          exercicios: exerciciosApi,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'INICIAR TREINO',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            Text(
                                              'Começar agora',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white.withOpacity(0.9),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Botão Adicionar Exercício - Design Secundário
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF374151) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
                                width: 2,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () async {
                                  final resultado = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AdicionarExercicioPage(),
                                    ),
                                  );
                                  // Aqui você pode tratar o resultado (exercício selecionado)
                                  if (resultado != null) {
                                    await _adicionarExercicioAoTreino(resultado);
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.add_rounded,
                                          color: const Color(0xFF3B82F6),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ADICIONAR EXERCÍCIO',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF374151),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            Text(
                                              'Incluir novo exercício',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: const Color(0xFF3B82F6),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Lista de exercícios ou estados de carregamento/erro
            if (loading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF3B82F6),
                    ),
                  ),
                ),
              )
            else if (erro != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        erro!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else if (lista.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 48,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum exercício encontrado',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    onReorder: _reordenarExercicios,
                    itemCount: lista.length,
                    itemBuilder: (context, index) {
                      final exercicio = lista[index];
                      final nome = exercicio['nome_do_exercicio'] ?? 'Exercício';
                      final categoria = exercicio['categoria'] ?? '';
                      final peso = exercicio['peso'] ?? '0';
                      final repeticoes = exercicio['numero_repeticoes'] ?? '0';
                      final series = exercicio['numero_series'] ?? '0';
                      final tempoDescanso = exercicio['tempo_descanso'] ?? '60';
                      final foto = exercicio['foto_gif'] ?? '';
                      final editado = _isExercicioEditado(exercicio);
                      return Container(
                        key: ValueKey(exercicio['id']),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: !editado 
                              ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)) 
                              : (isDark ? const Color(0xFF1F2937) : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: !editado 
                                ? const Color(0xFFEF4444) 
                                : Colors.black.withOpacity(0.03),
                            width: !editado ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Imagem do exercício
                              OptimizedGifWidget(
                                imageUrl: foto,
                                width: 38,
                                height: 38,
                                fit: BoxFit.cover,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(width: 12),
                              // Nome e infos
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            nome,
                                            style: TextStyle(
                                              color: isDark ? Colors.white : const Color(0xFF111827),
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (!editado) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEF4444),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'EDITAR',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      !editado 
                                          ? 'Configure os dados do exercício antes de iniciar o treino'
                                          : _getDescricaoCategoria(
                                              categoria, 
                                              peso, 
                                              repeticoes, 
                                              series, 
                                              tempoDescanso,
                                              distancia: categoria == 'Cardio / Corrida' ? exercicio['distancia']?.toString() : null,
                                            ),
                                      style: TextStyle(
                                        color: !editado ? const Color(0xFFEF4444) : Colors.grey[600],
                                        fontSize: 12,
                                        fontWeight: !editado ? FontWeight.w600 : FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Botões editar/excluir/histórico
                              Row(
                                children: [
                                  // Ícone de histórico de evolução
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        _abrirHistoricoEvolucao(exercicio);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.trending_up,
                                          color: const Color(0xFF10B981),
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        _editarExercicio(context, exercicio, index);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(Icons.edit_rounded, color: const Color(0xFF3B82F6), size: 22),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Excluir exercício'),
                                            content: Text('Deseja realmente excluir "$nome" deste treino?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true),
                                                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          try {
                                            final response = await http.post(
                                              Uri.parse('https://airfit.online/api/api.php'),
                                              body: {
                                                'tabela': 'exercicios',
                                                'acao': 'deletar',
                                                'id': exercicio['id'].toString(),
                                              },
                                            );
                                            final data = jsonDecode(response.body);
                                            if (data['sucesso'] == true) {
                                              setState(() {
                                                exerciciosApi.removeAt(index);
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Exercício excluído com sucesso!')),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Erro ao excluir: ${data['erro'] ?? 'Erro desconhecido'}')),
                                              );
                                            }
                                          } catch (e) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Erro de conexão: $e')),
                                            );
                                          }
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(Icons.delete_rounded, color: const Color(0xFF3B82F6), size: 22),
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
                  ),
                ),
              ),
              
              // Texto de instrução no final da lista
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Arraste e solte para ordenar a sequência dos exercícios',
                    style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EditarExercicioDialog extends StatefulWidget {
  final Map<String, dynamic> exercicio;
  final int index;
  final Function(Map<String, dynamic>) onSave;

  const _EditarExercicioDialog({
    required this.exercicio,
    required this.index,
    required this.onSave,
  });

  @override
  State<_EditarExercicioDialog> createState() => _EditarExercicioDialogState();
}

class _EditarExercicioDialogState extends State<_EditarExercicioDialog> {
  String? categoriaSelecionada;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _detectarCategoriaExistente();
  }

  void _detectarCategoriaExistente() {
    // Verificar se o exercício já tem uma categoria salva
    final categoriaExistente = widget.exercicio['categoria']?.toString();
    if (categoriaExistente != null && categoriaExistente.isNotEmpty) {
      // Tentar encontrar a categoria correspondente
      for (var categoria in categorias) {
        if (categoria['nome'] == categoriaExistente) {
          setState(() {
            categoriaSelecionada = categoria['id'];
          });
          break;
        }
      }
    }
  }
  
  final List<Map<String, dynamic>> categorias = [
    {
      'id': 'musculacao',
      'nome': 'Com Pesos (Musculação)',
      'descricao': 'Exercícios com halteres, barras, máquinas ou kettlebells.',
      'icon': Icons.fitness_center,
      'color': Color(0xFF3B82F6),
    },
    {
      'id': 'calistenia',
      'nome': 'Peso Corporal (Calistenia)',
      'descricao': 'Flexão, abdominal, agachamento livre, barra fixa etc.',
      'icon': Icons.accessibility_new,
      'color': Color(0xFF10B981),
    },
    {
      'id': 'cardio',
      'nome': 'Cardio / Corrida',
      'descricao': 'Corrida, caminhada, bicicleta, escada, jump rope etc.',
      'icon': Icons.directions_run,
      'color': Color(0xFFF59E0B),
    },
    {
      'id': 'funcional',
      'nome': 'Funcional',
      'descricao': 'Movimentos com cones, bolas, elásticos, corda naval etc.',
      'icon': Icons.sports_gymnastics,
      'color': Color(0xFF8B5CF6),
    },
    {
      'id': 'alongamento',
      'nome': 'Alongamento / Mobilidade',
      'descricao': 'Exercícios para flexibilidade, articulações, relaxamento.',
      'icon': Icons.self_improvement,
      'color': Color(0xFF06B6D4),
    },
    {
      'id': 'hiit',
      'nome': 'HIIT / Alta Intensidade',
      'descricao': 'Circuitos rápidos com ou sem equipamentos, estilo crossfit.',
      'icon': Icons.whatshot,
      'color': Color(0xFFEF4444),
    },
    {
      'id': 'isometria',
      'nome': 'Isometria',
      'descricao': 'Exercícios estáticos como prancha, agachamento parado.',
      'icon': Icons.pause_circle_filled,
      'color': Color(0xFF6B7280),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
                      'Editar Exercício',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
        backgroundColor: Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
                  ),
      body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: categoriaSelecionada == null
                    ? _buildSelecaoCategoria()
                    : _buildFormularioCategoria(),
      ),
    );
  }

  Widget _buildSelecaoCategoria() {
    final categoriaAtual = widget.exercicio['categoria']?.toString();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selecione a categoria do exercício:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        if (categoriaAtual != null && categoriaAtual.isNotEmpty) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Categoria atual: $categoriaAtual',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(height: 16),
        ...categorias.map((categoria) => _buildCategoriaCard(categoria)),
      ],
    );
  }

  Widget _buildCategoriaCard(Map<String, dynamic> categoria) {
    final categoriaAtual = widget.exercicio['categoria']?.toString();
    final isAtual = categoria['nome'] == categoriaAtual;
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            categoriaSelecionada = categoria['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isAtual ? categoria['color'] : Colors.grey.shade200,
              width: isAtual ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isAtual ? categoria['color'].withOpacity(0.05) : Colors.grey.shade50,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: categoria['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  categoria['icon'],
                  color: categoria['color'],
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria['nome'],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      categoria['descricao'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (isAtual) ...[
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoria['color'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ATUAL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.chevron_right,
                    color: categoria['color'],
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioCategoria() {
    final categoria = categorias.firstWhere((c) => c['id'] == categoriaSelecionada);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header da categoria selecionada
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: categoria['color'].withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: categoria['color'].withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(categoria['icon'], color: categoria['color'], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  categoria['nome'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: categoria['color'],
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    categoriaSelecionada = null;
                  });
                },
                child: Text('Alterar', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        SizedBox(height: 20),
        
        // Formulário específico para a categoria
        _buildFormularioEspecifico(categoriaSelecionada!),
      ],
    );
  }

  Widget _buildFormularioEspecifico(String categoria) {
    switch (categoria) {
      case 'musculacao':
        return _buildFormMusculacao();
      case 'calistenia':
        return _buildFormCalistenia();
      case 'cardio':
        return _buildFormCardio();
      case 'funcional':
        return _buildFormFuncional();
      case 'alongamento':
        return _buildFormAlongamento();
      case 'hiit':
        return _buildFormHIIT();
      case 'isometria':
        return _buildFormIsometria();
      default:
        return _buildFormGenerico();
    }
  }

  Widget _buildFormMusculacao() {
    final pesoController = TextEditingController();
    final repController = TextEditingController();
    final seriesController = TextEditingController();
    final descansoController = TextEditingController();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Peso (kg)', 
                pesoController, 
                'peso',
                placeholder: widget.exercicio['peso']?.toString() ?? '0',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Repetições', 
                repController, 
                'numero_repeticoes',
                placeholder: widget.exercicio['numero_repeticoes']?.toString() ?? '10',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Séries', 
                seriesController, 
                'numero_series',
                placeholder: widget.exercicio['numero_series']?.toString() ?? '3',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Descanso (s)', 
                descansoController, 
                'tempo_descanso',
                placeholder: widget.exercicio['tempo_descanso']?.toString() ?? '60',
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        _buildBotoesSalvar({
          'peso': pesoController,
          'numero_repeticoes': repController,
          'numero_series': seriesController,
          'tempo_descanso': descansoController,
        }),
      ],
    );
  }

  Widget _buildFormCalistenia() {
    final repController = TextEditingController();
    final seriesController = TextEditingController();
    final descansoController = TextEditingController();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Repetições', 
                repController, 
                'numero_repeticoes',
                placeholder: widget.exercicio['numero_repeticoes']?.toString() ?? '10',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Séries', 
                seriesController, 
                'numero_series',
                placeholder: widget.exercicio['numero_series']?.toString() ?? '3',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextField(
          'Descanso (s)', 
          descansoController, 
          'tempo_descanso',
          placeholder: widget.exercicio['tempo_descanso']?.toString() ?? '60',
        ),
        SizedBox(height: 24),
        _buildBotoesSalvar({
          'peso': TextEditingController(text: '0'),
          'numero_repeticoes': repController,
          'numero_series': seriesController,
          'tempo_descanso': descansoController,
        }),
      ],
    );
  }

  Widget _buildFormCardio() {
    final duracaoController = TextEditingController(text: widget.exercicio['tempo_descanso']?.toString() ?? '');
    final distanciaController = TextEditingController(text: widget.exercicio['distancia']?.toString() ?? '');

    return Column(
      children: [
        _buildTextField(
          'Duração (min)', 
          duracaoController, 
          'tempo_descanso',
          placeholder: widget.exercicio['tempo_descanso']?.toString() ?? '30',
        ),
        SizedBox(height: 16),
        _buildTextField(
          'Distância (km)', 
          distanciaController, 
          'distancia',
          placeholder: widget.exercicio['distancia']?.toString() ?? '5',
        ),
        SizedBox(height: 24),
        _buildBotoesSalvar({
          'peso': TextEditingController(text: '0'),
          'numero_repeticoes': TextEditingController(text: '1'),
          'numero_series': TextEditingController(text: '1'),
          'tempo_descanso': duracaoController,
          'distancia': distanciaController,
        }),
      ],
    );
  }

  Widget _buildFormFuncional() {
    final repController = TextEditingController(text: widget.exercicio['numero_repeticoes']?.toString() ?? '');
    final seriesController = TextEditingController(text: widget.exercicio['numero_series']?.toString() ?? '');
    final descansoController = TextEditingController(text: widget.exercicio['tempo_descanso']?.toString() ?? '');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Repetições/Tempo', 
                repController, 
                'numero_repeticoes',
                placeholder: widget.exercicio['numero_repeticoes']?.toString() ?? '10',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Séries', 
                seriesController, 
                'numero_series',
                placeholder: widget.exercicio['numero_series']?.toString() ?? '3',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextField(
          'Descanso (s)', 
          descansoController, 
          'tempo_descanso',
          placeholder: widget.exercicio['tempo_descanso']?.toString() ?? '60',
        ),
        SizedBox(height: 24),
        _buildBotoesSalvar({
          'peso': TextEditingController(text: '0'),
          'numero_repeticoes': repController,
          'numero_series': seriesController,
          'tempo_descanso': descansoController,
        }),
      ],
    );
  }

  Widget _buildFormAlongamento() {
    final duracaoController = TextEditingController(text: widget.exercicio['tempo_descanso']?.toString() ?? '');
    final seriesController = TextEditingController(text: widget.exercicio['numero_series']?.toString() ?? '');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Duração (s)', 
                duracaoController, 
                'tempo_descanso',
                placeholder: widget.exercicio['tempo_descanso']?.toString() ?? '30',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Repetições', 
                seriesController, 
                'numero_series',
                placeholder: widget.exercicio['numero_series']?.toString() ?? '3',
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        _buildBotoesSalvar({
          'peso': TextEditingController(text: '0'),
          'numero_repeticoes': TextEditingController(text: '1'),
          'numero_series': seriesController,
          'tempo_descanso': duracaoController,
        }),
      ],
    );
  }

  Widget _buildFormHIIT() {
    final trabalhoController = TextEditingController();
    final descansoController = TextEditingController();
    final roundsController = TextEditingController();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Trabalho (s)', 
                trabalhoController, 
                'numero_repeticoes',
                placeholder: widget.exercicio['numero_repeticoes']?.toString() ?? '30',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Descanso (s)', 
                descansoController, 
                'tempo_descanso',
                placeholder: widget.exercicio['tempo_descanso']?.toString() ?? '15',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextField(
          'Rounds', 
          roundsController, 
            'numero_series',
          placeholder: widget.exercicio['numero_series']?.toString() ?? '5',
        ),
        SizedBox(height: 24),
        _buildBotoesSalvar({
          'peso': TextEditingController(text: '0'),
          'numero_repeticoes': trabalhoController,
          'numero_series': roundsController,
          'tempo_descanso': descansoController,
        }),
      ],
    );
  }

  Widget _buildFormIsometria() {
    final duracaoController = TextEditingController(text: widget.exercicio['numero_repeticoes']?.toString() ?? '');
    final seriesController = TextEditingController(text: widget.exercicio['numero_series']?.toString() ?? '');
    final descansoController = TextEditingController(text: widget.exercicio['tempo_descanso']?.toString() ?? '');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Duração (s)', 
                duracaoController, 
                'numero_repeticoes',
                placeholder: widget.exercicio['numero_repeticoes']?.toString() ?? '30',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Séries', 
                seriesController, 
                'numero_series',
                placeholder: widget.exercicio['numero_series']?.toString() ?? '3',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        _buildTextField(
          'Descanso (s)', 
          descansoController, 
          'tempo_descanso',
          placeholder: widget.exercicio['tempo_descanso']?.toString() ?? '60',
        ),
        SizedBox(height: 24),
        _buildBotoesSalvar({
          'peso': TextEditingController(text: '0'),
          'numero_repeticoes': duracaoController,
          'numero_series': seriesController,
          'tempo_descanso': descansoController,
        }),
      ],
    );
  }

  Widget _buildFormGenerico() {
    final repController = TextEditingController(text: widget.exercicio['numero_repeticoes']?.toString() ?? '');
    final pesoController = TextEditingController(text: widget.exercicio['peso']?.toString() ?? '');
    final seriesController = TextEditingController(text: widget.exercicio['numero_series']?.toString() ?? '');
    final descansoController = TextEditingController(text: widget.exercicio['tempo_descanso']?.toString() ?? '');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Repetições', 
                repController, 
                'numero_repeticoes',
                placeholder: widget.exercicio['numero_repeticoes']?.toString() ?? '10',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Peso', 
                pesoController, 
                'peso',
                placeholder: widget.exercicio['peso']?.toString() ?? '0',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Séries', 
                seriesController, 
                'numero_series',
                placeholder: widget.exercicio['numero_series']?.toString() ?? '3',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Descanso (s)', 
                descansoController, 
                'tempo_descanso',
                placeholder: widget.exercicio['tempo_descanso']?.toString() ?? '60',
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        _buildBotoesSalvar({
          'peso': pesoController,
          'numero_repeticoes': repController,
          'numero_series': seriesController,
          'tempo_descanso': descansoController,
        }),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String field, {String? placeholder}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          enableInteractiveSelection: true,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF3B82F6)),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            hintText: placeholder,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
          onTap: () {
            // Garantir que o campo mantenha o foco
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBotoesSalvar(Map<String, TextEditingController> controllers) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Cancelar'),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: loading ? null : () => _salvarAlteracoes(controllers),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: loading 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Salvar',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _salvarAlteracoes(Map<String, TextEditingController> controllers) async {
    setState(() => loading = true);
    
    try {
      // Obter o nome da categoria selecionada
      final categoriaNome = categorias.firstWhere((c) => c['id'] == categoriaSelecionada)['nome'];
      
      // Valores atuais (anteriores)
      final pesoAnterior = double.tryParse(widget.exercicio['peso']?.toString() ?? '0') ?? 0.0;
      final repeticoesAnteriores = int.tryParse(widget.exercicio['numero_repeticoes']?.toString() ?? '0') ?? 0;
      final seriesAnteriores = int.tryParse(widget.exercicio['numero_series']?.toString() ?? '0') ?? 0;
      
      // Para duração, verificar se é isometria (usa numero_repeticoes como duração)
      final categoria = widget.exercicio['categoria']?.toString().toLowerCase() ?? '';
      final isIsometria = categoria == 'isometria';
      final duracaoAnterior = isIsometria 
          ? double.tryParse(widget.exercicio['numero_repeticoes']?.toString() ?? '0') ?? 0.0
          : double.tryParse(widget.exercicio['tempo_descanso']?.toString() ?? '0') ?? 0.0;
      final distanciaAnterior = double.tryParse(widget.exercicio['distancia']?.toString() ?? '0') ?? 0.0;
      
      // Novos valores
      final pesoNovo = double.tryParse(controllers['peso']!.text.isNotEmpty ? controllers['peso']!.text : widget.exercicio['peso']?.toString() ?? '0') ?? 0.0;
      final repeticoesNovas = int.tryParse(controllers['numero_repeticoes']!.text.isNotEmpty ? controllers['numero_repeticoes']!.text : widget.exercicio['numero_repeticoes']?.toString() ?? '0') ?? 0;
      final seriesNovas = int.tryParse(controllers['numero_series']!.text.isNotEmpty ? controllers['numero_series']!.text : widget.exercicio['numero_series']?.toString() ?? '0') ?? 0;
      
      // Para duração, verificar se é isometria (usa numero_repeticoes como duração)
      final duracaoNova = isIsometria
          ? double.tryParse(controllers['numero_repeticoes']!.text.isNotEmpty ? controllers['numero_repeticoes']!.text : widget.exercicio['numero_repeticoes']?.toString() ?? '0') ?? 0.0
          : double.tryParse(controllers['tempo_descanso']!.text.isNotEmpty ? controllers['tempo_descanso']!.text : widget.exercicio['tempo_descanso']?.toString() ?? '0') ?? 0.0;
      final distanciaNova = controllers.containsKey('distancia') 
          ? double.tryParse(controllers['distancia']!.text.isNotEmpty ? controllers['distancia']!.text : widget.exercicio['distancia']?.toString() ?? '0') ?? 0.0
          : 0.0;
      
      // Preparar dados para envio
      final dados = {
        'tabela': 'exercicios',
        'acao': 'atualizar',
        'id': widget.exercicio['id'].toString(),
        'numero_repeticoes': controllers['numero_repeticoes']!.text.isNotEmpty ? controllers['numero_repeticoes']!.text : widget.exercicio['numero_repeticoes']?.toString() ?? '',
        'peso': controllers['peso']!.text.isNotEmpty ? controllers['peso']!.text : widget.exercicio['peso']?.toString() ?? '',
        'numero_series': controllers['numero_series']!.text.isNotEmpty ? controllers['numero_series']!.text : widget.exercicio['numero_series']?.toString() ?? '',
        'tempo_descanso': controllers['tempo_descanso']!.text.isNotEmpty ? controllers['tempo_descanso']!.text : widget.exercicio['tempo_descanso']?.toString() ?? '',
        'categoria': categoriaNome, // Salvar a categoria selecionada
        'editado': '1', // Marcar como editado no banco de dados
      };
      
      // Adicionar distância se existir
      if (controllers.containsKey('distancia')) {
        dados['distancia'] = controllers['distancia']!.text.isNotEmpty ? controllers['distancia']!.text : widget.exercicio['distancia']?.toString() ?? '';
      }
      
      final response = await http.post(
        Uri.parse('https://airfit.online/api/api.php'),
        body: dados,
      );
      
      final data = jsonDecode(response.body);
      if (data['sucesso'] == true) {
        // Verificar se houve mudança (qualquer alteração) e salvar no histórico
        final houveMudanca = pesoNovo != pesoAnterior || 
                             (_deveSalvarRepeticoes(categoriaNome) && repeticoesNovas != repeticoesAnteriores) || 
                             (_deveSalvarSeries(categoriaNome) && seriesNovas != seriesAnteriores) ||
                             duracaoNova != duracaoAnterior ||
                             distanciaNova != distanciaAnterior;
        
        if (houveMudanca) {
          await _salvarEvolucao(
            pesoAnterior: pesoAnterior,
            pesoNovo: pesoNovo,
            repeticoesAnteriores: _deveSalvarRepeticoes(categoriaNome) ? repeticoesAnteriores : 0,
            repeticoesNovas: _deveSalvarRepeticoes(categoriaNome) ? repeticoesNovas : 0,
            seriesAnteriores: _deveSalvarSeries(categoriaNome) ? seriesAnteriores : 0,
            seriesNovas: _deveSalvarSeries(categoriaNome) ? seriesNovas : 0,
            duracaoAnterior: duracaoAnterior,
            duracaoNova: duracaoNova,
            distanciaAnterior: distanciaAnterior,
            distanciaNova: distanciaNova,
            nomeExercicio: widget.exercicio['nome_do_exercicio'] ?? 'Exercício',
          );
        }
        
        Navigator.of(context).pop();
        
        // Atualizar dados locais
        final dadosLocais = {
          'numero_repeticoes': controllers['numero_repeticoes']!.text.isNotEmpty ? controllers['numero_repeticoes']!.text : widget.exercicio['numero_repeticoes']?.toString() ?? '',
          'peso': controllers['peso']!.text.isNotEmpty ? controllers['peso']!.text : widget.exercicio['peso']?.toString() ?? '',
          'numero_series': controllers['numero_series']!.text.isNotEmpty ? controllers['numero_series']!.text : widget.exercicio['numero_series']?.toString() ?? '',
          'tempo_descanso': controllers['tempo_descanso']!.text.isNotEmpty ? controllers['tempo_descanso']!.text : widget.exercicio['tempo_descanso']?.toString() ?? '',
          'categoria': categoriaNome,
          'editado': true, // Marcar como editado
        };
        
        // Adicionar distância se existir
        if (controllers.containsKey('distancia')) {
          dadosLocais['distancia'] = controllers['distancia']!.text.isNotEmpty ? controllers['distancia']!.text : widget.exercicio['distancia']?.toString() ?? '';
        }
        
        widget.onSave(dadosLocais);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(houveMudanca ? 'Exercício atualizado e histórico salvo!' : 'Exercício atualizado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar: ${data['erro'] ?? 'Erro desconhecido'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() => loading = false);
  }

  bool _deveSalvarRepeticoes(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    return categoriaLower.contains('musculação') || 
           categoriaLower.contains('calistenia') || 
           categoriaLower.contains('funcional') ||
           categoriaLower.contains('hiit');
  }

  bool _deveSalvarSeries(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    return categoriaLower.contains('musculação') || 
           categoriaLower.contains('calistenia') || 
           categoriaLower.contains('funcional') ||
           categoriaLower.contains('hiit') ||
           categoriaLower.contains('isometria');
  }

  Future<void> _salvarEvolucao({
    required double pesoAnterior,
    required double pesoNovo,
    required int repeticoesAnteriores,
    required int repeticoesNovas,
    required int seriesAnteriores,
    required int seriesNovas,
    required double duracaoAnterior,
    required double duracaoNova,
    required double distanciaAnterior,
    required double distanciaNova,
    required String nomeExercicio,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      if (usuarioId == null) {
        print('Usuário não identificado para salvar evolução');
        return;
      }

      final dadosEvolucao = {
        'usuario_id': usuarioId,
        'exercicio_id': widget.exercicio['id'],
        'nome_exercicio': nomeExercicio,
        'categoria': widget.exercicio['categoria'] ?? '',
        'peso_anterior': pesoAnterior,
        'peso_novo': pesoNovo,
        'repeticoes_anteriores': repeticoesAnteriores,
        'repeticoes_novas': repeticoesNovas,
        'series_anteriores': seriesAnteriores,
        'series_novas': seriesNovas,
        'duracao_anterior': duracaoAnterior,
        'duracao_nova': duracaoNova,
        'distancia_anterior': distanciaAnterior,
        'distancia_nova': distanciaNova,
        'observacoes': '',
      };

      final response = await http.post(
        Uri.parse('https://airfit.online/api/salvar_evolucao.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(dadosEvolucao),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sucesso'] == true) {
          print('Evolução salva com sucesso: ${data['id_evolucao']}');
        } else {
          print('Erro ao salvar evolução: ${data['mensagem']}');
        }
      } else {
        print('Erro HTTP ao salvar evolução: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao salvar evolução: $e');
    }
  }
} 