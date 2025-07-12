import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoricoPage extends StatefulWidget {
  final int usuarioId; // Passe o ID do usuário logado

  const HistoricoPage({required this.usuarioId, Key? key}) : super(key: key);

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
    buscarHistorico();
  }

  Future<void> buscarHistorico() async {
    try {
      print('Buscando histórico para usuário ID: ${widget.usuarioId}');
      
      // Se o usuarioId for 0 ou null, mostrar erro
      if (widget.usuarioId == 0 || widget.usuarioId == null) {
        setState(() {
          erro = 'Usuário não identificado. Faça login novamente.';
          loading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://airfit.online/api/historico.php?usuario_id=${widget.usuarioId}'),
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
    int totalHoras = totalTempo ~/ 60;
    int totalMin = totalTempo % 60;
    int numDiasTreino = datasTreino.length;

    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF),
      appBar: AppBar(
        title: const Text('Histórico de Treinos'),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1B3358),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : erro != null
              ? Center(child: Text(erro!))
              : historico.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_emotions, size: 60, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text('Nenhum treino realizado ainda'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('Ver Treinos'),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Card de totais
                          Card(
                            color: Colors.blue[700],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _statItem(Icons.fitness_center, '${totalKg.toStringAsFixed(1)} kg', 'Peso levantado'),
                                  _statItem(Icons.access_time, '${totalHoras}h ${totalMin}min', 'Tempo total'),
                                  _statItem(Icons.directions_run, '${totalKm.toStringAsFixed(1)} km', 'Distância total'),
                                  _statItem(Icons.calendar_today, '$numDiasTreino', 'Dias de treino'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Lista de treinos
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: historico.length,
                            itemBuilder: (context, i) {
                              final r = historico[i];
                              final data = DateTime.parse(r['data_registro']);
                              final diasSemana = [
                                'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'
                              ];
                              final diaSemana = diasSemana[data.weekday % 7];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[100],
                                    child: Text('${data.day}/${data.month}'),
                                  ),
                                  title: Text('${r['nome_treino'] ?? 'Treino'}'),
                                  subtitle: Text('$diaSemana'),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text('${r['kg_levantados']} kg'),
                                      Text('${r['tempo_treino_minutos']} min'),
                                      Text('${r['distancia_km']} km'),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
    );
  }

  Widget _statItem(IconData icon, String valor, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 4),
        Text(valor, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
} 