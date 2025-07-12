import 'package:flutter/material.dart';
import 'historico_page.dart';
import 'treinar_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

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
          _pages[1] = HistoricoPage(usuarioId: id);
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
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF),
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
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('UPMAX APP', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_darkTheme ? Icons.nightlight_round : Icons.nightlight_outlined, color: Colors.black),
            onPressed: () => setState(() => _darkTheme = !_darkTheme),
          ),
        ],
      ),
      body: _pages.isNotEmpty ? _pages[_selectedIndex] : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Container(
        color: const Color(0xFFF7F9FB),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Color(0xFF1B3358),
          unselectedItemColor: Color(0xFF1B3358).withOpacity(0.22),
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11, color: Color(0xFF1B3358)),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 11, color: Color(0xFF1B3358).withOpacity(0.22)),
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
    );
  }

  static BottomNavigationBarItem _navBarItem(IconData icon, String label, int index, int selectedIndex) {
    final bool isSelected = index == selectedIndex;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: Duration(milliseconds: 220),
        curve: Curves.ease,
        padding: const EdgeInsets.only(bottom: 6, top: 8),
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? Color(0xFF1B3358) : Color(0xFF1B3358).withOpacity(0.22),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1565DF), Color(0xFF1B3358)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.blue[900]),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Maalon Barbosa Silva Santos',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Conta Premium',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
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
                _drawerItem(Icons.psychology_alt_outlined, 'Assistente IA (Nutricionista e Personal Trainer)', () => onMenuTap(3)),
                _drawerItem(Icons.shopping_cart_outlined, 'Ofertas Fitness', () {}),
                _drawerItem(Icons.settings_outlined, 'Configurações', () => onMenuTap(4)),
                _drawerItem(Icons.account_balance_wallet_outlined, 'Meu Saldo', () {}),
                _drawerItem(Icons.credit_card_outlined, 'Assinatura', () {}),
                SwitchListTile(
                  title: const Text('Tema Escuro', style: TextStyle(fontSize: 15)),
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
                Text('2025 © Copyright ', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                GestureDetector(
                  onTap: () {},
                  child: const Text('UPMAX APP', style: TextStyle(color: Color(0xFF1565DF), fontWeight: FontWeight.bold, fontSize: 13)),
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
      leading: Icon(icon, color: Color(0xFF1B3358)),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
    );
  }
}

class _HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue[900],
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comece seu Treino de Hoje!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Recursos para progressão de carga e tempo de descanso, vão melhorar sua performance e evolução.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {},
                  child: const Text('Iniciar Treino'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.bar_chart, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Histórico de Treinos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: const [
                            Text(
                              '13.020 kg',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Total levantado'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: const [
                            Text(
                              '6',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text('Dias de treino'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    _buildTreinoItem('11/07', 'Treino', '480 kg', '19 min'),
                    _buildTreinoItem('10/07', 'Treino', '480 kg', '1 min'),
                    _buildTreinoItem('10/07', 'Treino', '480 kg', '71 min'),
                  ],
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  child: const Text('Ver Histórico Completo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.calendar_month, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Calendário de Treinos',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildCalendar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTreinoItem(String data, String titulo, String peso, String tempo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(titulo)),
          Text(peso, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Text(tempo, style: const TextStyle(color: Colors.grey)),
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
            Center(child: Text('Dom')),
            Center(child: Text('Seg')),
            Center(child: Text('Ter')),
            Center(child: Text('Qua')),
            Center(child: Text('Qui')),
            Center(child: Text('Sex')),
            Center(child: Text('Sáb')),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('1'), _calendarDay('2'), _calendarDay('3'), _calendarDay('4'), _calendarDay('5', checked: true), _calendarDay('6', checked: true), _calendarDay('7'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('8', checked: true), _calendarDay('9'), _calendarDay('10', checked: true), _calendarDay('11', selected: true), _calendarDay('12'), _calendarDay('13'), _calendarDay('14'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('15'), _calendarDay('16'), _calendarDay('17'), _calendarDay('18'), _calendarDay('19'), _calendarDay('20'), _calendarDay('21'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('22'), _calendarDay('23'), _calendarDay('24'), _calendarDay('25'), _calendarDay('26'), _calendarDay('27'), _calendarDay('28'),
          ],
        ),
        TableRow(
          children: [
            _calendarDay('29'), _calendarDay('30'), _calendarDay('31'), Container(), Container(), Container(), Container(),
          ],
        ),
      ],
    );
  }

  static Widget _calendarDay(String day, {bool checked = false, bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Colors.blue[700] : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                day,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (checked)
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: 2),
                  child: Icon(Icons.star, color: Colors.amber, size: 16),
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
    return Center(
      child: Text('Assistente IA em breve!', style: TextStyle(fontSize: 18)),
    );
  }
}

class PerfilPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Perfil do usuário em breve!', style: TextStyle(fontSize: 18)),
    );
  }
}