import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/trofeu_animal.dart';

class PremiosPage extends StatefulWidget {
  const PremiosPage({Key? key}) : super(key: key);

  @override
  State<PremiosPage> createState() => _PremiosPageState();
}

class _PremiosPageState extends State<PremiosPage> {
  List<Map<String, dynamic>> premios = [];
  List<TrofeuConquistado> trofeusMetas = [];
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
        await _carregarTrofeusMetas(id);
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
          });
        } else {
          print('Erro na resposta: ${dados['erro']}');
        }
      } else {
        print('Erro na requisição: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao carregar prêmios: $e');
    }
  }

  Future<void> _carregarTrofeusMetas(int usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('https://airfit.online/api/salvar_premio_v2.php?usuario_id=$usuarioId'),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        
        if (dados['sucesso'] == true) {
          final trofeus = <TrofeuConquistado>[];
          
          for (var premioData in dados['premios'] ?? []) {
            // Filtrar apenas prêmios de metas
            if (premioData['tipo_conquista'] == 'meta') {
              // Criar objeto TrofeuAnimal a partir dos dados
              final trofeu = TrofeuAnimal(
                id: premioData['id'].toString(),
                nome: premioData['nome_animal'],
                emoji: premioData['emoji_animal'],
                descricao: premioData['descricao_trofeu'] ?? '',
                categoria: premioData['categoria_trofeu'] ?? 'Comum',
                raridade: premioData['raridade_trofeu'] ?? 1,
                mensagemMotivacional: premioData['mensagem_motivacional'] ?? '',
              );
              
              trofeus.add(TrofeuConquistado.fromJson(premioData, trofeu));
            }
          }

          setState(() {
            trofeusMetas = trofeus;
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
      print('Erro ao carregar troféus: $e');
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
            onPressed: () async {
              if (usuarioId != null) {
                await _carregarPremios(usuarioId!);
                await _carregarTrofeusMetas(usuarioId!);
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
            : (premios.isEmpty && trofeusMetas.isEmpty)
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
                  'Total\nConquistas',
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
        
        // Lista de conquistas
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Seção de prêmios de treinos
              if (premios.isNotEmpty) ...[
                _buildSectionHeader('🎯 Prêmios de Treinos', premios.length),
                const SizedBox(height: 12),
                ...premios.map((premio) => _buildPremioCard(premio, isDark)).toList(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3B82F6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrofeuCard(TrofeuConquistado trofeu, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            trofeu.trofeu.corRaridade.withOpacity(0.1),
            trofeu.trofeu.corRaridade.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: trofeu.trofeu.corRaridade.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: trofeu.trofeu.corRaridade.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: trofeu.trofeu.corRaridade.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            trofeu.trofeu.emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                trofeu.trofeu.nome,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: trofeu.trofeu.corRaridade.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                trofeu.trofeu.raridadeTexto,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: trofeu.trofeu.corRaridade,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Meta: ${trofeu.nomeMeta}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trofeu.trofeu.descricao,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              _formatarData(trofeu.dataConquista.toIso8601String()),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        onTap: () => _mostrarDetalhesTrofeu(trofeu),
      ),
    );
  }

  void _mostrarDetalhesTrofeu(TrofeuConquistado trofeu) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                trofeu.trofeu.corRaridade.withOpacity(0.1),
                trofeu.trofeu.corRaridade.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: trofeu.trofeu.corRaridade.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                trofeu.trofeu.emoji,
                style: const TextStyle(fontSize: 64),
              ),
              const SizedBox(height: 16),
              Text(
                trofeu.trofeu.nome,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: trofeu.trofeu.corRaridade.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trofeu.trofeu.raridadeTexto,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: trofeu.trofeu.corRaridade,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                trofeu.trofeu.descricao,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Meta: ${trofeu.nomeMeta}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatarData(trofeu.dataConquista.toIso8601String()),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: trofeu.trofeu.corRaridade,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            
            // Peso total levantado ou medalha para prêmios especiais
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pesoTotal == 0 
                    ? const Color(0xFFF59E0B).withOpacity(0.1)  // Cor dourada para medalha
                    : const Color(0xFF10B981).withOpacity(0.1), // Cor verde para peso
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Mostrar medalha se peso for 0, senão mostrar peso
                  pesoTotal == 0
                      ? const Icon(
                          Icons.emoji_events,
                          size: 24,
                          color: Color(0xFFF59E0B),
                        )
                      : Column(
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