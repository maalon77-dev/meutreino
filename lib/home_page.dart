import 'package:flutter/material.dart';
import 'historico_page.dart';
import 'treinar_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'exercicios_treino_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6),
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
      extendBody: true,
      backgroundColor: Colors.transparent,
      drawer: CustomDrawer(
        darkTheme: isDark,
        onThemeChanged: (val) => themeProvider.setTheme(val),
        onMenuTap: (index) {
          setState(() {
            _selectedIndex = index;
            _treinoSelecionado = null;
            _exerciciosSelecionados = [];
          });
          Navigator.pop(context);
        },
      ),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : const Color(0xFF374151),
        ),
        title: _treinoSelecionado != null
            ? Text(
                _treinoSelecionado?['nome_treino'] ?? 'Treino',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w700,
                ),
              )
            : Text(
                'UPMAX Fitness',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: isDark ? Colors.white : const Color(0xFF374151),
                  fontWeight: FontWeight.w700,
                ),
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.nightlight_round : Icons.nightlight_outlined,
              color: isDark ? Colors.white : const Color(0xFF374151),
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [const Color(0xFF020617), const Color(0xFF0F172A)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: conteudoCentral,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
              selectedItemColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6),
              unselectedItemColor: isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF),
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            showUnselectedLabels: true,
              iconSize: 24,
            items: [
                _navBarItem(Icons.home_outlined, 'Home', 0, _selectedIndex, isDark),
                _navBarItem(Icons.event_note_outlined, 'Histórico', 1, _selectedIndex, isDark),
                _navBarItem(Icons.rocket_launch_outlined, 'Treinar', 2, _selectedIndex, isDark),
                _navBarItem(Icons.psychology_alt_outlined, 'Assistente', 3, _selectedIndex, isDark),
                _navBarItem(Icons.settings_outlined, 'Perfil', 4, _selectedIndex, isDark),
            ],
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
                _treinoSelecionado = null;
                _exerciciosSelecionados = [];
              });
            },
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _navBarItem(IconData icon, String label, int index, int selectedIndex, bool isDark) {
    final bool isSelected = index == selectedIndex;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)).withValues(alpha: 0.1) 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected 
            ? (isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6))
            : (isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
        ),
      ),
      label: label,
    );
  }
}

class CustomDrawer extends StatelessWidget {
  final bool darkTheme;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<int> onMenuTap;

