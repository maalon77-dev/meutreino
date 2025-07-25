import 'package:flutter/material.dart';
import 'historico_page.dart';
import 'treinar_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

import 'exercicios_treino_page.dart';
import 'premios_page.dart';
import 'metas_page.dart';
import 'services/meta_service.dart';
import 'models/meta.dart';
import 'widgets/app_bar_logo.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;
  
  const HomePage({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  int? usuarioId;
  bool _isLoading = true;
  List<Widget> _pages = [];

  // Novo estado para navegação interna
  Map<String, dynamic>? _treinoSelecionado;
  List<Map<String, dynamic>> _exerciciosSelecionados = [];
  bool _carregandoExercicios = false;
  
  // GlobalKey para o Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _inicializarPaginas();
    _carregarUsuarioId();
  }

  void _inicializarPaginas() {
    _pages = [
      _HomeContent(),
      const Center(child: Text('Carregando histórico...')),
      TreinarPage(
        onTreinoSelecionado: (treino) {
          setState(() {
            _treinoSelecionado = treino;
            _exerciciosSelecionados = List<Map<String, dynamic>>.from(treino['exercicios'] ?? []);
          });
        },
      ),
      const Center(child: Text('Assistente')),
      const Center(child: Text('Perfil')),
    ];
  }

  Future<void> _carregarUsuarioId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('usuario_id');
      print('UsuarioId carregado: $id');
      setState(() {
        usuarioId = id;
        _isLoading = false;
        if (id != null && id > 0) {
          print('Criando HistoricoPage com usuarioId: $id');
          _pages[1] = HistoricoPage();
        } else {
          print('UsuarioId inválido, aguardando login válido');
          _pages[1] = const Center(child: Text('Faça login para ver o histórico'));
        }
      });
    } catch (e) {
      print('Erro ao carregar usuarioId: $e');
      setState(() {
        _isLoading = false;
        _pages[1] = const Center(child: Text('Erro ao carregar dados'));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: const Color(0xFF3B82F6),
          ),
        ),
      );
    }
    // Lógica para exibir ExerciciosTreinoPage no centro
    Widget conteudoCentral;
    if (_treinoSelecionado != null) {
      if (_carregandoExercicios) {
        conteudoCentral = Center(child: CircularProgressIndicator());
      } else {
        conteudoCentral = ExerciciosTreinoPage(
          treino: _treinoSelecionado!,
          exercicios: _exerciciosSelecionados,
          onVoltar: () {
            setState(() {
              _treinoSelecionado = null;
              _exerciciosSelecionados = [];
            });
          },
        );
      }
    } else {
      conteudoCentral = _pages[_selectedIndex];
    }
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: Colors.transparent,
      drawer: CustomDrawer(
        onMenuTap: (index) {
          setState(() {
            _selectedIndex = index;
            _treinoSelecionado = null;
            _exerciciosSelecionados = [];
          });
          Navigator.pop(context);
        },
      ),
      appBar: AppBarLogo(
        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: conteudoCentral,
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

  Widget _buildNavItem(IconData icon, String label, int index, int selectedIndex) {
    final bool isSelected = index == selectedIndex;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
              _treinoSelecionado = null;
              _exerciciosSelecionados = [];
            });
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
                size: 23, // Aumentado de 20 para 23 (13% maior)
                color: isSelected 
                  ? const Color(0xFF3B82F6) 
                  : const Color(0xFF6B7280),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9, // Aumentado de 8 para 9 (13% maior)
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

class CustomDrawer extends StatelessWidget {
  final ValueChanged<int> onMenuTap;

  const CustomDrawer({
    required this.onMenuTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 48, bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                  radius: 38,
                    backgroundColor: const Color(0xFF3B82F6),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Maalon Barbosa Silva Santos',
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                  'Conta Premium',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF374151)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _drawerItem(Icons.home_outlined, 'Home', () => onMenuTap(0)),
                _drawerItem(Icons.rocket_launch_outlined, 'Iniciar Treino', () {}),
                _drawerItem(Icons.event_note_outlined, 'Histórico de Treinos', () => onMenuTap(1)),
                _drawerItem(Icons.forum_outlined, 'Comunidade', () {}),
                _drawerItem(Icons.psychology_alt_outlined, 'Assistente IA', () => onMenuTap(3)),
                _drawerItem(Icons.shopping_cart_outlined, 'Ofertas Fitness', () {}),
                _drawerItem(Icons.settings_outlined, 'Configurações', () => onMenuTap(4)),
                _drawerItem(Icons.account_balance_wallet_outlined, 'Meu Saldo', () {}),
                _drawerItem(Icons.credit_card_outlined, 'Assinatura', () {}),

                _drawerItem(Icons.logout, 'Sair', () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('logado', false);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginPage()),
                    (route) => false,
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(Icons.camera_alt_outlined, color: Colors.grey[400]),
                const SizedBox(height: 6),
                Text(
                  '2025 © Copyright ',
                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Text(
                    'UPMAX Fitness',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: const Icon(
        Icons.fitness_center,
        color: Color(0xFF3B82F6),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'Poppins',
          color: Color(0xFF374151),
        ),
      ),
      onTap: onTap,
    );
  }
}

