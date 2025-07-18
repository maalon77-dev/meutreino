import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import para Timer
import 'home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

class HomePageWithIndex extends StatefulWidget {
  final int initialIndex;
  
  const HomePageWithIndex({Key? key, required this.initialIndex}) : super(key: key);

  @override
  State<HomePageWithIndex> createState() => _HomePageWithIndexState();
}

class _HomePageWithIndexState extends State<HomePageWithIndex> {
  @override
  Widget build(BuildContext context) {
    return HomePage(initialIndex: widget.initialIndex);
  }
}

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
        final dynamic dados = jsonDecode(response.body);
        final Map<int, String> nomes = {};
        
        if (dados is List) {
          for (var treino in dados) {
            if (treino is Map<String, dynamic>) {
              nomes[treino['id']] = treino['nome'];
            }
          }
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
              exercicios = dados.map((item) => Map<String, dynamic>.from(item)).toList();
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF8FAFC), const Color(0xFFE0E7FF)],
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
                  color: const Color(0xFF374151),
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
                    color: Colors.black.withOpacity(0.15),
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
                          color: const Color(0xFF3B82F6),
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
                  colors: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                          color: const Color(0xFF3B82F6),
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
    return GestureDetector(
      onTap: () => _abrirExerciciosTreino(context, treino),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nomeTreino,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: const Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Text(
                  'Exercícios: ${treino['total_exercicios'] ?? 0}',
                  style: TextStyle(
                    color: const Color(0xFF6B7280),
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

class _ExecucaoTreinoPageState extends State<ExecucaoTreinoPage> 
    with TickerProviderStateMixin {
  int exercicioAtual = 0;
  int serieAtual = 1;
  late Stopwatch stopwatch;
  late final PageController _pageController;
  bool descansando = false;
  int tempoRestante = 0;
  Timer? timerDescanso;
  Timer? timerCronometro;
  int tempoTotalTreino = 0;
  int _selectedIndex = 2; // Treinar
  
  // Controladores de animação
  late AnimationController _glowController;
  late AnimationController _buttonController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _glowAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inicializar de forma assíncrona
    _inicializarTreino();
    
    _pageController = PageController(initialPage: 0);
    
    // Inicializar animações
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _progressController.forward();
    _fadeController.forward();
    
    // Inicializar timer para atualizar o cronômetro
    timerCronometro = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final tempoAtual = await _obterTempoTotalTreino();
      setState(() {
        tempoTotalTreino = tempoAtual;
      });
      
      // Verificar timeout de 5 horas
      if (tempoAtual >= 5 * 60 * 60) { // 5 horas em segundos
        print('Timeout de 5 horas atingido - resetando cronômetro');
        timer.cancel();
        await _limparCronometroPersistente();
        stopwatch.reset();
        stopwatch.start();
        await _salvarInicioTreino();
        setState(() {
          tempoTotalTreino = 0;
        });
        
        // Reiniciar o timer após timeout
        timerCronometro = Timer.periodic(const Duration(seconds: 1), (newTimer) async {
          final novoTempoAtual = await _obterTempoTotalTreino();
          setState(() {
            tempoTotalTreino = novoTempoAtual;
          });
          print('Cronômetro reiniciado: ${formatTime(novoTempoAtual)}');
        });
        
        return; // Sair da função atual
      }
      
      print('Cronômetro atualizado: ${formatTime(tempoAtual)}');
    });
  }

  @override
  void dispose() {
    stopwatch.stop();
    _pageController.dispose();
    timerDescanso?.cancel();
    timerCronometro?.cancel();
    _glowController.dispose();
    _buttonController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
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

  Future<void> _trocarExercicioComFade() async {
    // Fade out
    await _fadeController.reverse();
    
    // Lógica para avançar exercício
    if (exercicioAtual < widget.exercicios.length - 1) {
      setState(() {
        exercicioAtual++;
        serieAtual = 1;
        descansando = false;
        tempoRestante = 0;
        timerDescanso?.cancel();
      });
    }
    
    // Fade in
    await _fadeController.forward();
  }

  Future<void> _pularExercicioComFade() async {
    // Fade out
    await _fadeController.reverse();
    
    setState(() {
      // Move o exercício atual (posição 0) para o final da lista de não concluídos
      final exercicioPulado = widget.exercicios.removeAt(0);
      
      // Encontrar a posição onde inserir (antes dos concluídos)
      int posicaoInsercao = widget.exercicios.length;
      for (int i = 0; i < widget.exercicios.length; i++) {
        if (widget.exercicios[i]['concluido'] == true) {
          posicaoInsercao = i;
          break;
        }
      }
      
      // Inserir o exercício pulado antes dos concluídos
      widget.exercicios.insert(posicaoInsercao, exercicioPulado);
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      // Resetar variáveis do treino - o próximo exercício não concluído se torna o principal
      exercicioAtual = 0;
      serieAtual = 1;
      descansando = false;
      tempoRestante = 0;
      timerDescanso?.cancel();
    });
    
    // Salvar o estado atualizado dos exercícios
    await _salvarEstadoExercicios();
    
    // Fade in
    await _fadeController.forward();
  }

  void iniciarDescanso(int segundos) {
    setState(() {
      descansando = true;
      tempoRestante = segundos;
    });
    timerDescanso?.cancel();
    timerDescanso = Timer.periodic(const Duration(seconds: 1), (timer) async {
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
        // Vibrar 5 vezes ao terminar o descanso
        if (await Vibration.hasVibrator() ?? false) {
          for (int i = 0; i < 5; i++) {
            Vibration.vibrate(duration: 200);
            await Future.delayed(const Duration(milliseconds: 250));
          }
        }
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
    _pularExercicioComFade();
  }

  void concluirExercicio() {
    _concluirExercicioComFade();
  }

  Future<void> _concluirExercicioComFade() async {
    // Fade out
    await _fadeController.reverse();
    
    setState(() {
      // Marcar o exercício atual como concluído
      widget.exercicios[0]['concluido'] = true;
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      // Resetar variáveis do treino
      exercicioAtual = 0;
      serieAtual = 1;
      descansando = false;
      tempoRestante = 0;
      timerDescanso?.cancel();
    });
    
    // Salvar o estado atualizado dos exercícios
    await _salvarEstadoExercicios();
    
    // Fade in
    await _fadeController.forward();
    
    // Verificar se todos os exercícios foram concluídos
    await _verificarConclusaoTreino();
  }

  Future<void> _trocarParaExercicioComFade(int idx) async {
    // Verificar se o exercício está concluído - se estiver, não permitir seleção
    if (widget.exercicios[idx]['concluido'] == true) {
      return; // Não fazer nada se o exercício já foi concluído
    }
    
    // Fade out
    await _fadeController.reverse();
    
    setState(() {
      final item = widget.exercicios.removeAt(idx);
      widget.exercicios.insert(0, item);
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      exercicioAtual = 0;
      serieAtual = 1;
      descansando = false;
      tempoRestante = 0;
      timerDescanso?.cancel();
    });
    
    // Salvar o estado atualizado dos exercícios
    await _salvarEstadoExercicios();
    
    // Fade in
    await _fadeController.forward();
  }

  Future<void> _inicializarCronometroPersistente() async {
    final prefs = await SharedPreferences.getInstance();
    final tempoInicioSalvo = prefs.getInt('treino_inicio_timestamp');
    final nomeTreinoSalvo = prefs.getString('treino_nome_ativo');
    
    if (tempoInicioSalvo != null && nomeTreinoSalvo == widget.nomeTreino) {
      // Verificar se passou mais de 5 horas (5 * 60 * 60 * 1000 = 18000000 ms)
      final agora = DateTime.now().millisecondsSinceEpoch;
      final tempoDecorrido = agora - tempoInicioSalvo;
      final cincoHoras = 5 * 60 * 60 * 1000; // 5 horas em milliseconds
      
      if (tempoDecorrido >= cincoHoras) {
        // Timeout de 5 horas - resetar cronômetro
        print('Timeout de 5 horas atingido - resetando cronômetro');
        await _limparCronometroPersistente();
        stopwatch = Stopwatch()..start();
        await _salvarInicioTreino();
      } else {
        // Cronômetro continua do ponto onde parou
        stopwatch = Stopwatch()..start();
        print('Cronômetro restaurado: ${tempoDecorrido ~/ 1000}s já decorridos');
      }
    } else {
      // Primeiro treino ou treino diferente - iniciar novo cronômetro
      stopwatch = Stopwatch()..start();
      await _salvarInicioTreino();
      print('Novo cronômetro iniciado');
    }
    
    // Inicializar o tempo total do treino
    tempoTotalTreino = await _obterTempoTotalTreino();
  }

  Future<void> _salvarInicioTreino() async {
    final prefs = await SharedPreferences.getInstance();
    final agora = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('treino_inicio_timestamp', agora);
    await prefs.setString('treino_nome_ativo', widget.nomeTreino);
    print('Início do treino salvo: ${DateTime.now()}');
  }

  Future<void> _salvarEstadoExercicios() async {
    final prefs = await SharedPreferences.getInstance();
    final estadoExercicios = widget.exercicios.map((exercicio) {
      return {
        'nome': exercicio['nome_do_exercicio'],
        'concluido': exercicio['concluido'] ?? false,
      };
    }).toList();
    
    final estadoJson = jsonEncode(estadoExercicios);
    await prefs.setString('estado_exercicios_${widget.nomeTreino}', estadoJson);
    print('Estado dos exercícios salvo: ${estadoExercicios.length} exercícios');
  }

  Future<void> _restaurarEstadoExercicios() async {
    final prefs = await SharedPreferences.getInstance();
    final estadoSalvo = prefs.getString('estado_exercicios_${widget.nomeTreino}');
    
    if (estadoSalvo != null) {
      try {
        final List<dynamic> estadoExercicios = jsonDecode(estadoSalvo);
        
        // Aplicar o estado salvo aos exercícios
        for (var exercicio in widget.exercicios) {
          final estadoSalvoExercicio = estadoExercicios.firstWhere(
            (e) => e['nome'] == exercicio['nome_do_exercicio'],
            orElse: () => null,
          );
          
          if (estadoSalvoExercicio != null) {
            exercicio['concluido'] = estadoSalvoExercicio['concluido'];
          }
        }
        
        print('Estado dos exercícios restaurado: ${estadoExercicios.length} exercícios');
      } catch (e) {
        print('Erro ao restaurar estado dos exercícios: $e');
      }
    }
  }

  Future<void> _limparCronometroPersistente() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('treino_inicio_timestamp');
    await prefs.remove('treino_nome_ativo');
    await prefs.remove('estado_exercicios_${widget.nomeTreino}');
    print('Cronômetro persistente e estado dos exercícios limpos');
  }

  Future<void> _inicializarTreino() async {
    // 1. Primeiro restaurar o estado dos exercícios
    await _restaurarEstadoExercicios();
    
    // 2. Verificar se todos os exercícios estão concluídos e resetar se necessário
    await _verificarEResetarExercicios();
    
    // 3. Inicializar cronômetro persistente
    await _inicializarCronometroPersistente();
    
    print('Treino inicializado com estado restaurado');
  }

  void _reorganizarLista() {
    // Separar exercícios não concluídos dos concluídos
    final List<Map<String, dynamic>> naoConcluidos = [];
    final List<Map<String, dynamic>> concluidos = [];
    
    for (var exercicio in widget.exercicios) {
      if (exercicio['concluido'] == true) {
        concluidos.add(exercicio);
      } else {
        naoConcluidos.add(exercicio);
      }
    }
    
    // Recompor a lista: não concluídos primeiro, concluídos depois
    widget.exercicios.clear();
    widget.exercicios.addAll(naoConcluidos);
    widget.exercicios.addAll(concluidos);
    
    print('Lista reorganizada: ${naoConcluidos.length} não concluídos, ${concluidos.length} concluídos');
  }

  Future<void> _verificarEResetarExercicios() async {
    final todosExerciciosConcluidos = widget.exercicios.every((ex) => ex['concluido'] == true);
    if (todosExerciciosConcluidos) {
      // Se todos estão concluídos, resetar todos os exercícios para disponíveis
      for (var exercicio in widget.exercicios) {
        exercicio['concluido'] = false;
      }
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      // Salvar o estado resetado
      await _salvarEstadoExercicios();
      
      print('Todos os exercícios foram resetados - treino reiniciado');
    } else {
      // Se nem todos estão concluídos, manter o estado atual
      // Apenas reorganizar para garantir que concluídos fiquem no final
      _reorganizarLista();
      print('Exercícios mantidos no estado atual - alguns ainda pendentes');
    }
  }

  Future<void> _resetarTodosExercicios() async {
    setState(() {
      // Resetar todos os exercícios
      for (var exercicio in widget.exercicios) {
        exercicio['concluido'] = false;
      }
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      // Resetar variáveis do treino
      exercicioAtual = 0;
      serieAtual = 1;
      descansando = false;
      tempoRestante = 0;
      timerDescanso?.cancel();
      
      // Reiniciar cronômetro persistente
      stopwatch.reset();
      stopwatch.start();
    });
    
    // Reiniciar cronômetro persistente
    await _limparCronometroPersistente();
    await _salvarInicioTreino();
    
    // Salvar o estado resetado dos exercícios
    await _salvarEstadoExercicios();
    
    print('Treino resetado - todos os exercícios disponíveis novamente');
  }

  Future<void> _verificarConclusaoTreino() async {
    final todosExerciciosConcluidos = widget.exercicios.every((ex) => ex['concluido'] == true);
    if (todosExerciciosConcluidos) {
      stopwatch.stop();
      timerCronometro?.cancel(); // Parar o timer quando concluir
      await _mostrarPopupConclusao();
    }
  }

  Future<void> _mostrarPopupConclusao() async {
    final tempoTotal = await _obterTempoTotalTreino();
    final TextEditingController kmController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 8),
              Text('Treino Concluído!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parabéns! Você concluiu todos os exercícios.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Text(
                'Tempo Total: ${formatTime(tempoTotal)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: kmController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantos KM foram percorridos?',
                  hintText: 'Ex: 5.5',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixText: 'KM',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Resetar exercícios para continuar treinando
                _resetarTodosExercicios();
              },
              child: Text('Continuar Treinando'),
            ),
            ElevatedButton(
              onPressed: () {
                final kmPercorridos = double.tryParse(kmController.text) ?? 0.0;
                _salvarTreinoCompleto(tempoTotal, kmPercorridos);
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Voltar para a tela anterior
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text('Salvar e Sair'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _salvarTreinoCompleto(int tempoSegundos, double kmPercorridos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      print('Salvando treino: usuarioId=$usuarioId, nome=${widget.nomeTreino}, tempo=$tempoSegundos, km=$kmPercorridos');
      
      if (usuarioId != null) {
        final url = Uri.parse('https://airfit.online/api/historico_treinos.php');
        final body = {
          'usuario_id': usuarioId.toString(),
          'nome_treino': widget.nomeTreino,
          'tempo_total': tempoSegundos.toString(),
          'km_percorridos': kmPercorridos.toString(),
          'data_treino': DateTime.now().toIso8601String(),
        };
        
        print('URL: $url');
        print('Body: $body');
        
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        );
        
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          try {
            final responseData = jsonDecode(response.body);
            if (responseData['sucesso'] == true) {
              // Limpar cronômetro persistente e estado dos exercícios após salvar com sucesso
              await _limparCronometroPersistente();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Treino salvo com sucesso!'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              throw Exception(responseData['erro'] ?? 'Erro desconhecido');
            }
          } catch (jsonError) {
            print('Erro ao decodificar JSON: $jsonError');
            throw Exception('Resposta inválida do servidor');
          }
        } else {
          throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
        }
      } else {
        throw Exception('Usuário não logado');
      }
    } catch (e) {
      print('Erro ao salvar treino: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar treino: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final min = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$hours : $min : $sec';
  }

  Future<int> _obterTempoTotalTreino() async {
    final prefs = await SharedPreferences.getInstance();
    final tempoInicioSalvo = prefs.getInt('treino_inicio_timestamp');
    final nomeTreinoSalvo = prefs.getString('treino_nome_ativo');
    
    if (tempoInicioSalvo != null && nomeTreinoSalvo == widget.nomeTreino) {
      final agora = DateTime.now().millisecondsSinceEpoch;
      final tempoDecorrido = agora - tempoInicioSalvo;
      return tempoDecorrido ~/ 1000; // Converter para segundos
    } else {
      return stopwatch.elapsed.inSeconds;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exs = widget.exercicios;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      drawer: CustomDrawer(
        onMenuTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: const Color(0xFF374151),
        ),
        title: Text(
          widget.nomeTreino,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: const Color(0xFF374151),
            ),
            onPressed: () {
              // Função de notificação
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFF8FAFC), const Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          itemCount: exs.length,
          itemBuilder: (context, idx) {
            if (idx == 0) {
              // Exercício ativo - Design futurista completamente novo
              final ex = exs[0];
              final nome = (ex['nome_do_exercicio'] ?? '').toString().toUpperCase();
              final img = ex['foto_gif'] ?? '';
              final reps = ex['numero_repeticoes']?.toString() ?? '-';
              final peso = ex['peso']?.toString() ?? '-';
              final totalSeries = int.tryParse(ex['numero_series']?.toString() ?? '1') ?? 1;
              
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                  child: AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, child) {
                      return Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                                offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Container(
                            decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFF3B82F6).withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Conteúdo principal
                              Padding(
                                padding: const EdgeInsets.all(28),
                                                                 child: Column(
                                   children: [
                                                                        // Header com timer
                                   _buildHolographicHeader(false),
                                     const SizedBox(height: 24),
                                     
                                     // Layout com GIF como fundo suave
                                   _buildGifBackgroundLayout(img, nome, reps, peso, totalSeries, false),
                                     const SizedBox(height: 24),
                                     
                                   // Barra de progresso
                                   _buildFuturisticProgressBar(totalSeries, false),
                                     const SizedBox(height: 28),
                                     
                                   // Painel de controle
                                   _buildFuturisticControlPanel(false),
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
                ),
              );
            } else {
              // Exercícios não ativos - Card menor e minimalista
              final ex = exs[idx];
              final nome = (ex['nome_do_exercicio'] ?? '').toString();
              final img = ex['foto_gif'] ?? '';
              final isConcluido = ex['concluido'] == true;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isConcluido 
                        ? const Color(0xFFE8F5E8) // Verde claro para concluído
                        : const Color(0xFFF5F5F5), // Cinza para pendente
                    borderRadius: BorderRadius.circular(16),
                    border: isConcluido 
                        ? Border.all(color: const Color(0xFF4CAF50), width: 1)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // GIF pausado à esquerda
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: img.isNotEmpty
                                  ? Image.network(
                                      'https://airfit.online/$img',
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      // Simula GIF pausado mostrando apenas o primeiro frame
                                      gaplessPlayback: true,
                                    )
                                  : Icon(
                                      Icons.image,
                                      size: 24,
                                      color: Colors.grey[500],
                                    ),
                            ),
                            // Overlay indicando estado do exercício apenas para concluídos
                            if (isConcluido)
                            Container(
                              decoration: BoxDecoration(
                                  color: const Color(0xFF4CAF50).withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(12),
                              ),
                                child: Center(
                                child: Icon(
                                    Icons.check_circle,
                                  color: Colors.white,
                                    size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Nome do exercício no centro
                      Expanded(
                          child: Text(
                            nome,
                            style: GoogleFonts.poppins(
                            color: isConcluido 
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFF2A2A2A),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            decoration: isConcluido 
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            ),
                          maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Botão de play à direita ou ícone de concluído
                      isConcluido
                          ? Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            )
                          : GestureDetector(
                          onTap: () {
                            _trocarParaExercicioComFade(idx);
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCDFF47),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                                child: Icon(
                              Icons.play_arrow,
                              color: Colors.black,
                              size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Home', 0, _selectedIndex),
                _buildNavItem(Icons.event_note_outlined, 'Histórico', 1, _selectedIndex),
                _buildNavItem(Icons.sports_gymnastics, 'Treinar', 2, _selectedIndex),
                _buildNavItem(Icons.psychology_alt_outlined, 'Assistente', 3, _selectedIndex),
                _buildNavItem(Icons.person_outline, 'Perfil', 4, _selectedIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Novos widgets para o design futurista
  Widget _buildHolographicHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'TREINO ATIVO',
            style: GoogleFonts.poppins(
              color: const Color(0xFF3B82F6),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.green,
                width: 1,
              ),
            ),
            child: Text(
              formatTime(tempoTotalTreino),
              style: GoogleFonts.poppins(
                color: Colors.green,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

     Widget _buildGifBackgroundLayout(String img, String nome, String reps, String peso, int totalSeries, bool isDark) {
     return Container(
       height: 200,
       child: Container(
         width: double.infinity,
           height: 180,
         decoration: BoxDecoration(
             color: Colors.white, // Fundo branco
           borderRadius: BorderRadius.circular(20),
           // Removendo boxShadow (bordas/sombras)
         ),
         child: Stack(
           clipBehavior: Clip.none,
           children: [
             // GIF integrado no lado direito do mesmo card - altura aumentada em 30%
             Positioned(
               right: -20, // Movido de -40 para -20 (20px mais para a esquerda)
               top: 0,
               child: Container(
                 width: 200,
                 height: 180,
                 child: ClipRRect(
                   borderRadius: BorderRadius.circular(20), // Cantos arredondados completos
                   child: img.isNotEmpty
                       ? Image.network(
                           'https://airfit.online/$img',
                           fit: BoxFit.cover,
                           width: 200,
                           height: 180,
                         )
                       : Container(
                           color: Colors.white,
                           child: Icon(
                             Icons.image,
                             size: 80,
                             color: Colors.grey[400],
                           ),
                         ),
                 ),
               ),
             ),
             
                          // Conteúdo principal (textos) posicionado mais à esquerda
             Positioned(
               left: 16,
               top: 16,
               bottom: 16,
               right: 100, // Aumentado para dar mais espaço ao GIF
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                                       // Título melhorado - posicionado mais à esquerda
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     child: Text(
                       nome,
                       style: GoogleFonts.poppins(
                         color: Colors.black,
                         fontWeight: FontWeight.w700,
                         fontSize: 14,
                         letterSpacing: 0.3,
                         height: 1.2,
                         shadows: [
                           Shadow(
                             color: Colors.white.withOpacity(0.3),
                             blurRadius: 1,
                             offset: const Offset(0.5, 0.5),
                       ),
                         ],
                       ),
                       maxLines: 3,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   
                   const Spacer(),
                   
                   // Estatísticas melhoradas e destacadas
                   _buildEnhancedStats(reps, peso, totalSeries),
                 ],
               ),
             ),
           ],
         ),
       ),
     );
   }



   Widget _buildHorizontalGifLayout(String img, String nome, String reps, String peso, int totalSeries, bool isDark) {
     return Container(
       height: 180,
       child: Stack(
         children: [
           // GIF como fundo
           Container(
             decoration: BoxDecoration(
               color: const Color(0xFFE8E8E8), // Cinza claro como na imagem
               borderRadius: BorderRadius.circular(24),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.08),
                   blurRadius: 16,
                   offset: const Offset(0, 4),
                 ),
               ],
             ),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(24),
               child: img.isNotEmpty
                   ? Image.network(
                       'https://airfit.online/$img',
                       fit: BoxFit.cover,
                       width: double.infinity,
                       height: double.infinity,
                     )
                   : Container(
                       width: double.infinity,
                       height: double.infinity,
                       decoration: BoxDecoration(
                         color: const Color(0xFFE8E8E8),
                         borderRadius: BorderRadius.circular(24),
                       ),
                       child: Icon(
                         Icons.image,
                         size: 60,
                         color: Colors.grey[500],
                       ),
                     ),
             ),
           ),
           
           // Overlay suave para legibilidade
           Container(
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 colors: [
                   Colors.black.withValues(alpha: 0.4),
                   Colors.black.withValues(alpha: 0.1),
                   Colors.black.withValues(alpha: 0.5),
                 ],
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
               ),
               borderRadius: BorderRadius.circular(24),
             ),
           ),
           
           // Textos sobrepostos
           Positioned.fill(
             child: Padding(
               padding: const EdgeInsets.all(20),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   // Título no topo
                   Flexible(
                     child: Text(
                       nome,
                       style: GoogleFonts.poppins(
                         color: Colors.white,
                         fontWeight: FontWeight.w600,
                         fontSize: 18,
                         letterSpacing: 0.3,
                         shadows: [
                           Shadow(
                             color: Colors.black.withValues(alpha: 0.6),
                             blurRadius: 3,
                             offset: const Offset(0, 1),
                           ),
                         ],
                       ),
                       softWrap: true,
                       overflow: TextOverflow.visible,
                     ),
                   ),
                   
                   // Estatísticas na parte inferior
                   _buildCleanStats(reps, peso, totalSeries, isDark),
                 ],
               ),
             ),
           ),
         ],
       ),
     );
   }

   Widget _buildCleanStats(String reps, String peso, int totalSeries, bool isDark) {
     return Row(
       children: [
         // Estatística principal (Séries) - Verde limão
         Expanded(
           child: Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: const Color(0xFFCDFF47), // Verde limão como na imagem
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                   blurRadius: 8,
                   offset: const Offset(0, 2),
                 ),
               ],
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(
                   'Séries',
                   style: GoogleFonts.poppins(
                     color: Colors.black,
                     fontSize: 11,
                     fontWeight: FontWeight.w500,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
                 const SizedBox(height: 2),
                 Text(
                   '$serieAtual / $totalSeries',
                   style: GoogleFonts.poppins(
                     color: Colors.black,
                     fontSize: 16,
                     fontWeight: FontWeight.w700,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ],
             ),
           ),
         ),
         
         const SizedBox(width: 8),
         
         // Estatística secundária (Repetições) - Preto
         Expanded(
           child: Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: const Color(0xFF2A2A2A), // Preto como na imagem
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                   blurRadius: 8,
                   offset: const Offset(0, 2),
                 ),
               ],
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(
                   'Repetições',
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 11,
                     fontWeight: FontWeight.w500,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
                 const SizedBox(height: 2),
                 Text(
                   reps,
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 16,
                     fontWeight: FontWeight.w700,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ],
             ),
           ),
         ),
       ],
     );
   }

   Widget _buildOverlayStats(String reps, String peso, int totalSeries, bool isDark) {
     return Column(
       mainAxisSize: MainAxisSize.min,
       children: [
         _buildOverlayStatRow(
           Icons.repeat,
           'Séries',
           '$serieAtual / $totalSeries',
           Colors.cyanAccent,
           isDark,
         ),
         const SizedBox(height: 6),
         _buildOverlayStatRow(
           Icons.cached,
           'Repetições',
           reps,
           Colors.blueAccent,
           isDark,
         ),
         const SizedBox(height: 6),
         _buildOverlayStatRow(
           Icons.fitness_center,
           'Peso',
           '$peso kg',
           Colors.purpleAccent,
           isDark,
         ),
       ],
     );
   }

   Widget _buildOverlayStatRow(IconData icon, String label, String value, Color color, bool isDark) {
     return Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Container(
           padding: const EdgeInsets.all(4),
           decoration: BoxDecoration(
             color: color.withOpacity(0.3),
             borderRadius: BorderRadius.circular(6),
             border: Border.all(
               color: color.withOpacity(0.6),
               width: 1,
             ),
           ),
           child: Icon(icon, size: 14, color: Colors.white),
         ),
         const SizedBox(width: 8),
         Flexible(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(
                 label,
                 style: GoogleFonts.poppins(
                   color: Colors.white.withOpacity(0.9),
                   fontSize: 9,
                   fontWeight: FontWeight.w500,
                   letterSpacing: 0.3,
                   shadows: [
                     Shadow(
                       color: Colors.black.withOpacity(0.8),
                       blurRadius: 2,
                       offset: const Offset(1, 1),
                     ),
                   ],
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
               Text(
                 value,
                 style: GoogleFonts.poppins(
                   color: Colors.white,
                   fontSize: 12,
                   fontWeight: FontWeight.w600,
                   shadows: [
                     Shadow(
                       color: Colors.black.withOpacity(0.8),
                       blurRadius: 2,
                       offset: const Offset(1, 1),
                     ),
                   ],
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
             ],
           ),
         ),
       ],
     );
   }

   Widget _buildCompactStats(String reps, String peso, int totalSeries, bool isDark) {
     return Column(
       children: [
         _buildCompactStatRow(
           Icons.repeat,
           'Séries',
           '$serieAtual / $totalSeries',
           Colors.blueAccent,
           isDark,
         ),
         const SizedBox(height: 8),
         _buildCompactStatRow(
           Icons.cached,
           'Repetições',
           reps,
           Colors.cyanAccent,
           isDark,
         ),
         const SizedBox(height: 8),
         _buildCompactStatRow(
           Icons.fitness_center,
           'Peso',
           '$peso kg',
           Colors.purpleAccent,
           isDark,
         ),
       ],
     );
   }

   Widget _buildCompactStatRow(IconData icon, String label, String value, Color color, bool isDark) {
     return Row(
       children: [
         Container(
           padding: const EdgeInsets.all(6),
           decoration: BoxDecoration(
             color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
             borderRadius: BorderRadius.circular(8),
             border: isDark ? Border.all(
               color: color.withOpacity(0.5),
               width: 1,
             ) : null,
           ),
           child: Icon(icon, size: 16, color: color),
         ),
         const SizedBox(width: 12),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 label,
                 style: GoogleFonts.orbitron(
                   color: isDark ? color.withOpacity(0.8) : const Color(0xFF64748B),
                   fontSize: 10,
                   fontWeight: FontWeight.bold,
                   letterSpacing: 0.5,
                 ),
               ),
               Text(
                 value,
                 style: GoogleFonts.orbitron(
                   color: isDark ? Colors.white : const Color(0xFF1F2937),
                   fontSize: 14,
                   fontWeight: FontWeight.bold,
                 ),
               ),
             ],
           ),
         ),
       ],
     );
   }

   Widget _buildFuturisticImageFrame(String img, bool isDark) {
     return Container(
       decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(20),
         gradient: isDark ? LinearGradient(
           colors: [
             Colors.cyanAccent.withOpacity(0.3),
             Colors.blueAccent.withOpacity(0.3),
             Colors.purpleAccent.withOpacity(0.3),
           ],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ) : null,
         boxShadow: isDark ? [
           BoxShadow(
             color: Colors.cyanAccent.withOpacity(0.3),
             blurRadius: 20,
             spreadRadius: 2,
           ),
         ] : [
           BoxShadow(
             color: Colors.black.withOpacity(0.1),
             blurRadius: 15,
             offset: const Offset(0, 8),
           ),
         ],
       ),
       padding: const EdgeInsets.all(3),
       child: ClipRRect(
         borderRadius: BorderRadius.circular(17),
         child: Container(
           width: 140,
           height: 140,
           decoration: BoxDecoration(
             color: isDark ? const Color(0xFF0F172A) : Colors.white,
             borderRadius: BorderRadius.circular(17),
           ),
           child: ClipRRect(
             borderRadius: BorderRadius.circular(17),
             child: img.isNotEmpty
                 ? Image.network('https://airfit.online/$img', fit: BoxFit.cover)
                 : Icon(Icons.image, size: 80, color: isDark ? Colors.grey[600] : Colors.grey[400]),
           ),
         ),
       ),
     );
   }

  Widget _buildNeonTitle(String nome, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: isDark ? BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withOpacity(0.1),
            Colors.blueAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.3),
          width: 1,
        ),
      ) : null,
      child: Text(
        nome,
        textAlign: TextAlign.center,
        style: isDark ? GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.cyanAccent.withOpacity(0.5),
              blurRadius: 10,
            ),
          ],
        ) : const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildHolographicStatsPanel(String reps, String peso, int totalSeries, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.1),
            Colors.cyanAccent.withOpacity(0.1),
          ],
        ) : null,
        color: isDark ? null : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(
          color: Colors.blueAccent.withOpacity(0.3),
          width: 1,
        ) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildHolographicStatItem(
            Icons.repeat,
            'SÉRIES',
            '$serieAtual / $totalSeries',
            Colors.blueAccent,
            isDark,
          ),
          _buildVerticalDivider(isDark),
          _buildHolographicStatItem(
            Icons.cached,
            'REPS',
            reps,
            Colors.cyanAccent,
            isDark,
          ),
          _buildVerticalDivider(isDark),
          _buildHolographicStatItem(
            Icons.fitness_center,
            'PESO',
            '$peso kg',
            Colors.purpleAccent,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHolographicStatItem(IconData icon, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: isDark ? Border.all(
                color: color.withOpacity(0.5),
                width: 1,
              ) : null,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: isDark ? color : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: isDark ? LinearGradient(
          colors: [
            Colors.transparent,
            Colors.cyanAccent.withOpacity(0.5),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ) : null,
        color: isDark ? null : const Color(0xFFE5E7EB),
      ),
    );
  }

     Widget _buildFuturisticProgressBar(int totalSeries, bool isDark) {
     return Column(
       children: [
         Text(
           'Progresso das Séries',
           style: GoogleFonts.poppins(
             color: const Color(0xFF666666),
             fontSize: 12,
             fontWeight: FontWeight.w500,
           ),
         ),
         const SizedBox(height: 12),
         AnimatedBuilder(
           animation: _progressAnimation,
           builder: (context, child) {
             return Row(
               children: List.generate(totalSeries, (i) {
                 final isCompleted = i < serieAtual;
                 return Expanded(
                   child: Container(
                     margin: EdgeInsets.only(right: i == totalSeries - 1 ? 0 : 6),
                     height: 6,
                     decoration: BoxDecoration(
                       color: isCompleted 
                           ? const Color(0xFFCDFF47)
                           : const Color(0xFFE8E8E8),
                       borderRadius: BorderRadius.circular(3),
                     ),
                   ),
                 );
               }),
             );
           },
         ),
       ],
     );
   }

   Widget _buildEnhancedStats(String reps, String peso, int totalSeries) {
     return Container(
       padding: const EdgeInsets.all(12),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         mainAxisSize: MainAxisSize.min,
         children: [
           // Séries com destaque - mais compacto
           Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               Container(
                 padding: const EdgeInsets.all(6),
                 decoration: BoxDecoration(
                   color: const Color(0xFFCDFF47),
                   borderRadius: BorderRadius.circular(6),
                 ),
                 child: Icon(
                   Icons.repeat,
                   size: 14,
                   color: Colors.black,
                 ),
               ),
               const SizedBox(width: 8),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(
                     'Séries',
                     style: GoogleFonts.poppins(
                       color: Colors.black,
                       fontSize: 10,
                       fontWeight: FontWeight.w500,
                       shadows: [
                         Shadow(
                           color: Colors.white.withOpacity(0.3),
                           blurRadius: 1,
                           offset: const Offset(0.5, 0.5),
                         ),
                       ],
                     ),
                   ),
                   Text(
                     '$serieAtual / $totalSeries',
                     style: GoogleFonts.poppins(
                       color: Colors.black,
                       fontSize: 14,
                       fontWeight: FontWeight.w700,
                       shadows: [
                         Shadow(
                           color: Colors.white.withOpacity(0.3),
                           blurRadius: 1,
                           offset: const Offset(0.5, 0.5),
                         ),
                       ],
                     ),
                   ),
                 ],
               ),
             ],
           ),
           
           const SizedBox(height: 8),
           
           // Repetições e Peso lado a lado - mais compacto
           Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               // Repetições
               Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Container(
                     padding: const EdgeInsets.all(6),
                     decoration: BoxDecoration(
                       color: const Color(0xFF2A2A2A),
                       borderRadius: BorderRadius.circular(6),
                     ),
                     child: Icon(
                       Icons.cached,
                       size: 14,
                       color: Colors.white,
                     ),
                   ),
                   const SizedBox(width: 6),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                         'Reps',
                         style: GoogleFonts.poppins(
                           color: Colors.black,
                           fontSize: 10,
                           fontWeight: FontWeight.w500,
                           shadows: [
                             Shadow(
                               color: Colors.white.withOpacity(0.3),
                               blurRadius: 1,
                               offset: const Offset(0.5, 0.5),
                             ),
                           ],
                         ),
                       ),
                       Text(
                         reps,
                         style: GoogleFonts.poppins(
                           color: Colors.black,
                           fontSize: 12,
                           fontWeight: FontWeight.w700,
                           shadows: [
                             Shadow(
                               color: Colors.white.withOpacity(0.3),
                               blurRadius: 1,
                               offset: const Offset(0.5, 0.5),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
               
               const SizedBox(width: 12),
               
               // Peso
               Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Container(
                     padding: const EdgeInsets.all(6),
                     decoration: BoxDecoration(
                       color: const Color(0xFFE8E8E8),
                       borderRadius: BorderRadius.circular(6),
                     ),
                     child: Icon(
                       Icons.fitness_center,
                       size: 14,
                       color: const Color(0xFF666666),
                     ),
                   ),
                   const SizedBox(width: 6),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       Text(
                         'Peso',
                         style: GoogleFonts.poppins(
                           color: Colors.black,
                           fontSize: 10,
                           fontWeight: FontWeight.w500,
                           shadows: [
                             Shadow(
                               color: Colors.white.withOpacity(0.3),
                               blurRadius: 1,
                               offset: const Offset(0.5, 0.5),
                             ),
                           ],
                         ),
                       ),
                       Text(
                         '${peso}kg',
                         style: GoogleFonts.poppins(
                           color: Colors.black,
                           fontSize: 12,
                           fontWeight: FontWeight.w700,
                           shadows: [
                             Shadow(
                               color: Colors.white.withOpacity(0.3),
                               blurRadius: 1,
                               offset: const Offset(0.5, 0.5),
                             ),
                           ],
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
             ],
           ),
         ],
       ),
     );
   }

  Widget _buildHolographicDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.cyanAccent.withOpacity(0.5),
            Colors.blueAccent.withOpacity(0.5),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

     Widget _buildFuturisticControlPanel(bool isDark) {
     return Column(
       children: [
         // Layout principal com botão circular no centro
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
           children: [
             // Botão esquerdo - Concluir exercício
             _buildSideButton(
               text: 'CONCLUIR\nEXERCÍCIO',
               onPressed: concluirExercicio,
               icon: Icons.done_all,
               isDark: false,
             ),
             
             // Botão central circular - Ação principal
             _buildCentralButton(
               onPressed: descansando ? null : concluirSerie,
               isResting: descansando,
               restTime: tempoRestante,
               isDark: false,
             ),
             
             // Botão direito - Pular exercício
             _buildSideButton(
               text: 'PULAR\nEXERCÍCIO',
               onPressed: pularExercicio,
               icon: Icons.skip_next,
               isDark: false,
             ),
           ],
         ),
       ],
     );
   }

   Widget _buildCentralButton({
     required VoidCallback? onPressed,
     required bool isResting,
     required int restTime,
     required bool isDark,
   }) {
     return GestureDetector(
       onTap: onPressed,
       child: Container(
         width: 64,
         height: 64,
         decoration: BoxDecoration(
           color: onPressed != null 
               ? const Color(0xFFCDFF47)
               : const Color(0xFFCCCCCC),
           shape: BoxShape.circle,
           boxShadow: onPressed != null ? [
             BoxShadow(
               color: Colors.black.withOpacity(0.1),
               blurRadius: 8,
               offset: const Offset(0, 3),
             ),
           ] : null,
         ),
         child: Center(
           child: isResting
               ? Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(
                       Icons.pause,
                       color: Colors.black,
                       size: 18,
                     ),
                     Text(
                       '${restTime}s',
                       style: GoogleFonts.poppins(
                         color: Colors.black,
                         fontSize: 8,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ],
                 )
               : Icon(
                   Icons.play_arrow,
                   color: onPressed != null 
                       ? Colors.black
                       : Colors.grey[600],
                   size: 24,
                 ),
         ),
       ),
     );
   }

   Widget _buildSideButton({
     required String text,
     required VoidCallback onPressed,
     required IconData icon,
     required bool isDark,
   }) {
     return GestureDetector(
       onTap: onPressed,
       child: Container(
         width: 64,
         height: 64,
         decoration: BoxDecoration(
           color: const Color(0xFFF8F8F8),
           borderRadius: BorderRadius.circular(12),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.04),
               blurRadius: 6,
               offset: const Offset(0, 2),
             ),
           ],
         ),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(
               icon,
               color: const Color(0xFF666666),
               size: 18,
             ),
             const SizedBox(height: 3),
             Text(
               text,
               textAlign: TextAlign.center,
               style: GoogleFonts.poppins(
                 color: const Color(0xFF666666),
                 fontSize: 8,
                 fontWeight: FontWeight.w500,
                 height: 1.1,
               ),
             ),
           ],
         ),
       ),
     );
   }

     Widget _buildQuantumButton({
     required String text,
     required VoidCallback? onPressed,
     required bool isPrimary,
     required IconData icon,
     required bool isDark,
   }) {
     return GestureDetector(
       onTapDown: onPressed != null ? (_) => _buttonController.forward() : null,
       onTapUp: onPressed != null ? (_) => _buttonController.reverse() : null,
       onTapCancel: onPressed != null ? () => _buttonController.reverse() : null,
       onTap: onPressed,
       child: AnimatedBuilder(
         animation: _buttonAnimation,
         builder: (context, child) {
           return Transform.scale(
             scale: onPressed != null ? _buttonAnimation.value : 1.0,
             child: Container(
               padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
               decoration: BoxDecoration(
                 color: onPressed != null
                     ? (isPrimary
                         ? const Color(0xFFCDFF47) // Verde limão para botão principal
                         : const Color(0xFFE8E8E8)) // Cinza claro para botões secundários
                     : const Color(0xFFCCCCCC), // Cinza para desabilitado
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: onPressed != null ? [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.1),
                     blurRadius: 8,
                     offset: const Offset(0, 2),
                   ),
                 ] : null,
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(
                     icon,
                     size: 18,
                     color: onPressed != null
                         ? (isPrimary 
                             ? Colors.black // Preto no botão verde
                             : const Color(0xFF666666)) // Cinza escuro nos secundários
                         : Colors.grey[500],
                   ),
                   const SizedBox(width: 8),
                   Text(
                     text,
                     style: GoogleFonts.poppins(
                       color: onPressed != null
                           ? (isPrimary 
                               ? Colors.black // Preto no botão verde
                               : const Color(0xFF666666)) // Cinza escuro nos secundários
                           : Colors.grey[500],
                       fontSize: 14,
                       fontWeight: FontWeight.w600,
                       letterSpacing: 0.3,
                     ),
                   ),
                 ],
               ),
             ),
           );
         },
       ),
     );
   }

  Widget _buildNavItem(IconData icon, String label, int index, int selectedIndex) {
    final bool isSelected = index == selectedIndex;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            if (index != 2) {
              // Navegar para a HomePage com o índice correto
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomePageWithIndex(initialIndex: index)),
                (route) => false,
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 2),
                  width: isSelected ? 35 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                              Icon(
                icon,
                size: 20,
                color: isSelected 
                  ? const Color(0xFF3B82F6) 
                  : const Color(0xFF6B7280),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected 
                      ? const Color(0xFF3B82F6) 
                      : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _FuturisticInfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _FuturisticInfoBlock({required this.icon, required this.label, required this.value, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16213E) : const Color(0xFFF4F7FE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.cyanAccent : const Color(0xFF2563EB),
            width: 1.5,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.18),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isDark ? Colors.cyanAccent : const Color(0xFF2563EB)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF2563EB))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF2563EB))),
          ],
        ),
      ),
    );
  }
}

class _FuturisticButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isMain;
  final bool isDark;
  final IconData? icon;
  const _FuturisticButton({required this.text, this.onPressed, required this.isMain, required this.isDark, this.icon});
  @override
  Widget build(BuildContext context) {
    if (!isDark) {
      return ElevatedButton(
        onPressed: onPressed,
        child: icon != null ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)],
        ) : Text(text),
      );
    }
    if (isMain) {
      // Botão com gradiente
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.cyanAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(text, style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        fontSize: 16,
                      )),
                    ],
                  )
                : Text(text, style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 16,
                  )),
          ),
        ),
      );
    }
    // Botão secundário
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        shadowColor: Colors.blueAccent.withOpacity(0.4),
        textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
      child: icon != null ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: 18, color: Colors.cyanAccent), const SizedBox(width: 8), Text(text)],
      ) : Text(text),
    );
  }
} 