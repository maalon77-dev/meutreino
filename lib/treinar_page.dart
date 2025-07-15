import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercicios_treino_page.dart';

class TreinarPage extends StatefulWidget {
  final void Function(Map<String, dynamic> treino)? onTreinoSelecionado;
  TreinarPage({this.onTreinoSelecionado, Key? key}) : super(key: key);

  @override
  State<TreinarPage> createState() => _TreinarPageState();
}

class _TreinarPageState extends State<TreinarPage> {
  List<Map<String, dynamic>> treinosUsuario = [];
  bool isLoading = true;
  Map<int, String> nomesTreinos = {};

  @override
  void initState() {
    super.initState();
    _carregarTreinosUsuario();
  }

  Future<void> _carregarTreinosUsuario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      if (usuarioId != null && usuarioId > 0) {
        await _buscarTreinosUsuario(usuarioId);
        await _buscarNomesTreinos();
      }
    } catch (e) {
      print('Erro ao carregar treinos: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _buscarTreinosUsuario(int usuarioId) async {
    try {
      print('Buscando treinos para usuário ID: $usuarioId');
      final response = await http.get(
        Uri.parse('https://airfit.online/api/api.php?tabela=treinos&acao=listar_treinos_usuario&usuario_id=$usuarioId'),
      );

      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        final List<Map<String, dynamic>> treinosOrdenados = List<Map<String, dynamic>>.from(dados);
        
        print('Treinos recebidos: ${treinosOrdenados.length} registros');
        
        setState(() {
          treinosUsuario = treinosOrdenados;
        });
      } else {
        print('Erro na resposta: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar treinos: $e');
    }
  }

  Future<void> _buscarNomesTreinos() async {
    try {
      final response = await http.get(
        Uri.parse('https://airfit.online/api/api.php?tabela=treinos&acao=listar_treinos'),
      );

      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        final Map<int, String> nomes = {};
        
        for (var treino in dados) {
          nomes[treino['id']] = treino['nome'];
        }
        
        print('MAPA DE NOMES DOS TREINOS: ');
        nomes.forEach((id, nome) {
          print('id: $id nome: $nome');
        });
        
        setState(() {
          nomesTreinos = nomes;
        });
      }
    } catch (e) {
      print('Erro ao buscar nomes dos treinos: $e');
    }
  }

  String _obterNomeTreino(Map<String, dynamic> treino) {
    return treino['nome_treino'] ?? 'Treino';
  }

  void _abrirExerciciosTreino(BuildContext context, Map<String, dynamic> treino) async {
    print('Clicou no treino: ' + (treino['nome_treino'] ?? treino.toString()));
    final treinoId = treino['id'];
    if (treinoId == null) {
      print('Erro: ID do treino é nulo');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ID do treino não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('ID do treino: $treinoId');
    final url = Uri.parse('https://airfit.online/api/get_exercicios.php?id_treino=$treinoId');
    print('URL da requisição: $url');
    
    try {
      final response = await http.get(url);
      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta RAW: "${response.body}"');
      print('Tamanho do corpo: ${response.body.length}');
      print('Corpo está vazio: ${response.body.isEmpty}');
      print('Corpo trimmed: "${response.body.trim()}"');
      print('Começa com [: ${response.body.trim().startsWith('[')}');
      
      List<Map<String, dynamic>> exercicios = [];
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final bodyTrimmed = response.body.trim();
          if (bodyTrimmed.startsWith('[')) {
            try {
              final List dados = jsonDecode(bodyTrimmed);
              exercicios = List<Map<String, dynamic>>.from(dados);
              print('Exercícios encontrados: ${exercicios.length}');
              print('Dados dos exercícios: $exercicios');
            } catch (e) {
              print('Erro ao fazer parse do JSON: $e');
            }
          } else if (bodyTrimmed.startsWith('{')) {
            try {
              final Map<String, dynamic> dados = jsonDecode(bodyTrimmed);
              print('Resposta em formato de objeto: $dados');
              if (dados.containsKey('erro')) {
                print('Erro retornado pela API: ${dados['erro']}');
              }
            } catch (e) {
              print('Erro ao fazer parse do JSON objeto: $e');
            }
          } else {
            print('Resposta não é JSON válido. Conteúdo: "$bodyTrimmed"');
          }
        } else {
          print('Resposta da API está completamente vazia.');
        }
      } else {
        print('Erro na resposta: ${response.statusCode}');
        print('Corpo do erro: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar exercícios. Status: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (widget.onTreinoSelecionado != null) {
        widget.onTreinoSelecionado!({
          ...treino,
          'exercicios': exercicios,
        });
      }
    } catch (e) {
      print('Erro ao carregar exercícios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar exercícios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [const Color(0xFF111827), const Color(0xFF1F2937)]
            : [const Color(0xFFF8FAFC), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seção de treinos do usuário
            if (treinosUsuario.isNotEmpty) ...[
              Text(
                'Meus Treinos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 16),
              ...treinosUsuario.map((treino) => 
                _treinoCard(
                  context,
                  treino: treino,
                  nomeTreino: _obterNomeTreino(treino),
                )
              ).toList(),
              const SizedBox(height: 24),
            ],
            
            // Banner Treinos Personalizados
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: const AssetImage('assets/backgrounds/criar-treino.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Treinos Personalizados',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Escolha seus exercícios favoritos e crie seu treino diário personalizado.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3B82F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {},
                      child: Text(
                        'Criar Treino',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Banner Treinos Prontos
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                    : [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.rocket_launch,
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
                              'Treinos Prontos',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Escolha entre diversos treinos já prontos com todos os exercícios já estabelecidos, criados por profissionais.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF3B82F6),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {},
                      child: Text(
                        'Treinos Prontos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _treinoCard(BuildContext context, {
    required Map<String, dynamic> treino,
    required String nomeTreino,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _abrirExerciciosTreino(context, treino),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nomeTreino,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isDark ? Colors.white : const Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Text(
                  'Exercícios: ${treino['total_exercicios'] ?? 0}',
                  style: TextStyle(
                    color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 