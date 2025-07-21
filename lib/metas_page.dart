import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'models/meta.dart';
import 'services/meta_service.dart';
import 'widgets/meta_card.dart';
import 'widgets/criar_meta_page.dart';
import 'widgets/atualizar_progresso_page.dart';

class MetasPage extends StatefulWidget {
  final int usuarioId;
  
  const MetasPage({super.key, required this.usuarioId});

  @override
  State<MetasPage> createState() => _MetasPageState();
}

class _MetasPageState extends State<MetasPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  List<Meta> _metas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _carregarMetas();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _carregarMetas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await metaService.initialize();
      final metas = await metaService.obterTodasMetas(widget.usuarioId);
      
      print('🔄 Metas carregadas na página: ${metas.length}');
      for (var meta in metas) {
        print('  - ${meta.nome}: ${meta.progressos.length} progressos, valor atual: ${meta.valorAtual}');
      }
      
      setState(() {
        _metas = metas;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erro ao carregar metas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _criarNovaMeta() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CriarMetaPage(usuarioId: widget.usuarioId),
      ),
    );

    if (result == true) {
      _carregarMetas();
    }
  }

  Future<void> _atualizarProgresso(Meta meta) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AtualizarProgressoPage(
          meta: meta,
          usuarioId: widget.usuarioId,
        ),
      ),
    );

    if (result == true) {
      _carregarMetas();
    }
  }

  void _excluirMeta(Meta meta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Meta'),
        content: Text('Tem certeza que deseja excluir a meta "${meta.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              try {
                Navigator.pop(context);
                await metaService.excluirMeta(meta.id);
                _carregarMetas();
                
                // Mostrar mensagem de sucesso
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Meta "${meta.nome}" excluída com sucesso!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                print('❌ Erro ao excluir meta: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erro ao excluir meta: $e'),
                      backgroundColor: const Color(0xFFDC2626),
                    ),
                  );
                }
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: metaService.obterEstatisticas(widget.usuarioId),
      builder: (context, snapshot) {
        final estatisticas = snapshot.data ?? {
          'total': 0,
          'ativas': 0,
          'concluidas': 0,
          'percentualConclusao': 0.0,
        };
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Minhas Metas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _criarNovaMeta,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: RefreshIndicator(
                onRefresh: _carregarMetas,
                child: CustomScrollView(
                  slivers: [
                    // Header com estatísticas
                    SliverToBoxAdapter(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3B82F6).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildStatItem(
                                  'Total',
                                  estatisticas['total'].toString(),
                                  Icons.flag,
                                ),
                                _buildStatItem(
                                  'Ativas',
                                  estatisticas['ativas'].toString(),
                                  Icons.trending_up,
                                ),
                                _buildStatItem(
                                  'Concluídas',
                                  estatisticas['concluidas'].toString(),
                                  Icons.check_circle,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: estatisticas['percentualConclusao'] / 100,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${estatisticas['percentualConclusao'].toStringAsFixed(1)}% Concluído',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Lista de metas
                    if (_metas.isEmpty)
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.flag_outlined,
                                      size: 64,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Nenhuma meta criada',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF374151),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Crie sua primeira meta para começar a acompanhar seu progresso!',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: _criarNovaMeta,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Criar Primeira Meta'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final meta = _metas[index];
                              return MetaCard(
                                meta: meta,
                                onAtualizarProgresso: () => _atualizarProgresso(meta),
                                onExcluir: () => _excluirMeta(meta),
                              );
                            },
                            childCount: _metas.length,
                          ),
                        ),
                      ),
                  ],
                ),
                      ),
      ),
    );
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 