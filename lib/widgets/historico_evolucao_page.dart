import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Estrutura para agrupar evoluções por tipo
class EvolucaoItem {
  final String tipo;
  final String valorAnterior;
  final String valorNovo;
  final IconData icon;
  final Color color;
  final DateTime data;

  EvolucaoItem({
    required this.tipo,
    required this.valorAnterior,
    required this.valorNovo,
    required this.icon,
    required this.color,
    required this.data,
  });
}

class GrupoEvolucao {
  final String tipo;
  final List<EvolucaoItem> evolucoes;

  GrupoEvolucao({
    required this.tipo,
    required this.evolucoes,
  });
}

class HistoricoEvolucaoPage extends StatefulWidget {
  final int exercicioId;
  final String nomeExercicio;

  const HistoricoEvolucaoPage({
    Key? key,
    required this.exercicioId,
    required this.nomeExercicio,
  }) : super(key: key);

  @override
  State<HistoricoEvolucaoPage> createState() => _HistoricoEvolucaoPageState();
}

class _HistoricoEvolucaoPageState extends State<HistoricoEvolucaoPage> {
  List<Map<String, dynamic>> historico = [];
  bool isLoading = true;
  String? errorMessage;
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
        await _carregarHistorico(id);
      } else {
        setState(() {
          errorMessage = 'Usuário não identificado';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro ao carregar dados do usuário: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _carregarHistorico(int usuarioId) async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await http.get(
        Uri.parse('https://airfit.online/api/salvar_evolucao.php?usuario_id=$usuarioId&exercicio_id=${widget.exercicioId}'),
      );

      if (response.statusCode == 200) {
        final dados = jsonDecode(response.body);
        
        if (dados['sucesso'] == true) {
          setState(() {
            historico = List<Map<String, dynamic>>.from(dados['historico'] ?? []);
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = dados['erro'] ?? 'Erro ao carregar histórico';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Erro na requisição: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erro de conexão: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Evolução: ${widget.nomeExercicio}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorState()
              : historico.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoricoList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao carregar histórico',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _carregarHistorico(usuarioId!),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
              Icons.trending_up,
              size: 64,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhuma evolução registrada',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Continue treinando para ver sua\nprogressão neste exercício!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricoList() {
    final grupos = _getGruposEvolucao();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grupos.length,
      itemBuilder: (context, index) {
        return _buildGrupoEvolucaoCard(grupos[index]);
      },
    );
  }

  Widget _buildEvolucaoCard(Map<String, dynamic> evolucao, int index) {
    final dataEvolucao = DateTime.parse(evolucao['data_evolucao']);
    final pesoAnterior = double.tryParse(evolucao['peso_anterior'].toString()) ?? 0.0;
    final pesoNovo = double.tryParse(evolucao['peso_novo'].toString()) ?? 0.0;
    final repeticoesAnteriores = int.tryParse(evolucao['repeticoes_anteriores'].toString()) ?? 0;
    final repeticoesNovas = int.tryParse(evolucao['repeticoes_novas'].toString()) ?? 0;
    final seriesAnteriores = int.tryParse(evolucao['series_anteriores'].toString()) ?? 0;
    final seriesNovas = int.tryParse(evolucao['series_novas'].toString()) ?? 0;
    final duracaoAnterior = double.tryParse(evolucao['duracao_anterior']?.toString() ?? '0') ?? 0.0;
    final duracaoNova = double.tryParse(evolucao['duracao_nova']?.toString() ?? '0') ?? 0.0;
    final distanciaAnterior = double.tryParse(evolucao['distancia_anterior']?.toString() ?? '0') ?? 0.0;
    final distanciaNova = double.tryParse(evolucao['distancia_nova']?.toString() ?? '0') ?? 0.0;

    // Calcular mudanças (não apenas melhorias)
    final mudancaPeso = pesoNovo != pesoAnterior;
    final mudancaRepeticoes = repeticoesNovas != repeticoesAnteriores;
    final mudancaSeries = seriesNovas != seriesAnteriores;
    final mudancaDuracao = duracaoNova != duracaoAnterior;
    final mudancaDistancia = distanciaNova != distanciaAnterior;
    
    // Calcular se houve melhoria para a cor do ícone
    final houveMelhoria = pesoNovo > pesoAnterior || 
                         repeticoesNovas > repeticoesAnteriores || 
                         seriesNovas > seriesAnteriores ||
                         duracaoNova > duracaoAnterior ||
                         distanciaNova > distanciaAnterior;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com data e ícone de evolução
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: houveMelhoria
                      ? Colors.green[600]
                      : Colors.orange[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatarData(dataEvolucao.toIso8601String()),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                if (mudancaPeso || mudancaRepeticoes || mudancaSeries || mudancaDuracao || mudancaDistancia)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Histórico',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Detalhes da evolução
            if (mudancaPeso) ...[
              _buildEvolucaoItem(
                'Peso',
                '${pesoAnterior.toStringAsFixed(1)} kg',
                '${pesoNovo.toStringAsFixed(1)} kg',
                Icons.fitness_center,
                Colors.blue,
              ),
              const SizedBox(height: 8),
            ],
            
            if (mudancaRepeticoes && (evolucao['categoria']?.toString().toLowerCase() != 'isometria')) ...[
              _buildEvolucaoItem(
                'Repetições',
                '$repeticoesAnteriores reps',
                '$repeticoesNovas reps',
                Icons.repeat,
                Colors.green,
              ),
              const SizedBox(height: 8),
            ],
            
            if (mudancaSeries) ...[
              _buildEvolucaoItem(
                'Séries',
                '$seriesAnteriores séries',
                '$seriesNovas séries',
                Icons.layers,
                Colors.purple,
              ),
              const SizedBox(height: 8),
            ],
            
            if (mudancaDuracao || (mudancaRepeticoes && evolucao['categoria']?.toString().toLowerCase() == 'isometria')) ...[
              _buildEvolucaoItem(
                'Duração',
                _getValorDuracao(evolucao['categoria'] ?? '', duracaoAnterior, repeticoesAnteriores),
                _getValorDuracao(evolucao['categoria'] ?? '', duracaoNova, repeticoesNovas),
                Icons.timer,
                Colors.orange,
              ),
              const SizedBox(height: 8),
            ],
            
            if (mudancaDistancia) ...[
              _buildEvolucaoItem(
                'Distância',
                '${distanciaAnterior.toStringAsFixed(1)} km',
                '${distanciaNova.toStringAsFixed(1)} km',
                Icons.place,
                Colors.red,
              ),
              const SizedBox(height: 8),
            ],
            
            // Observações
            if (evolucao['observacoes'] != null && evolucao['observacoes'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        evolucao['observacoes'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEvolucaoItem(String titulo, String valorAnterior, String valorNovo, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    valorAnterior,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    valorNovo,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatarData(String data) {
    try {
      final date = DateTime.parse(data);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Hoje às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays == 1) {
        return 'Ontem às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} dias atrás';
      } else {
        final diasSemana = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'];
        final meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
        
        return '${diasSemana[date.weekday - 1]}, ${date.day} ${meses[date.month - 1]} ${date.year}';
      }
    } catch (e) {
      return data;
    }
  }

  String _getTituloRepeticoes(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    if (categoriaLower == 'isometria') {
      return 'Duração';
    }
    return 'Repetições';
  }

  String _getValorRepeticoes(int valor, String categoria) {
    final categoriaLower = categoria.toLowerCase();
    if (categoriaLower == 'isometria') {
      return '${valor}s';
    }
    return '${valor} reps';
  }

  String _getValorDuracao(String categoria, double duracao, int repeticoes) {
    final categoriaLower = categoria.toLowerCase();
    if (categoriaLower == 'isometria') {
      // Para isometria, usar o valor da duração (que contém o valor correto)
      return '${duracao.toStringAsFixed(0)}s';
    } else {
      // Para outros exercícios, usar o valor da duração
      return '${duracao.toStringAsFixed(0)} min';
    }
  }

  bool _deveSalvarRepeticoes(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    return categoriaLower.contains('musculação') || 
           categoriaLower.contains('calistenia') || 
           categoriaLower.contains('funcional') ||
           categoriaLower.contains('hiit');
  }

  bool _deveSalvarSeries(String categoria) {
    final categoriaLower = categoria.toLowerCase();
    return categoriaLower.contains('musculação') || 
           categoriaLower.contains('calistenia') || 
           categoriaLower.contains('funcional') ||
           categoriaLower.contains('hiit') ||
           categoriaLower.contains('isometria');
  }

  List<GrupoEvolucao> _getGruposEvolucao() {
    final Map<String, List<EvolucaoItem>> grupos = {};

    for (final evolucao in historico) {
      final dataEvolucao = DateTime.parse(evolucao['data_evolucao']);
      final pesoAnterior = double.tryParse(evolucao['peso_anterior'].toString()) ?? 0.0;
      final pesoNovo = double.tryParse(evolucao['peso_novo'].toString()) ?? 0.0;
      final repeticoesAnteriores = int.tryParse(evolucao['repeticoes_anteriores'].toString()) ?? 0;
      final repeticoesNovas = int.tryParse(evolucao['repeticoes_novas'].toString()) ?? 0;
      final seriesAnteriores = int.tryParse(evolucao['series_anteriores'].toString()) ?? 0;
      final seriesNovas = int.tryParse(evolucao['series_novas'].toString()) ?? 0;
      final duracaoAnterior = double.tryParse(evolucao['duracao_anterior']?.toString() ?? '0') ?? 0.0;
      final duracaoNova = double.tryParse(evolucao['duracao_nova']?.toString() ?? '0') ?? 0.0;
      final distanciaAnterior = double.tryParse(evolucao['distancia_anterior']?.toString() ?? '0') ?? 0.0;
      final distanciaNova = double.tryParse(evolucao['distancia_nova']?.toString() ?? '0') ?? 0.0;
      final categoria = evolucao['categoria']?.toString() ?? '';

      // Verificar mudanças
      if (pesoNovo != pesoAnterior) {
        grupos.putIfAbsent('Peso', () => []);
        grupos['Peso']!.add(EvolucaoItem(
          tipo: 'Peso',
          valorAnterior: '${pesoAnterior.toStringAsFixed(1)} kg',
          valorNovo: '${pesoNovo.toStringAsFixed(1)} kg',
          icon: Icons.fitness_center,
          color: Colors.blue,
          data: dataEvolucao,
        ));
      }

      if (repeticoesNovas != repeticoesAnteriores && _deveSalvarRepeticoes(categoria)) {
        grupos.putIfAbsent('Repetições', () => []);
        grupos['Repetições']!.add(EvolucaoItem(
          tipo: 'Repetições',
          valorAnterior: '$repeticoesAnteriores reps',
          valorNovo: '$repeticoesNovas reps',
          icon: Icons.repeat,
          color: Colors.green,
          data: dataEvolucao,
        ));
      }

      if (seriesNovas != seriesAnteriores && _deveSalvarSeries(categoria)) {
        grupos.putIfAbsent('Séries', () => []);
        grupos['Séries']!.add(EvolucaoItem(
          tipo: 'Séries',
          valorAnterior: '$seriesAnteriores séries',
          valorNovo: '$seriesNovas séries',
          icon: Icons.layers,
          color: Colors.purple,
          data: dataEvolucao,
        ));
      }

      if (duracaoNova != duracaoAnterior || (repeticoesNovas != repeticoesAnteriores && categoria.toLowerCase() == 'isometria')) {
        grupos.putIfAbsent('Duração', () => []);
        final valorAnterior = categoria.toLowerCase() == 'isometria' 
            ? '${repeticoesAnteriores}s' 
            : '${duracaoAnterior.toStringAsFixed(0)} min';
        final valorNovo = categoria.toLowerCase() == 'isometria' 
            ? '${repeticoesNovas}s' 
            : '${duracaoNova.toStringAsFixed(0)} min';
        grupos['Duração']!.add(EvolucaoItem(
          tipo: 'Duração',
          valorAnterior: valorAnterior,
          valorNovo: valorNovo,
          icon: Icons.timer,
          color: Colors.orange,
          data: dataEvolucao,
        ));
      }

      if (distanciaNova != distanciaAnterior) {
        grupos.putIfAbsent('Distância', () => []);
        grupos['Distância']!.add(EvolucaoItem(
          tipo: 'Distância',
          valorAnterior: '${distanciaAnterior.toStringAsFixed(1)} km',
          valorNovo: '${distanciaNova.toStringAsFixed(1)} km',
          icon: Icons.place,
          color: Colors.red,
          data: dataEvolucao,
        ));
      }
    }

    // Ordenar evoluções por data (mais recente primeiro) e converter para lista
    final List<GrupoEvolucao> resultado = [];
    grupos.forEach((tipo, evolucoes) {
      evolucoes.sort((a, b) => b.data.compareTo(a.data));
      resultado.add(GrupoEvolucao(tipo: tipo, evolucoes: evolucoes));
    });

    // Ordenar grupos por ordem de importância
    resultado.sort((a, b) {
      final ordem = {'Peso': 1, 'Repetições': 2, 'Séries': 3, 'Duração': 4, 'Distância': 5};
      return (ordem[a.tipo] ?? 6).compareTo(ordem[b.tipo] ?? 6);
    });

    return resultado;
  }

  Widget _buildGrupoEvolucaoCard(GrupoEvolucao grupo) {
    final primeiraEvolucao = grupo.evolucoes.first;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header do grupo
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primeiraEvolucao.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    primeiraEvolucao.icon,
                    size: 20,
                    color: primeiraEvolucao.color,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  grupo.tipo,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: primeiraEvolucao.color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primeiraEvolucao.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${grupo.evolucoes.length} evolução${grupo.evolucoes.length > 1 ? 'ões' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primeiraEvolucao.color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lista de evoluções do grupo
            ...grupo.evolucoes.map((evolucao) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          evolucao.valorAnterior,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          evolucao.valorNovo,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primeiraEvolucao.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatarData(evolucao.data.toIso8601String()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
} 