class _HomeContent extends StatefulWidget {
  @override
  State<_HomeContent> createState() => _HomeContentState();

  static Widget _buildTreinoItem(BuildContext context, String data, String titulo, String tempo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white, // Azul escuro
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB), // Azul mais claro
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Data
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6)).withValues(alpha: 0.1), // Azul médio
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6), // Azul médio
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Título e tempo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280), // Azul claro
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tempo,
                  style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280), // Azul claro
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
                ),
              ],
            ),
    );
  }

  static Widget _statCard(BuildContext context, String value, String label, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : Colors.white, // Azul escuro
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
            child: Column(
              children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
                    Text(
            value,
                      style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280), // Azul claro
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


}

class _HomeContentState extends State<_HomeContent> {
  List<Map<String, dynamic>> historico = [];
  int treinosMesAtual = 0;
  double totalKg = 0;
  bool isLoading = true;
  int? usuarioId;
  
  // Estado para metas
  List<Meta> _metas = [];
  bool _carregandoMetas = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      if (usuarioId != null && usuarioId > 0) {
        this.usuarioId = usuarioId;
        await Future.wait([
          _buscarHistorico(usuarioId),
          _carregarMetas(),
        ]);
      }
    } catch (e) {
      print('Erro ao carregar dados: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _buscarHistorico(int usuarioId) async {
    try {
      print('Buscando histórico para usuário ID: $usuarioId');
      final response = await http.get(
        Uri.parse('https://airfit.online/api/api.php?acao=historico_treino_especifico&usuario_id=$usuarioId'),
      );

      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        final List<Map<String, dynamic>> historicoOrdenado = List<Map<String, dynamic>>.from(dados['historico'] ?? []);
        
        print('Dados recebidos: ${historicoOrdenado.length} registros');
        
        // Ordenar por data mais recente
        historicoOrdenado.sort((a, b) => DateTime.parse(b['data_treino']).compareTo(DateTime.parse(a['data_treino'])));
        
        // Calcular treinos do mês atual
        final agora = DateTime.now();
        final treinosMes = historicoOrdenado.where((treino) {
          final dataTreino = DateTime.parse(treino['data_treino']);
          return dataTreino.year == agora.year && dataTreino.month == agora.month;
        }).length;

        // Calcular total de tempo do mês (em minutos)
        double totalTempoMes = 0;
        for (var treino in historicoOrdenado) {
          final dataTreino = DateTime.parse(treino['data_treino']);
          if (dataTreino.year == agora.year && dataTreino.month == agora.month) {
            final tempoTotal = int.tryParse(treino['tempo_total'].toString()) ?? 0;
            totalTempoMes += tempoTotal / 60; // Converter segundos para minutos
          }
        }

        print('Treinos no mês atual: $treinosMes');
        print('Total de tempo no mês: ${totalTempoMes.toStringAsFixed(0)} minutos');

        setState(() {
          historico = historicoOrdenado;
          treinosMesAtual = treinosMes;
          totalKg = totalTempoMes; // Usar totalTempoMes no lugar de totalKg
        });
      } else {
        print('Erro na resposta: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar histórico: $e');
    }
  }

  String _formatarData(String dataRegistro) {
    try {
      final data = DateTime.parse(dataRegistro);
      final diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      final diaSemana = diasSemana[data.weekday - 1];
      return '$diaSemana, ${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--/--';
    }
  }

  Future<void> _carregarMetas() async {
    if (usuarioId == null) return;
    
    setState(() {
      _carregandoMetas = true;
    });

    try {
      await metaService.initialize();
      final todasMetas = await metaService.obterTodasMetas(usuarioId!);
      
      // Pegar apenas as duas últimas metas criadas
      final metasOrdenadas = todasMetas.toList()
        ..sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
      
      setState(() {
        _metas = metasOrdenadas.take(2).toList();
        _carregandoMetas = false;
      });
    } catch (e) {
      print('Erro ao carregar metas: $e');
      setState(() {
        _carregandoMetas = false;
      });
    }
  }

  List<FlSpot> _getChartSpots(Meta meta) {
    if (meta.progressos.isEmpty) {
      return [
        FlSpot(0, meta.valorInicial),
        FlSpot(1, meta.valorInicial),
      ];
    }

    // Ordenar progressos por data (mais antigo primeiro) para o gráfico
    final progressosOrdenados = List<ProgressoMeta>.from(meta.progressos);
    progressosOrdenados.sort((a, b) => a.data.compareTo(b.data));

    final spots = <FlSpot>[];
    spots.add(FlSpot(0, meta.valorInicial));
    
    for (int i = 0; i < progressosOrdenados.length; i++) {
      spots.add(FlSpot((i + 1).toDouble(), progressosOrdenados[i].valor));
    }
    
    return spots;
  }

  double _getMinY(Meta meta) {
    if (meta.progressos.isEmpty) {
      return meta.valorInicial * 0.9;
    }
    
    final minValor = meta.progressos.map((p) => p.valor).reduce((a, b) => a < b ? a : b);
    final minInicial = meta.valorInicial;
    return (minValor < minInicial ? minValor : minInicial) * 0.9;
  }

  double _getMaxY(Meta meta) {
    if (meta.progressos.isEmpty) {
      return meta.valorInicial * 1.1;
    }
    
    final maxValor = meta.progressos.map((p) => p.valor).reduce((a, b) => a > b ? a : b);
    final maxDesejado = meta.valorDesejado;
    final maxInicial = meta.valorInicial;
    
    final maxValue = [maxValor, maxDesejado, maxInicial].reduce((a, b) => a > b ? a : b);
    return maxValue * 1.1;
  }

  String _formatarPeso(dynamic kg) {
    try {
      final peso = double.parse(kg.toString());
      if (peso >= 60) {
        final horas = peso ~/ 60;
        final minutos = (peso % 60).toInt();
        return horas > 0 ? '${horas}h ${minutos}min' : '${minutos}min';
      }
      return '${peso.toInt()} min';
    } catch (e) {
      return '0 min';
    }
  }

  String _formatarTempo(dynamic minutos) {
    try {
      final tempo = int.parse(minutos.toString());
      if (tempo < 60) {
        return '$tempo min';
      } else {
        final horas = tempo ~/ 60;
        final mins = tempo % 60;
        return '$horas h $mins min';
      }
    } catch (e) {
      return '0 min';
    }
  }

  Widget _buildMetasSection(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.flag,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Minhas Metas',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MetasPage(usuarioId: usuarioId!),
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_carregandoMetas)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_metas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.flag_outlined,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Crie suas metas para acompanhar o progresso',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            )
          else
            Column(
              children: [
                // Gráfico das duas últimas metas
                Row(
                  children: _metas.map((meta) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  meta.tipo.icone,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    meta.nome,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF374151),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${meta.valorAtual.toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
                                        ),
                                      ),
                                      Text(
                                        meta.tipo.unidade,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${meta.percentualConclusao.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: meta.percentualConclusao >= 100 
                                        ? const Color(0xFF10B981)
                                        : (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // LineChart pequeno
                            if (meta.progressos.isNotEmpty)
                              SizedBox(
                                height: 60,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(show: false),
                                    titlesData: FlTitlesData(show: false),
                                    borderData: FlBorderData(show: false),
                                    minX: 0,
                                    maxX: (_getChartSpots(meta).length - 1).toDouble(),
                                    minY: _getMinY(meta),
                                    maxY: _getMaxY(meta),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _getChartSpots(meta),
                                        isCurved: true,
                                        curveSmoothness: 0.35,
                                        preventCurveOverShooting: true,
                                        color: meta.percentualConclusao >= 100 
                                            ? const Color(0xFF10B981)
                                            : (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)),
                                        barWidth: 2,
                                        dotData: FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: (meta.percentualConclusao >= 100 
                                              ? const Color(0xFF10B981)
                                              : (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)))
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF475569) : const Color(0xFFE5E7EB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Sem dados',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
            ),
          
          const SizedBox(height: 12),
          
          // Botão para ver todas as metas
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MetasPage(usuarioId: usuarioId!),
                ),
              );
            },
            child: Text(
              'Ver Minhas Metas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding bottom aumentado
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card principal de treino
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/backgrounds/iniciar-treino.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withValues(alpha: 0.45),
                  BlendMode.darken,
                ),
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Ícone removido conforme solicitado
                    // const Icon(
                    //   Icons.fitness_center,
                    //   color: Colors.white,
                    //   size: 24,
                    // ),
                    // const SizedBox(width: 16),
                    Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                            'Comece seu Treino de Hoje!',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Recursos para progressão de carga e tempo de descanso',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
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
                      'Iniciar Treino',
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
          
          // Dois cards verticais lado a lado
          Row(
            children: [
              // Card do último treino
              Expanded(
                child: Container(
                  height: 160, // Altura aumentada para evitar overflow
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.history,
                              color: isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              historico.isNotEmpty ? (historico[0]['nome_treino'] ?? 'Treino') : 'Último Treino',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (historico.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatarData(historico[0]['data_treino']),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    _formatarTempo((int.tryParse(historico[0]['tempo_total'].toString()) ?? 0) ~/ 60),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        Text(
                          'Nenhum treino ainda',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Card de prêmios
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiosPage(),
                      ),
                    );
                  },
                  child: Container(
                    height: 160, // Altura aumentada para evitar overflow
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDark ? const Color(0xFFF59E0B) : const Color(0xFFF59E0B)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.emoji_events,
                                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFF59E0B),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Meus Prêmios',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Veja suas conquistas',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Seção de Metas
          _buildMetasSection(context, isDark),
          
          const SizedBox(height: 24),
          
          // Card de histórico
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white, // Azul escuro variante
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.bar_chart,
                        color: isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Histórico de Treinos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _HomeContent._statCard(context, _formatarPeso(totalKg), 'Tempo total', Icons.timer_outlined, isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _HomeContent._statCard(context, treinosMesAtual.toString(), 'Treinos este mês', Icons.calendar_today, isDark ? const Color(0xFF8B5CF6) : const Color(0xFF60A5FA)),
          ),
        ],
      ),
                const SizedBox(height: 20),
                if (isLoading)
                  Center(
                    child: CircularProgressIndicator(
                      color: isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6), // Azul médio
                      strokeWidth: 2,
                    ),
                  )
                else if (historico.isEmpty)
          Container(
                    padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6), // Azul escuro
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280), // Azul claro
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
            child: Text(
                            'Nenhum treino registrado ainda',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280), // Azul claro
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
          children: [
                      if (historico.length >= 1) _HomeContent._buildTreinoItem(context, _formatarData(historico[0]['data_treino']), historico[0]['nome_treino'] ?? 'Treino', _formatarTempo((int.tryParse(historico[0]['tempo_total'].toString()) ?? 0) ~/ 60)),
                      if (historico.length >= 2) _HomeContent._buildTreinoItem(context, _formatarData(historico[1]['data_treino']), historico[1]['nome_treino'] ?? 'Treino', _formatarTempo((int.tryParse(historico[1]['tempo_total'].toString()) ?? 0) ~/ 60)),
                      if (historico.length >= 3) _HomeContent._buildTreinoItem(context, _formatarData(historico[2]['data_treino']), historico[2]['nome_treino'] ?? 'Treino', _formatarTempo((int.tryParse(historico[2]['tempo_total'].toString()) ?? 0) ~/ 60)),
                    ],
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Navegar para a aba de histórico (índice 1)
                    if (context.mounted) {
                      // Encontrar o widget HomePage pai e navegar para o histórico
                      final homePageState = context.findAncestorStateOfType<_HomePageState>();
                      if (homePageState != null) {
                        homePageState.setState(() {
                          homePageState._selectedIndex = 1;
                          homePageState._treinoSelecionado = null;
                          homePageState._exerciciosSelecionados = [];
                        });
                      }
                    }
                  },
                  child: Text(
                    'Ver Histórico Completo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }
}

class AssistentePage extends StatelessWidget {
  const AssistentePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 120), // Padding adequado
      child: Center(
          child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_outlined,
                    size: 48,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Assistente IA em breve!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Conte com inteligência artificial para dicas de treino e nutrição.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6B7280),
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

class PerfilPage extends StatelessWidget {
  const PerfilPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 120), // Padding adequado
      child: Center(
          child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.settings,
                    color: Color(0xFF3B82F6),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Configurações',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Aqui você pode gerenciar suas configurações do app',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}