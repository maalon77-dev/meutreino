import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

class HistoricoPage extends StatefulWidget {
  // Remover o parâmetro usuarioId do construtor
  const HistoricoPage({Key? key}) : super(key: key);

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  bool loading = true;
  String? erro;
  List historico = [];

  double totalKg = 0;
  int totalTempo = 0;
  double totalKm = 0;
  Set<String> datasTreino = {};

  @override
  void initState() {
    super.initState();
    _buscarUsuarioIdEHistorico();
  }

  Future<void> _buscarUsuarioIdEHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id') ?? 0;
    if (usuarioId == 0) {
      setState(() {
        erro = 'Usuário não identificado. Faça login novamente.';
        loading = false;
      });
      return;
    }
    await buscarHistoricoComId(usuarioId);
  }

  Future<void> buscarHistoricoComId(int usuarioId) async {
    try {
      print('Buscando histórico para usuário ID: $usuarioId');
      final response = await http.get(
        Uri.parse('https://airfit.online/api/api.php?tabela=historico_saldo&acao=historico_usuario&usuario_id=$usuarioId'),
      );
      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');
      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        setState(() {
          historico = dados;
          for (var r in historico) {
            totalKg += double.tryParse(r['kg_levantados'].toString()) ?? 0;
            totalTempo += int.tryParse(r['tempo_treino_minutos'].toString()) ?? 0;
            totalKm += double.tryParse(r['distancia_km'].toString()) ?? 0;
            datasTreino.add(r['data_registro'].toString().substring(0, 10));
          }
          loading = false;
        });
      } else {
        setState(() {
          erro = 'Erro ao buscar histórico (Status: ${response.statusCode})';
          loading = false;
        });
      }
    } catch (e) {
      print('Erro na requisição: $e');
      setState(() {
        erro = 'Erro de conexão: $e';
        loading = false;
      });
    }
  }

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
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Histórico de Treinos',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Acompanhe seu progresso e evolução',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          
          // Conteúdo
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF3B82F6),
                      ),
                    )
                  : historico.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.history,
                                  size: 48,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum treino registrado',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: const Color(0xFF374151),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete seu primeiro treino para ver o histórico aqui',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF6B7280),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding bottom aumentado
                          itemCount: historico.length,
                          itemBuilder: (context, index) {
                            final item = historico[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Header do card
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.fitness_center,
                                            color: Color(0xFF3B82F6),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Treino #${item['treino_id']}',
                                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              Text(
                                                _formatarData(item['data_registro']),
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  color: const Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF3B82F6).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${item['pontos_ganhos']} pts',
                                            style: const TextStyle(
                                              color: Color(0xFF3B82F6),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Estatísticas
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStat(
                                          'Peso Total',
                                          '${item['kg_levantados']} kg',
                                          Icons.fitness_center,
                                          const Color(0xFF3B82F6),
                                        ),
                                        _buildStat(
                                          'Tempo',
                                          '${item['tempo_treino_minutos']} min',
                                          Icons.timer,
                                          const Color(0xFF60A5FA),
                                        ),
                                        _buildStat(
                                          'Distância',
                                          '${item['distancia_km']} km',
                                          Icons.directions_run,
                                          const Color(0xFF93C5FD),
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
    );
  }

  Widget _statItem(IconData icon, String valor, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _resumoCard(String label, int valor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        children: [
          Text(
            '$valor',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
            fontSize: 12,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _formatarData(String data) {
    try {
      final date = DateTime.parse(data);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;
      
      if (difference == 0) {
        return 'Hoje';
      } else if (difference == 1) {
        return 'Ontem';
      } else if (difference < 7) {
        return 'Há $difference dias';
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      return data;
    }
  }
} 