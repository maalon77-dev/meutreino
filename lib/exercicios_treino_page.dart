import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'treinar_page.dart';

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
    final repController = TextEditingController(text: exercicio['numero_repeticoes']?.toString() ?? '');
    final pesoController = TextEditingController(text: exercicio['peso']?.toString() ?? '');
    final seriesController = TextEditingController(text: exercicio['numero_series']?.toString() ?? '');
    final descansoController = TextEditingController(text: exercicio['tempo_descanso']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    bool loading = false;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Editar Exercício', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text('Número de Repetições', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B47DC))),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: repController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Informe as repetições' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Peso', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B47DC))),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: pesoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Informe o peso' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Número de Séries', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B47DC))),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: seriesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Informe as séries' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Tempo de Descanso', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B47DC))),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: descansoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Informe o descanso' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: loading ? null : () async {
                    if (!formKey.currentState!.validate()) return;
                    setState(() => loading = true);
                    try {
                      final response = await http.post(
                        Uri.parse('https://airfit.online/api/api.php'),
                        body: {
                          'tabela': 'exercicios',
                          'acao': 'atualizar',
                          'id': exercicio['id'].toString(),
                          'numero_repeticoes': repController.text,
                          'peso': pesoController.text,
                          'numero_series': seriesController.text,
                          'tempo_descanso': descansoController.text,
                        },
                      );
                      final data = jsonDecode(response.body);
                      if (data['sucesso'] == true) {
                        Navigator.of(context).pop();
                        setState(() {
                          exerciciosApi[index]['numero_repeticoes'] = repController.text;
                          exerciciosApi[index]['peso'] = pesoController.text;
                          exerciciosApi[index]['numero_series'] = seriesController.text;
                          exerciciosApi[index]['tempo_descanso'] = descansoController.text;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Exercício atualizado com sucesso!')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erro ao atualizar: \\${data['erro'] ?? 'Erro desconhecido'}')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro de conexão: \\$e')),
                      );
                    }
                    setState(() => loading = false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Salvar Mudanças'),
                ),
                TextButton(
                  onPressed: loading ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF9CA3AF),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  child: const Text('Fechar'),
                ),
              ],
            );
          },
        );
      },
    );
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
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),

            // Cabeçalho com design moderno
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937) : Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
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
                                      color: const Color(0xFF10B981),
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
                                  Text(
                                    'Ainda não realizado',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Botão Iniciar Treino
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExecucaoTreinoPage(
                                nomeTreino: widget.treino['nome_treino'] ?? 'Treino',
                                exercicios: exerciciosApi,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'INICIAR TREINO AGORA',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Botão Adicionar Exercício
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Implementar adicionar exercício
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Adicionar exercício...')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'ADICIONAR EXERCÍCIO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Texto de instrução
                    Text(
                      'Arraste e solte para ordenar a sequência dos exercícios',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
                      const Color(0xFF10B981),
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
                      final peso = exercicio['peso'] ?? '0';
                      final repeticoes = exercicio['numero_repeticoes'] ?? '0';
                      final series = exercicio['numero_series'] ?? '0';
                      final foto = exercicio['foto_gif'] ?? '';
                      return Container(
                        key: ValueKey(exercicio['id']),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1F2937) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: Colors.black.withOpacity(0.03),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Imagem do exercício
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: foto.isNotEmpty
                                    ? Image.network(
                                        'https://airfit.online/$foto',
                                        width: 38,
                                        height: 38,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(Icons.image_not_supported, size: 32, color: Colors.grey[400]),
                                      )
                                    : Icon(Icons.image, size: 32, color: Colors.grey[400]),
                              ),
                              const SizedBox(width: 12),
                              // Nome e infos
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nome,
                                      style: TextStyle(
                                        color: isDark ? Colors.white : const Color(0xFF111827),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 2,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Peso: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                            Text('$peso' 'kg', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Repetições: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                            Text('$repeticoes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Séries: ', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                            Text('$series', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Botões editar/excluir
                              Row(
                                children: [
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
          ],
        ),
      ),
    );
  }
} 