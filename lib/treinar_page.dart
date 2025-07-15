import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'exercicios_treino_page.dart';
import 'dart:async'; // Import para Timer

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

class ExecucaoTreinoPage extends StatefulWidget {
  final String nomeTreino;
  final List<Map<String, dynamic>> exercicios;

  const ExecucaoTreinoPage({
    Key? key,
    required this.nomeTreino,
    required this.exercicios,
  }) : super(key: key);

  @override
  State<ExecucaoTreinoPage> createState() => _ExecucaoTreinoPageState();
}

class _ExecucaoTreinoPageState extends State<ExecucaoTreinoPage> {
  int exercicioAtual = 0;
  int serieAtual = 1;
  late Stopwatch stopwatch;
  late final PageController _pageController;
  bool descansando = false;
  int tempoRestante = 0;
  Timer? timerDescanso;

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch()..start();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    stopwatch.stop();
    _pageController.dispose();
    timerDescanso?.cancel();
    super.dispose();
  }

  void avancarExercicio() {
    if (exercicioAtual < widget.exercicios.length - 1) {
      setState(() {
        exercicioAtual++;
        serieAtual = 1;
        descansando = false;
        tempoRestante = 0;
        timerDescanso?.cancel();
      });
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  void iniciarDescanso(int segundos) {
    setState(() {
      descansando = true;
      tempoRestante = segundos;
    });
    timerDescanso?.cancel();
    timerDescanso = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (tempoRestante > 1) {
        setState(() {
          tempoRestante--;
        });
      } else {
        timer.cancel();
        setState(() {
          descansando = false;
          tempoRestante = 0;
        });
      }
    });
  }

  void concluirSerie() {
    final ex = widget.exercicios[exercicioAtual];
    final totalSeries = int.tryParse(ex['numero_series']?.toString() ?? '1') ?? 1;
    final tempoDescanso = int.tryParse(ex['tempo_descanso']?.toString() ?? '0') ?? 0;
    if (serieAtual < totalSeries) {
      iniciarDescanso(tempoDescanso > 0 ? tempoDescanso : 0);
      setState(() {
        serieAtual++;
      });
    } else {
      avancarExercicio();
    }
  }

  void pularExercicio() {
    avancarExercicio();
  }

  void concluirExercicio() {
    avancarExercicio();
  }

  String formatTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '00 : $min : $sec';
  }

  @override
  Widget build(BuildContext context) {
    final exs = widget.exercicios;
    return Scaffold(
      backgroundColor: const Color(0xFFEFF4FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.nomeTreino, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF2563EB)),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF2563EB),
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(height: 2),
                StreamBuilder<int>(
                  stream: Stream.periodic(const Duration(seconds: 1), (_) => stopwatch.elapsed.inSeconds),
                  builder: (context, snapshot) {
                    final t = snapshot.data ?? 0;
                    return Text(
                      formatTime(t),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exs.length,
              itemBuilder: (context, idx) {
                final ex = exs[idx];
                final nome = (ex['nome_do_exercicio'] ?? '').toString().toUpperCase();
                final img = ex['foto_gif'] ?? '';
                final reps = ex['numero_repeticoes']?.toString() ?? '-';
                final peso = ex['peso']?.toString() ?? '-';
                final totalSeries = int.tryParse(ex['numero_series']?.toString() ?? '1') ?? 1;
                return Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: img.isNotEmpty
                                    ? Image.network('https://airfit.online/$img', width: 120, height: 120, fit: BoxFit.cover)
                                    : const Icon(Icons.image, size: 100, color: Colors.grey),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                nome,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _InfoBlock(
                                    icon: Icons.repeat,
                                    label: 'Séries',
                                    value: '${serieAtual} / $totalSeries',
                                  ),
                                  const SizedBox(width: 12),
                                  _InfoBlock(
                                    icon: Icons.cyclone,
                                    label: 'Repetições',
                                    value: reps,
                                  ),
                                  const SizedBox(width: 12),
                                  _InfoBlock(
                                    icon: Icons.fitness_center,
                                    label: 'Peso',
                                    value: '$peso kg',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              // Progressão de séries
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: _BarraProgressoSeries(
                                  total: totalSeries,
                                  atual: serieAtual,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  exs.length,
                                  (i) => Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: i == exercicioAtual ? const Color(0xFF2563EB) : Colors.grey[300],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: descansando ? null : concluirSerie,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: descansando
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.timer, size: 18, color: Colors.white),
                                                const SizedBox(width: 8),
                                                Text('Descansando... $tempoRestante s', style: const TextStyle(fontSize: 16)),
                                              ],
                                            )
                                          : const Text('Concluir série'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: concluirExercicio,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[300],
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: const Text('Concluir exercício'),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: pularExercicio,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        side: const BorderSide(color: Color(0xFF2563EB)),
                                      ),
                                      child: const Text('Pular exercício'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoBlock({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
} 

class _BarraProgressoSeries extends StatelessWidget {
  final int total;
  final int atual;
  const _BarraProgressoSeries({required this.total, required this.atual});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) =>
        Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
            height: 10,
            decoration: BoxDecoration(
              color: i < atual ? const Color(0xFF2563EB) : const Color(0xFFE0E7EF),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
} 