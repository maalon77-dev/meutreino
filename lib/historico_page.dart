import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoricoPage extends StatefulWidget {
  const HistoricoPage({Key? key}) : super(key: key);

  @override
  State<HistoricoPage> createState() => _HistoricoPageState();
}

class _HistoricoPageState extends State<HistoricoPage> {
  bool loading = true;
  String? erro;
  List historico = [];
  DateTime _selectedMonth = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  double totalKg = 0;
  int totalTempo = 0;
  double totalKm = 0;
  Set<String> datasTreino = {};

  @override
  void initState() {
    super.initState();
    _buscarUsuarioIdEHistorico();
    _carregarNomesTreinos();
  }

  Future<void> _buscarUsuarioIdEHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioId = prefs.getInt('usuario_id') ?? 0;
    if (usuarioId == 0) {
      if (mounted) {
        setState(() {
          erro = 'Usuário não identificado. Faça login novamente.';
          loading = false;
        });
      }
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
        if (mounted) {
          setState(() {
            historico = dados;
            totalKg = 0;
            totalTempo = 0;
            totalKm = 0;
            datasTreino.clear();
            
            for (var r in historico) {
              totalKg += double.tryParse(r['kg_levantados'].toString()) ?? 0;
              totalTempo += int.tryParse(r['tempo_treino_minutos'].toString()) ?? 0;
              totalKm += double.tryParse(r['distancia_km'].toString()) ?? 0;
              datasTreino.add(r['data_registro'].toString().substring(0, 10));
            }
            loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            erro = 'Erro ao buscar histórico (Status: ${response.statusCode})';
            loading = false;
          });
        }
      }
    } catch (e) {
      print('Erro na requisição: $e');
      if (mounted) {
        setState(() {
          erro = 'Erro de conexão: $e';
          loading = false;
        });
      }
    }
  }

  void _onMonthChanged(DateTime focusedDay) {
    if (mounted) {
      setState(() {
        _selectedMonth = DateTime(focusedDay.year, focusedDay.month);
        _focusedDay = focusedDay;
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (mounted) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  List<DateTime> _getEventsForDay(DateTime day) {
    return datasTreino
        .where((dateStr) {
          try {
            final eventDate = DateTime.parse(dateStr);
            return eventDate.year == day.year &&
                   eventDate.month == day.month &&
                   eventDate.day == day.day;
          } catch (e) {
            return false;
          }
        })
        .map((dateStr) => DateTime.parse(dateStr))
        .toList();
  }

  // Método para verificar se um dia tem treino
  bool _hasEventForDay(DateTime day) {
    return datasTreino.any((dateStr) {
      try {
        final eventDate = DateTime.parse(dateStr);
        return eventDate.year == day.year &&
               eventDate.month == day.month &&
               eventDate.day == day.day;
      } catch (e) {
        return false;
      }
    });
  }

  // Método para verificar se um dia está selecionado
  bool _isSelectedDay(DateTime day) {
    return _selectedDay != null &&
           day.year == _selectedDay!.year &&
           day.month == _selectedDay!.month &&
           day.day == _selectedDay!.day;
  }

  // Método para verificar se um dia é hoje
  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year &&
           day.month == now.month &&
           day.day == now.day;
  }

  // Método para gerar os dias do mês
  List<List<DateTime?>> _generateCalendarDays() {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final firstDay = DateTime(year, month, 1);
    final lastDay = DateTime(year, month + 1, 0);
    
    // Ajustar para segunda-feira como primeiro dia da semana
    final firstWeekday = firstDay.weekday;
    final startOffset = firstWeekday == 1 ? 0 : firstWeekday - 1;
    
    final days = <List<DateTime?>>[];
    List<DateTime?> currentWeek = [];
    
    // Adicionar dias vazios no início
    for (int i = 0; i < startOffset; i++) {
      currentWeek.add(null);
    }
    
    // Adicionar dias do mês
    for (int day = 1; day <= lastDay.day; day++) {
      currentWeek.add(DateTime(year, month, day));
      
      if (currentWeek.length == 7) {
        days.add(List.from(currentWeek));
        currentWeek = [];
      }
    }
    
    // Adicionar dias vazios no final se necessário
    while (currentWeek.length < 7) {
      currentWeek.add(null);
    }
    if (currentWeek.isNotEmpty) {
      days.add(currentWeek);
    }
    
    return days;
  }

  // Método para obter o nome do mês
  String _getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }

  // Método para construir um dia do calendário
  Widget _buildCalendarDay(DateTime? day) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (day == null) {
      return Container(
        margin: const EdgeInsets.all(2),
        height: 32,
      );
    }
    final hasEvent = _hasEventForDay(day);
    final isSelected = _isSelectedDay(day);
    final isToday = _isToday(day);

    // Buscar todos os treinos desse dia
    final treinosDoDia = historico.where((item) {
      try {
        final d = DateTime.parse(item['data_registro']);
        return d.year == day.year && d.month == day.month && d.day == day.day;
      } catch (e) {
        return false;
      }
    }).toList();

    String tooltipText = '';
    if (treinosDoDia.isNotEmpty) {
      tooltipText = treinosDoDia.map((item) {
        final nome = _getNomeTreino(item['treino_id']);
        final minutos = int.tryParse(item['tempo_treino_minutos'].toString()) ?? 0;
        final horas = minutos ~/ 60;
        final mins = minutos % 60;
        String duracao = horas > 0 ? '${horas}h ' : '';
        duracao += '${mins}min';
        return '$nome\nDuração: $duracao';
      }).join('\n---\n');
    }

    Widget diaWidget = Stack(
      alignment: Alignment.center,
      children: [
        // Número do dia
        Text(
          day.day.toString(),
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : hasEvent
                    ? const Color(0xFF3B82F6) // Azul médio
                    : isDark
                        ? Colors.white
                        : const Color(0xFF374151),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        // Ícone de treino (pequeno, no canto superior direito)
        if (hasEvent)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white 
                    : const Color(0xFF3B82F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 6,
                color: isSelected 
                    ? const Color(0xFF3B82F6) 
                    : Colors.white,
              ),
            ),
          ),
        // Ícone de hoje (pequeno, no canto inferior esquerdo)
        if (isToday)
          Positioned(
            bottom: 2,
            left: 2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white 
                    : const Color(0xFF10B981), // Verde para hoje
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.today,
                size: 6,
                color: isSelected 
                    ? const Color(0xFF10B981) 
                    : Colors.white,
              ),
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: () {
        if (hasEvent) {
          // Montar título customizado
          final diasSemana = [
            'Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'
          ];
          final meses = [
            'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
            'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
          ];
          final diaSemana = diasSemana[day.weekday - 1];
          final mesExtenso = meses[day.month - 1];
          final titulo = 'Treino de $diaSemana, dia ${day.day} de $mesExtenso de ${day.year}';

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(titulo),
              content: Text(tooltipText),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          );
        }
        _onDaySelected(day, day);
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : hasEvent
                  ? const Color(0xFF3B82F6).withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : hasEvent
                    ? const Color(0xFF3B82F6).withOpacity(0.3)
                    : isDark
                        ? const Color(0xFF475569)
                        : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        height: 32,
        child: diaWidget,
      ),
    );
  }

  List _getTreinosDoMes() {
    return historico.where((item) {
      try {
        final itemDate = DateTime.parse(item['data_registro']);
        return itemDate.year == _selectedMonth.year && 
               itemDate.month == _selectedMonth.month;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  List _getUltimosTreinos() {
    // Ordenar por data mais recente e pegar apenas os últimos 5
    final treinosOrdenados = List.from(historico);
    treinosOrdenados.sort((a, b) => DateTime.parse(b['data_registro']).compareTo(DateTime.parse(a['data_registro'])));
    return treinosOrdenados.take(5).toList();
  }

  String _getDiaSemana(String dataRegistro) {
    try {
      final date = DateTime.parse(dataRegistro);
      final diasSemana = ['Domingo', 'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado'];
      return diasSemana[date.weekday - 1];
    } catch (e) {
      return '';
    }
  }

  Map<int, String> _nomesTreinos = {};
  bool _carregandoNomesTreinos = true;

  Future<void> _carregarNomesTreinos() async {
    try {
      final response = await http.get(
        Uri.parse('https://airfit.online/api/api.php?tabela=treinos&acao=listar_todos'),
      );
      
      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _nomesTreinos.clear();
            for (var treino in dados) {
              final id = int.tryParse(treino['id'].toString());
              if (id != null) {
                _nomesTreinos[id] = treino['nome_treino'] ?? 'Treino';
              }
            }
            print('MAPA DE NOMES DOS TREINOS: \n');
            _nomesTreinos.forEach((k, v) => print('id: ' + k.toString() + ' nome: ' + v));
            _carregandoNomesTreinos = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _carregandoNomesTreinos = false;
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar nomes dos treinos: $e');
      if (mounted) {
        setState(() {
          _carregandoNomesTreinos = false;
        });
      }
    }
  }

  String _getNomeTreino(dynamic treinoId) {
    final id = int.tryParse(treinoId.toString());
    print('Buscando nome para treino_id: ' + treinoId.toString() + ' (convertido: ' + (id?.toString() ?? 'null') + ')');
    if (id != null && _nomesTreinos.containsKey(id)) {
      print('Encontrado: ' + _nomesTreinos[id]!);
      return _nomesTreinos[id]!;
    }
    print('NÃO ENCONTRADO!');
    return 'Treino';
  }

  double _getPesoTotalDoMes() {
    return _getTreinosDoMes().fold(0.0, (sum, item) {
      return sum + (double.tryParse(item['kg_levantados'].toString()) ?? 0);
    });
  }

  int _getTempoTotalDoMes() {
    return _getTreinosDoMes().fold(0, (sum, item) {
      return sum + (int.tryParse(item['tempo_treino_minutos'].toString()) ?? 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF020617), const Color(0xFF0F172A)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Título e subtítulo
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico de Treinos',
                      style: textTheme.headlineLarge?.copyWith(
                        color: isDark ? Colors.white : const Color(0xFF374151),
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Veja seu progresso e conquistas',
                      style: textTheme.bodyLarge?.copyWith(
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Card do calendário
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                                    _focusedDay = _selectedMonth;
                                  });
                                }
                              },
                              icon: Icon(Icons.chevron_left, color: const Color(0xFF3B82F6)),
                            ),
                            Text(
                              '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF374151),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                                    _focusedDay = _selectedMonth;
                                  });
                                }
                              },
                              icon: Icon(Icons.chevron_right, color: const Color(0xFF3B82F6)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            for (final d in ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'])
                              Expanded(
                                child: Center(
                                  child: Text(
                                    d,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Dias do calendário
                        for (final week in _generateCalendarDays())
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                for (final day in week)
                                  Expanded(child: _buildCalendarDay(day)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Card do resumo do mês
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bar_chart_outlined, color: const Color(0xFF3B82F6), size: 28),
                            const SizedBox(width: 10),
                            Text(
                              'Resumo do mês',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF374151),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMonthStat('Treinos', _getTreinosDoMes().length.toString(), Icons.fitness_center_outlined, const Color(0xFF3B82F6)),
                            _buildMonthStat('Peso Total', '${_getPesoTotalDoMes().toStringAsFixed(0)} kg', Icons.monitor_weight_outlined, const Color(0xFF60A5FA)),
                            _buildMonthStat('Tempo Total', '${_getTempoTotalDoMes()} min', Icons.timer_outlined, const Color(0xFF93C5FD)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Últimos treinos
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  'Últimos Treinos',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    ...(_carregandoNomesTreinos
                        ? [const Center(child: CircularProgressIndicator())]
                        : _getUltimosTreinos().map((item) => Card(
                              elevation: 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.check_circle_outline, color: const Color(0xFF3B82F6), size: 28),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getNomeTreino(item['treino_id']),
                                            style: textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getDiaSemana(item['data_registro']),
                                            style: textTheme.bodySmall?.copyWith(
                                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.timer_outlined, size: 16, color: const Color(0xFF60A5FA)),
                                              const SizedBox(width: 4),
                                              Text('${item['tempo_treino_minutos']} min', style: textTheme.bodySmall),
                                              const SizedBox(width: 16),
                                              Icon(Icons.monitor_weight_outlined, size: 16, color: const Color(0xFF93C5FD)),
                                              const SizedBox(width: 4),
                                              Text('${item['kg_levantados']} kg', style: textTheme.bodySmall),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF3B82F6).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Concluído',
                                        style: const TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )).toList()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthStat(String label, String value, IconData icon, Color color) {
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
            fontWeight: FontWeight.w700,
            color: color,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF94A3B8) : const Color(0xFF6B7280), // Azul claro
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xFF94A3B8) : const Color(0xFF6B7280), // Azul claro
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
      } else {
        return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
    } catch (e) {
      return data;
    }
  }
} 