  const CustomDrawer({
    required this.darkTheme,
    required this.onThemeChanged,
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
              color: darkTheme ? const Color(0xFF1F2937) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: darkTheme ? 0.3 : 0.1),
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
                  style: TextStyle(
                    color: darkTheme ? Colors.white : const Color(0xFF374151),
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
                SwitchListTile(
                  title: Text(
                    'Tema Escuro',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      color: darkTheme ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                  value: darkTheme,
                  onChanged: onThemeChanged,
                  secondary: Icon(
                    Icons.nightlight_round_outlined,
                    color: darkTheme ? Colors.white : const Color(0xFF3B82F6),
                  ),
                  activeColor: const Color(0xFF6366F1),
                ),
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
      leading: Icon(
        icon, 
        color: darkTheme ? Colors.white : const Color(0xFF3B82F6),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontFamily: 'Poppins',
          color: darkTheme ? Colors.white : const Color(0xFF374151),
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

  static Widget _buildCalendar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Table(
      border: TableBorder.all(color: Colors.transparent),
                  children: [
        TableRow(
          children: [
            Center(child: Text('Dom', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))), // Azul claro
            Center(child: Text('Seg', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))), // Azul claro
            Center(child: Text('Ter', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))), // Azul claro
            Center(child: Text('Qua', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))), // Azul claro
            Center(child: Text('Qui', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))), // Azul claro
            Center(child: Text('Sex', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))), // Azul claro
            Center(child: Text('Sáb', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280)))), // Azul claro
          ],
        ),
        TableRow(
          children: [
            _calendarDay(context, '1'),
            _calendarDay(context, '2'),
            _calendarDay(context, '3'),
            _calendarDay(context, '4'),
            _calendarDay(context, '5', checked: true),
            _calendarDay(context, '6', checked: true),
            _calendarDay(context, '7'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay(context, '8', checked: true),
            _calendarDay(context, '9'),
            _calendarDay(context, '10', checked: true),
            _calendarDay(context, '11', selected: true),
            _calendarDay(context, '12'),
            _calendarDay(context, '13'),
            _calendarDay(context, '14'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay(context, '15'),
            _calendarDay(context, '16'),
            _calendarDay(context, '17'),
            _calendarDay(context, '18'),
            _calendarDay(context, '19'),
            _calendarDay(context, '20'),
            _calendarDay(context, '21'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay(context, '22'),
            _calendarDay(context, '23'),
            _calendarDay(context, '24'),
            _calendarDay(context, '25'),
            _calendarDay(context, '26'),
            _calendarDay(context, '27'),
            _calendarDay(context, '28'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay(context, '29'),
            _calendarDay(context, '30'),
            _calendarDay(context, '31'),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
            const SizedBox(),
          ],
        ),
      ],
    );
  }

  static Widget _calendarDay(BuildContext context, String day, {bool checked = false, bool selected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
        color: selected
            ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6)) // Azul médio
            : checked
                ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6)).withValues(alpha: 0.2) // Azul médio
                : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: selected
              ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6)) // Azul médio
              : checked
                  ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6)).withValues(alpha: 0.5) // Azul médio
                  : isDark
                      ? const Color(0xFF475569) // Azul mais claro
                      : const Color(0xFFE5E7EB),
          width: selected ? 2 : 1,
        ),
      ),
      height: 32,
      child: Center(
        child: Text(
          day,
                              style: TextStyle(
            color: selected
                ? Colors.white
                : checked
                    ? (isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6)) // Azul médio
                    : isDark
                        ? Colors.white
                        : const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _HomeContentState extends State<_HomeContent> {
  List<Map<String, dynamic>> historico = [];
  int treinosMesAtual = 0;
  double totalKg = 0;
  bool isLoading = true;

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
        await _buscarHistorico(usuarioId);
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
        Uri.parse('https://airfit.online/api/api.php?tabela=historico_saldo&acao=historico_usuario&usuario_id=$usuarioId'),
      );

      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        final List<Map<String, dynamic>> historicoOrdenado = List<Map<String, dynamic>>.from(dados);
        
        print('Dados recebidos: ${historicoOrdenado.length} registros');
        
        // Ordenar por data mais recente
        historicoOrdenado.sort((a, b) => DateTime.parse(b['data_registro']).compareTo(DateTime.parse(a['data_registro'])));
        
        // Calcular treinos do mês atual
        final agora = DateTime.now();
        final treinosMes = historicoOrdenado.where((treino) {
          final dataTreino = DateTime.parse(treino['data_registro']);
          return dataTreino.year == agora.year && dataTreino.month == agora.month;
        }).length;

        // Calcular total de kg
        double total = 0;
        for (var treino in historicoOrdenado) {
          total += double.tryParse(treino['kg_levantados'].toString()) ?? 0;
        }

        print('Treinos no mês atual: $treinosMes');
        print('Total de kg: $total');

        setState(() {
          historico = historicoOrdenado;
          treinosMesAtual = treinosMes;
          totalKg = total;
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

  String _formatarPeso(dynamic kg) {
    try {
      final peso = double.parse(kg.toString());
      if (peso >= 1000) {
        return '${(peso / 1000).toStringAsFixed(1)}t';
      }
      return '${peso.toStringAsFixed(0)} kg';
    } catch (e) {
      return '0 kg';
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
                  height: 140, // Altura fixa para ambos os cards
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
                              historico.isNotEmpty ? 'Treino' : 'Último Treino',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (historico.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatarData(historico[0]['data_registro']),
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
                                    _formatarTempo(historico[0]['tempo_treino_minutos']),
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
              // Card de criar meta
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // TODO: Implementar criação de meta
                  },
                  child: Container(
                    height: 140, // Altura fixa para ambos os cards
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
                                color: (isDark ? const Color(0xFF60A5FA) : const Color(0xFF60A5FA)).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.flag,
                                color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF60A5FA),
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Criar Meta',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Defina seus objetivos de treino',
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
                      child: _HomeContent._statCard(context, _formatarPeso(totalKg), 'Total levantado', Icons.fitness_center, isDark ? const Color(0xFF6366F1) : const Color(0xFF3B82F6)),
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
                      if (historico.length >= 1) _HomeContent._buildTreinoItem(context, _formatarData(historico[0]['data_registro']), 'Treino', _formatarTempo(historico[0]['tempo_treino_minutos'])),
                      if (historico.length >= 2) _HomeContent._buildTreinoItem(context, _formatarData(historico[1]['data_registro']), 'Treino', _formatarTempo(historico[1]['tempo_treino_minutos'])),
                      if (historico.length >= 3) _HomeContent._buildTreinoItem(context, _formatarData(historico[2]['data_registro']), 'Treino', _formatarTempo(historico[2]['tempo_treino_minutos'])),
                    ],
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {},
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
          const SizedBox(height: 24),
          
          // Card de calendário
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
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF60A5FA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Calendário de Treinos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
                const SizedBox(height: 20),
                _HomeContent._buildCalendar(context),
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