import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'optimized_gif_widget.dart';

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

  // NOVO: Estado para busca
  String searchQuery = '';
  List<Map<String, dynamic>> exerciciosFiltrados = [];
  TextEditingController searchController = TextEditingController();
  bool isSearching = false;

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
      
      print('🔍 Carregando exercícios iniciais: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );
      
      print('📡 Status inicial: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          print('✅ Exercícios iniciais carregados: ${data.length}');
          // Debug: verificar estrutura dos dados
          if (data.isNotEmpty) {
            print('🔍 Estrutura do primeiro exercício: ${data.first.keys.toList()}');
            print('🔍 Categoria do primeiro: ${data.first['categoria']}');
            print('🔍 Grupo do primeiro: ${data.first['grupo']}');
          }
          setState(() {
            exercicios = data.cast<Map<String, dynamic>>();
            exerciciosFiltrados = exercicios;
            isLoading = false;
          });
        } else if (data is Map && data.containsKey('erro')) {
          print('❌ Erro na API inicial: ${data['erro']}');
          setState(() {
            errorMessage = data['erro'];
            isLoading = false;
          });
        }
      } else {
        print('❌ Erro HTTP inicial: ${response.statusCode}');
        setState(() {
          errorMessage = 'Erro ao buscar exercícios: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erro de conexão inicial: $e');
      setState(() {
        errorMessage = 'Erro de conexão: $e';
        isLoading = false;
      });
    }
  }

  // NOVO: Função de busca global via API
  Future<void> _buscarExerciciosGlobal(String query) async {
    if (query.isEmpty) {
      setState(() {
        exerciciosFiltrados = exercicios;
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      // Buscar exercícios via API com busca global
      String url;
      
      if (query.trim().isEmpty) {
        // Se não há termo de busca, buscar apenas por categoria/grupo
        url = 'https://airfit.online/api/buscar_exercicios_global.php?categoria=${Uri.encodeQueryComponent(widget.categoria)}';
        if (widget.grupo != null && widget.grupo!.isNotEmpty) {
          url += '&grupo=${Uri.encodeQueryComponent(widget.grupo!)}';
        }
      } else {
        // Se há termo de busca, fazer busca global
        url = 'https://airfit.online/api/buscar_exercicios_global.php?termo=${Uri.encodeQueryComponent(query)}';
        if (widget.categoria.isNotEmpty) {
          url += '&categoria=${Uri.encodeQueryComponent(widget.categoria)}';
        }
        if (widget.grupo != null && widget.grupo!.isNotEmpty) {
          url += '&grupo=${Uri.encodeQueryComponent(widget.grupo!)}';
        }
      }
      
      print('🔍 Buscando exercícios globalmente em: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      );

      print('📡 Status da resposta: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📊 Tipo de resposta: ${data.runtimeType}');
        
        List<Map<String, dynamic>> todosExercicios = [];
        
        if (data is Map && data.containsKey('exercicios')) {
          todosExercicios = List<Map<String, dynamic>>.from(data['exercicios']);
          print('✅ Total de exercícios encontrados: ${todosExercicios.length}');
          // Debug: verificar estrutura dos dados da busca global
          if (todosExercicios.isNotEmpty) {
            print('🔍 Estrutura do primeiro exercício (busca): ${todosExercicios.first.keys.toList()}');
            print('🔍 Categoria do primeiro (busca): ${todosExercicios.first['categoria']}');
            print('🔍 Grupo do primeiro (busca): ${todosExercicios.first['grupo']}');
          }
        } else if (data is List) {
          todosExercicios = data.cast<Map<String, dynamic>>();
          print('✅ Total de exercícios encontrados (formato antigo): ${todosExercicios.length}');
          // Debug: verificar estrutura dos dados da busca global (formato antigo)
          if (todosExercicios.isNotEmpty) {
            print('🔍 Estrutura do primeiro exercício (busca antiga): ${todosExercicios.first.keys.toList()}');
            print('🔍 Categoria do primeiro (busca antiga): ${todosExercicios.first['categoria']}');
            print('🔍 Grupo do primeiro (busca antiga): ${todosExercicios.first['grupo']}');
          }
        } else {
          print('❌ Formato de resposta inesperado: $data');
          setState(() {
            exerciciosFiltrados = [];
            isSearching = false;
          });
          return;
        }
        
        // A API já retorna os exercícios filtrados, então usamos diretamente
        print('🎯 Exercícios encontrados para "$query": ${todosExercicios.length}');

        setState(() {
          exerciciosFiltrados = todosExercicios;
          isSearching = false;
        });
        print('🎯 Estado atualizado - exerciciosFiltrados.length: ${exerciciosFiltrados.length}');
      } else {
        print('❌ Erro na resposta: ${response.statusCode}');
        print('❌ Corpo da resposta: ${response.body}');
        setState(() {
          exerciciosFiltrados = [];
          isSearching = false;
        });
      }
    } catch (e) {
      print('❌ Erro na busca global: $e');
      setState(() {
        exerciciosFiltrados = [];
        isSearching = false;
      });
    }
  }

  // NOVO: Função de busca com debounce
  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
    
    // Debounce para evitar muitas requisições
    Future.delayed(const Duration(milliseconds: 300), () {
      if (searchQuery == value) {
        _buscarExerciciosGlobal(value);
      }
    });
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
        child: Column(
          children: [
            // NOVO: Campo de busca
            TextField(
              controller: searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Buscar exercício pelo nome...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF3B82F6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFF3B82F6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    print('🔍 _buildBody() - isLoading: $isLoading, isSearching: $isSearching, exerciciosFiltrados.length: ${exerciciosFiltrados.length}, searchQuery: "$searchQuery"');
    
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
    
    // Mostrar indicador de busca
    if (isSearching) {
      print('🔍 Mostrando indicador de busca...');
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Buscando exercícios...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    
    if (exerciciosFiltrados.isEmpty) {
      print('🔍 Nenhum exercício encontrado - searchQuery: "$searchQuery"');
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.fitness_center, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty ? 'Nenhum exercício encontrado' : 'Nenhum exercício encontrado',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isNotEmpty 
                ? 'Tente buscar por outro termo.'
                : 'Não há exercícios cadastrados nesta categoria ou grupo.',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    print('🔍 Exibindo ${exerciciosFiltrados.length} exercícios filtrados');
    return ListView.separated(
      itemCount: exerciciosFiltrados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final exercicio = exerciciosFiltrados[index];
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          exercicio['nome_do_exercicio'] ?? 'Exercício',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Categoria e grupo no canto direito inferior
                        Builder(
                          builder: (context) {
                            final categoria = exercicio['categoria'] ?? '';
                            final grupo = exercicio['grupo'] ?? '';
                            final deveMostrar = categoria.isNotEmpty || grupo.isNotEmpty;
                            
                            print('🔍 Card - Categoria: "$categoria", Grupo: "$grupo", Deve mostrar: $deveMostrar');
                            
                            if (deveMostrar) {
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade300, width: 0.5),
                                  ),
                                  child: Text(
                                    _formatCategoriaGrupo(exercicio['categoria'], exercicio['grupo']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
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
      return OptimizedGifWidget(
        imageUrl: fotoGif,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(12),
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

  // Função auxiliar para formatar categoria e grupo
  String _formatCategoriaGrupo(String? categoria, String? grupo) {
    final cat = categoria?.trim() ?? '';
    final grp = grupo?.trim() ?? '';
    
    print('🔍 Formatando - Categoria: "$cat", Grupo: "$grp"');
    
    if (cat.isNotEmpty && grp.isNotEmpty) {
      final resultado = '$cat • $grp';
      print('🔍 Resultado: $resultado');
      return resultado;
    } else if (cat.isNotEmpty) {
      print('🔍 Resultado: $cat');
      return cat;
    } else if (grp.isNotEmpty) {
      print('🔍 Resultado: $grp');
      return grp;
    } else {
      print('🔍 Resultado: (vazio)');
      return '';
    }
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
      return OptimizedGifWidget(
        imageUrl: fotoGif,
        width: 200,
        height: 200,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(16),
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
    // Inclui o grupo no exercício, se existir
    if (widget.grupo != null && widget.grupo!.isNotEmpty) {
      exercicio['grupo'] = widget.grupo;
    }
    // Retorna o exercício selecionado para a página anterior
    Navigator.pop(context, exercicio);
  }


} 