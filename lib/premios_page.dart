import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PremiosPage extends StatefulWidget {
  const PremiosPage({Key? key}) : super(key: key);

  @override
  State<PremiosPage> createState() => _PremiosPageState();
}

class _PremiosPageState extends State<PremiosPage> {
  List<Map<String, dynamic>> premios = [];
  bool isLoading = true;
  int? usuarioId;

  @override
  void initState() {
    super.initState();
    _carregarUsuarioId();
  }

  Future<void> _carregarUsuarioId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('usuario_id');
      setState(() {
        usuarioId = id;
      });
      
      if (id != null && id > 0) {
        await _carregarPremios(id);
      }
    } catch (e) {
      print('Erro ao carregar usuarioId: $e');
    }
  }

  Future<void> _carregarPremios(int usuarioId) async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.get(
        Uri.parse('https://airfit.online/api/salvar_premio_v2.php?usuario_id=$usuarioId'),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        
        if (dados['sucesso'] == true) {
          setState(() {
            premios = List<Map<String, dynamic>>.from(dados['premios'] ?? []);
            isLoading = false;
          });
        } else {
          print('Erro na resposta: ${dados['erro']}');
          setState(() {
            isLoading = false;
          });
        }
      } else {
        print('Erro na requisição: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar prêmios: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  String _formatarData(String data) {
    try {
      final dataObj = DateTime.parse(data);
      final diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
      final meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      
      final diaSemana = diasSemana[dataObj.weekday - 1];
      final dia = dataObj.day.toString().padLeft(2, '0');
      final mes = meses[dataObj.month - 1];
      final ano = dataObj.year;
      final hora = dataObj.hour.toString().padLeft(2, '0');
      final minuto = dataObj.minute.toString().padLeft(2, '0');
      
      return '$diaSemana, $dia $mes $ano às $hora:$minuto';
    } catch (e) {
      return data;
    }
  }

  String _formatarPeso(double peso) {
    if (peso >= 1000) {
      return '${(peso / 1000).toStringAsFixed(1)} ton';
    } else {
      return '${peso.toInt()} kg';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF374151)),
        title: Text(
          'Meus Prêmios',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: const Color(0xFF374151),
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (usuarioId != null) {
                _carregarPremios(usuarioId!);
              }
            },
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
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF3B82F6),
                ),
              )
            : premios.isEmpty
                ? _buildEmptyState(isDark)
                : _buildPremiosList(isDark),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum prêmio ainda!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Complete treinos para conquistar\nprêmios incríveis!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                Icon(
                  Icons.fitness_center,
                  size: 32,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(height: 12),
                Text(
                  'Como conquistar prêmios?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '1. Complete exercícios nos treinos\n2. Acumule peso total levantado\n3. Conquiste animais incríveis!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiosList(bool isDark) {
    return Column(
      children: [
        // Header com estatísticas
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${premios.length}',
                  'Prêmios\nConquistados',
                  Icons.emoji_events,
                  const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  _formatarPeso(_calcularPesoTotal()),
                  'Peso Total\nLevantado',
                  Icons.fitness_center,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de prêmios
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: premios.length,
            itemBuilder: (context, index) {
              final premio = premios[index];
              return _buildPremioCard(premio, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPremioCard(Map<String, dynamic> premio, bool isDark) {
    final nomeAnimal = premio['nome_animal'] ?? 'Animal';
    final emojiAnimal = premio['emoji_animal'] ?? '🐾';
    final pesoAnimal = double.tryParse(premio['peso_animal'].toString()) ?? 0.0;
    final pesoTotal = double.tryParse(premio['peso_total_levantado'].toString()) ?? 0.0;
    final dataConquista = premio['data_conquista'] ?? '';
    final nomeTreino = premio['nome_treino'] ?? 'Treino';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Emoji do animal
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  emojiAnimal,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Informações do prêmio
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nomeAnimal,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Treino: $nomeTreino',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatarData(dataConquista),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            
            // Peso total levantado
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    _formatarPeso(pesoTotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF10B981),
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

  double _calcularPesoTotal() {
    double total = 0;
    for (var premio in premios) {
      total += double.tryParse(premio['peso_total_levantado'].toString()) ?? 0.0;
    }
    return total;
  }
} 