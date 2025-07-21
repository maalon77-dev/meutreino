import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/meta.dart';

class MetaCard extends StatefulWidget {
  final Meta meta;
  final VoidCallback onAtualizarProgresso;
  final VoidCallback onExcluir;

  const MetaCard({
    super.key,
    required this.meta,
    required this.onAtualizarProgresso,
    required this.onExcluir,
  });

  @override
  State<MetaCard> createState() => _MetaCardState();
}

class _MetaCardState extends State<MetaCard> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _progressAnimation;
  bool _showHistorico = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.meta.percentualConclusao / 100).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.meta;
    final isConcluida = meta.concluida;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isConcluida 
                      ? const Color(0xFFFFD700).withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
              border: isConcluida 
                  ? Border.all(
                      color: const Color(0xFFFFD700),
                      width: 2,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Conteúdo principal
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header da meta
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getTipoColor(meta.tipo).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              meta.tipo.icone,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  meta.nome,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                Text(
                                  meta.tipo.nome,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isConcluida)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Concluída',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Valores da meta
                      Row(
                        children: [
                          Expanded(
                            child: _buildValueCard(
                              'Inicial',
                              '${meta.valorInicial.toStringAsFixed(1)} ${meta.tipo.unidade}',
                              const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildValueCard(
                              'Atual',
                              '${meta.valorAtual.toStringAsFixed(1)} ${meta.tipo.unidade}',
                              const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildValueCard(
                              'Meta',
                              '${meta.valorDesejado.toStringAsFixed(1)} ${meta.tipo.unidade}',
                              const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Barra de progresso
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Progresso',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              Text(
                                '${meta.percentualConclusao.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          AnimatedBuilder(
                            animation: _progressAnimation,
                            builder: (context, child) {
                              return LinearProgressIndicator(
                                value: _progressAnimation.value,
                                backgroundColor: const Color(0xFFE5E7EB),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isConcluida 
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF3B82F6),
                                ),
                                minHeight: 8,
                              );
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Gráfico de progresso interativo
                      if (meta.progressos.isNotEmpty)
                        Container(
                          height: 180,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Evolução do Progresso',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isConcluida 
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF3B82F6),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: (isConcluida 
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF3B82F6))
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${meta.progressos.length} registros',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isConcluida 
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: true,
                                      horizontalInterval: _getGridInterval(meta),
                                      verticalInterval: 1,
                                      getDrawingHorizontalLine: (value) {
                                        return FlLine(
                                          color: const Color(0xFFE5E7EB),
                                          strokeWidth: 1,
                                          dashArray: [5, 5],
                                        );
                                      },
                                      getDrawingVerticalLine: (value) {
                                        return FlLine(
                                          color: const Color(0xFFE5E7EB),
                                          strokeWidth: 1,
                                          dashArray: [5, 5],
                                        );
                                      },
                                    ),
                                                                         titlesData: FlTitlesData(
                                       show: false,
                                     ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        width: 1,
                                      ),
                                    ),
                                    minX: 0,
                                    maxX: (_getChartSpots(widget.meta).length - 1).toDouble(),
                                    minY: _getMinY(widget.meta),
                                    maxY: _getMaxY(widget.meta),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _getChartSpots(widget.meta),
                                        isCurved: true,
                                        curveSmoothness: 0.35,
                                        preventCurveOverShooting: true,
                                        color: isConcluida 
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFF3B82F6),
                                        barWidth: 3,
                                        dotData: FlDotData(
                                          show: true,
                                          getDotPainter: (spot, percent, barData, index) {
                                            return FlDotCirclePainter(
                                              radius: 4,
                                              color: isConcluida 
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF3B82F6),
                                              strokeWidth: 2,
                                              strokeColor: Colors.white,
                                            );
                                          },
                                        ),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: (isConcluida 
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF3B82F6))
                                              .withOpacity(0.1),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              (isConcluida 
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF3B82F6))
                                                  .withOpacity(0.3),
                                              (isConcluida 
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFF3B82F6))
                                                  .withOpacity(0.05),
                                            ],
                                          ),
                                        ),
                                        shadow: Shadow(
                                          blurRadius: 8,
                                          color: (isConcluida 
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFF3B82F6))
                                              .withOpacity(0.3),
                                          offset: const Offset(0, 4),
                                        ),
                                      ),
                                    ],
                                                                         lineTouchData: LineTouchData(
                                       enabled: true,
                                       touchTooltipData: LineTouchTooltipData(
                                         getTooltipColor: (touchedSpot) => Colors.white,
                                         tooltipRoundedRadius: 8,
                                         tooltipBorder: BorderSide(
                                           color: const Color(0xFFE5E7EB),
                                           width: 1,
                                         ),
                                        getTooltipItems: (touchedSpots) {
                                          return touchedSpots.map((touchedSpot) {
                                            final index = touchedSpot.x.toInt();
                                            final spots = _getChartSpots(widget.meta);
                                            if (index >= 0 && index < spots.length) {
                                              final date = _getDateFromSpot(index, widget.meta);
                                              return LineTooltipItem(
                                                '${touchedSpot.y.toStringAsFixed(1)} ${widget.meta.tipo.unidade}\n',
                                                TextStyle(
                                                  color: isConcluida 
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFF3B82F6),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: DateFormat('dd/MM/yyyy HH:mm').format(date),
                                                    style: const TextStyle(
                                                      color: Color(0xFF6B7280),
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }
                                            return null;
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Botão para mostrar/ocultar histórico
                      if (meta.progressos.isNotEmpty)
                        Row(
                          children: [
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showHistorico = !_showHistorico;
                                  });
                                },
                                icon: Icon(
                                  _showHistorico ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  color: const Color(0xFF3B82F6),
                                ),
                                label: Text(
                                  _showHistorico ? 'Ocultar Histórico' : 'Ver Histórico Completo',
                                  style: const TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      
                      // Histórico expandível
                      if (_showHistorico && meta.progressos.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Histórico Completo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...meta.progressos.map((progresso) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE5E7EB)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.trending_up,
                                          color: Color(0xFF3B82F6),
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${progresso.valor.toStringAsFixed(1)} ${meta.tipo.unidade}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF374151),
                                              ),
                                            ),
                                            if (progresso.observacao != null)
                                              Text(
                                                progresso.observacao!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd/MM/yyyy HH:mm').format(progresso.data),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Botões de ação
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: widget.onAtualizarProgresso,
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Atualizar'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: widget.onExcluir,
                            icon: const Icon(Icons.delete_outline),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Ícone de concluído no canto superior direito
                if (isConcluida)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                
                // Selo de concluída
                if (isConcluida)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildValueCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTipoColor(TipoMeta tipo) {
    switch (tipo) {
      case TipoMeta.peso:
        return const Color(0xFF8B5CF6);
      case TipoMeta.distancia:
        return const Color(0xFF06B6D4);
      case TipoMeta.repeticoes:
        return const Color(0xFFF59E0B);
      case TipoMeta.frequencia:
        return const Color(0xFF10B981);
      case TipoMeta.carga:
        return const Color(0xFFEF4444);
      case TipoMeta.medidas:
        return const Color(0xFFEC4899);
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

  double _getGridInterval(Meta meta) {
    final range = _getMaxY(meta) - _getMinY(meta);
    if (range <= 10) return 2;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    return 20;
  }

  double _getLeftInterval(Meta meta) {
    final range = _getMaxY(meta) - _getMinY(meta);
    if (range <= 10) return 2;
    if (range <= 50) return 5;
    if (range <= 100) return 10;
    return 20;
  }

  double _getBottomInterval(Meta meta) {
    final spots = _getChartSpots(meta);
    if (spots.length <= 5) return 1;
    if (spots.length <= 10) return 2;
    if (spots.length <= 20) return 3;
    return 5;
  }

  DateTime _getDateFromSpot(int index, Meta meta) {
    if (index == 0) {
      return meta.dataCriacao;
    }
    
    // Ordenar progressos por data (mais antigo primeiro) para o gráfico
    final progressosOrdenados = List<ProgressoMeta>.from(meta.progressos);
    progressosOrdenados.sort((a, b) => a.data.compareTo(b.data));
    
    if (index - 1 < progressosOrdenados.length) {
      return progressosOrdenados[index - 1].data;
    }
    
    return meta.dataCriacao;
  }
} 