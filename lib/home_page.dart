import 'package:flutter/material.dart';
import 'historico_page.dart';
import 'treinar_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _darkTheme = false;
  int? usuarioId;
  bool _isLoading = true;
  List<Widget> _pages = [];

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
      TreinarPage(),
      AssistentePage(),
      PerfilPage(),
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
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF6366F1),
          ),
        ),
      );
    }
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      drawer: CustomDrawer(
        darkTheme: _darkTheme,
        onThemeChanged: (val) => setState(() => _darkTheme = val),
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
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        title: Text(
          'UPMAX Fitness',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _darkTheme ? Icons.nightlight_round : Icons.nightlight_outlined,
              color: const Color(0xFF374151),
            ),
            onPressed: () => setState(() => _darkTheme = !_darkTheme),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _pages.isNotEmpty ? _pages[_selectedIndex] : const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF3B82F6),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
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
              backgroundColor: Colors.white,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF3B82F6),
              unselectedItemColor: const Color(0xFF9CA3AF),
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
                _navBarItem(Icons.home_outlined, 'Home', 0, _selectedIndex),
                _navBarItem(Icons.event_note_outlined, 'Histórico', 1, _selectedIndex),
                _navBarItem(Icons.rocket_launch_outlined, 'Treinar', 2, _selectedIndex),
                _navBarItem(Icons.psychology_alt_outlined, 'Assistente', 3, _selectedIndex),
                _navBarItem(Icons.settings_outlined, 'Perfil', 4, _selectedIndex),
              ],
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  static BottomNavigationBarItem _navBarItem(IconData icon, String label, int index, int selectedIndex) {
    final bool isSelected = index == selectedIndex;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF9CA3AF),
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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
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
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                const Text(
                  'Maalon Barbosa Silva Santos',
                  style: TextStyle(
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
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
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
                  title: const Text(
                    'Tema Escuro',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  value: darkTheme,
                  onChanged: onThemeChanged,
                  secondary: const Icon(Icons.nightlight_round_outlined),
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
      leading: Icon(icon, color: const Color(0xFF3B82F6)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontFamily: 'Poppins',
        ),
      ),
      onTap: onTap,
    );
  }
}

class _HomeContent extends StatefulWidget {
  @override
  State<_HomeContent> createState() => _HomeContentState();
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
      final response = await http.get(
        Uri.parse('https://airfit.online/api/api.php?tabela=historico_saldo&acao=historico_usuario&usuario_id=$usuarioId'),
      );

      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        final List<Map<String, dynamic>> historicoOrdenado = List<Map<String, dynamic>>.from(dados);
        
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

        setState(() {
          historico = historicoOrdenado;
          treinosMesAtual = treinosMes;
          totalKg = total;
        });
      }
    } catch (e) {
      print('Erro ao buscar histórico: $e');
    }
  }

  String _formatarData(String dataRegistro) {
    try {
      final data = DateTime.parse(dataRegistro);
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--/--';
    }
  }

  String _formatarPeso(dynamic kg) {
    try {
      final peso = double.parse(kg.toString());
      if (peso >= 1000) {
        return '{(peso / 1000).toStringAsFixed(1)}t';
      }
      return '{peso.toStringAsFixed(0)} kg';
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding bottom aumentado
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card principal de treino
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
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
                      'Iniciar Treino',
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
          
          // Card de histórico
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bar_chart,
                        color: Color(0xFF3B82F6),
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
                      child: _statCard(context, _formatarPeso(totalKg), 'Total levantado', Icons.fitness_center, const Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _statCard(context, treinosMesAtual.toString(), 'Treinos este mês', Icons.calendar_today, const Color(0xFF60A5FA)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                      strokeWidth: 2,
                    ),
                  )
                else if (historico.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFF6B7280),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nenhum treino registrado ainda',
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
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
                      if (historico.length >= 1) _buildTreinoItem(
                        _formatarData(historico[0]['data_registro']),
                        'Treino',
                        _formatarPeso(historico[0]['kg_levantados']),
                        _formatarTempo(historico[0]['tempo_treino_minutos']),
                      ),
                      if (historico.length >= 2) _buildTreinoItem(
                        _formatarData(historico[1]['data_registro']),
                        'Treino',
                        _formatarPeso(historico[1]['kg_levantados']),
                        _formatarTempo(historico[1]['tempo_treino_minutos']),
                      ),
                      if (historico.length >= 3) _buildTreinoItem(
                        _formatarData(historico[2]['data_registro']),
                        'Treino',
                        _formatarPeso(historico[2]['kg_levantados']),
                        _formatarTempo(historico[2]['tempo_treino_minutos']),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Ver Histórico Completo',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF3B82F6),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
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
                        color: const Color(0xFF60A5FA).withOpacity(0.1),
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
                _buildCalendar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildTreinoItem(String data, String titulo, String peso, String tempo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            peso,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tempo,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildCalendar() {
    return Table(
      border: TableBorder.all(color: Colors.transparent),
      children: [
        const TableRow(
          children: [
            Center(child: Text('Dom', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
            Center(child: Text('Seg', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
            Center(child: Text('Ter', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
            Center(child: Text('Qua', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
            Center(child: Text('Qui', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
            Center(child: Text('Sex', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
            Center(child: Text('Sáb', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)))),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('1'),
            _calendarDay('2'),
            _calendarDay('3'),
            _calendarDay('4'),
            _calendarDay('5', checked: true),
            _calendarDay('6', checked: true),
            _calendarDay('7'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('8', checked: true),
            _calendarDay('9'),
            _calendarDay('10', checked: true),
            _calendarDay('11', selected: true),
            _calendarDay('12'),
            _calendarDay('13'),
            _calendarDay('14'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('15'),
            _calendarDay('16'),
            _calendarDay('17'),
            _calendarDay('18'),
            _calendarDay('19'),
            _calendarDay('20'),
            _calendarDay('21'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('22'),
            _calendarDay('23'),
            _calendarDay('24'),
            _calendarDay('25'),
            _calendarDay('26'),
            _calendarDay('27'),
            _calendarDay('28'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('29'),
            _calendarDay('30'),
            _calendarDay('31'),
            Container(),
            Container(),
            Container(),
            Container(),
          ],
        ),
      ],
    );
  }

  static Widget _calendarDay(String day, {bool checked = false, bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B82F6) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day,
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF374151),
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              if (checked)
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Icon(
                    Icons.check_circle,
                    color: Color(0xFF60A5FA),
                    size: 12,
                  ),
                ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Icon(
                    Icons.star,
                    color: Color(0xFF60A5FA),
                    size: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssistentePage extends StatelessWidget {
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
                  color: Colors.black.withOpacity(0.1),
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
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
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
                  color: Colors.black.withOpacity(0.1),
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
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 48,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Perfil do usuário',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Em breve você poderá editar seus dados e ver seu progresso.',
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