import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Import para Timer
import 'dart:math'; // Import para Random
import 'home_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';
import 'widgets/optimized_gif_widget.dart';
import 'treinos_prontos_page.dart';
import 'widgets/app_bar_logo.dart';


class TimeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove todos os caracteres não numéricos
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Limita a 6 dígitos (HHMMSS)
    if (text.length > 6) {
      text = text.substring(0, 6);
    }
    
    // Formata o texto
    String formattedText = '';
    if (text.length >= 1) {
      formattedText = text.substring(0, 1);
    }
    if (text.length >= 2) {
      formattedText = text.substring(0, 2);
    }
    if (text.length >= 3) {
      formattedText = '${text.substring(0, 2)}:${text.substring(2, 3)}';
    }
    if (text.length >= 4) {
      formattedText = '${text.substring(0, 2)}:${text.substring(2, 4)}';
    }
    if (text.length >= 5) {
      formattedText = '${text.substring(0, 2)}:${text.substring(2, 4)}:${text.substring(4, 5)}';
    }
    if (text.length >= 6) {
      formattedText = '${text.substring(0, 2)}:${text.substring(2, 4)}:${text.substring(4, 6)}';
    }
    
    // Valida os valores
    if (formattedText.length >= 2) {
      int hours = int.tryParse(formattedText.substring(0, 2)) ?? 0;
      if (hours > 23) {
        formattedText = '23${formattedText.substring(2)}';
      }
    }
    
    if (formattedText.length >= 5) {
      int minutes = int.tryParse(formattedText.substring(3, 5)) ?? 0;
      if (minutes > 59) {
        formattedText = '${formattedText.substring(0, 3)}59${formattedText.substring(5)}';
      }
    }
    
    if (formattedText.length >= 8) {
      int seconds = int.tryParse(formattedText.substring(6, 8)) ?? 0;
      if (seconds > 59) {
        formattedText = '${formattedText.substring(0, 6)}59';
      }
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class HomePageWithIndex extends StatefulWidget {
  final int initialIndex;
  
  const HomePageWithIndex({Key? key, required this.initialIndex}) : super(key: key);

  @override
  State<HomePageWithIndex> createState() => _HomePageWithIndexState();
}

class _HomePageWithIndexState extends State<HomePageWithIndex> {
  @override
  Widget build(BuildContext context) {
    return HomePage(initialIndex: widget.initialIndex);
  }
}

class TreinarPage extends StatefulWidget {
  final void Function(Map<String, dynamic> treino)? onTreinoSelecionado;
  TreinarPage({this.onTreinoSelecionado, Key? key}) : super(key: key);

  @override
  State<TreinarPage> createState() => _TreinarPageState();
}

class _TreinarPageState extends State<TreinarPage> {
  List<Map<String, dynamic>> treinosUsuario = [];
  bool isLoading = true;
  Map<int, String> nomesTreinos = {};
  bool isReordering = false;
  
  // GlobalKey para o Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _carregarTreinosUsuario();
  }

  Future<void> _carregarTreinosUsuario() async {
    try {
      setState(() {
        isLoading = true;
      });
      
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      if (usuarioId != null && usuarioId > 0) {
        await _buscarTreinosUsuario(usuarioId);
        await _buscarNomesTreinos();
      }
    } catch (e) {
      print('Erro ao carregar treinos: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Função para recarregar treinos sem mostrar loading
  Future<void> _recarregarTreinos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      if (usuarioId != null && usuarioId > 0) {
        await _buscarTreinosUsuario(usuarioId);
        await _buscarNomesTreinos();
      }
    } catch (e) {
      print('Erro ao recarregar treinos: $e');
    }
  }

  Future<void> _buscarTreinosUsuario(int usuarioId) async {
    try {
      print('Buscando treinos para usuário ID: $usuarioId');
      final response = await http.get(
        Uri.parse('https://airfit.online/api/api.php?tabela=treinos&acao=listar_treinos_usuario&usuario_id=$usuarioId'),
      );

      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final List dados = jsonDecode(response.body);
        final List<Map<String, dynamic>> treinosOrdenados = List<Map<String, dynamic>>.from(dados);
        
        print('Treinos recebidos: ${treinosOrdenados.length} registros');
        
        setState(() {
          treinosUsuario = treinosOrdenados;
        });
      } else {
        print('Erro na resposta: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar treinos: $e');
    }
  }

  Future<void> _buscarNomesTreinos() async {
    try {
      final response = await http.get(
        Uri.parse('https://airfit.online/api/api.php?tabela=treinos&acao=listar_treinos'),
      );

      if (response.statusCode == 200) {
        final dynamic dados = jsonDecode(response.body);
        final Map<int, String> nomes = {};
        
        if (dados is List) {
          for (var treino in dados) {
            if (treino is Map<String, dynamic>) {
              nomes[treino['id']] = treino['nome'];
            }
          }
        }
        
        print('MAPA DE NOMES DOS TREINOS: ');
        nomes.forEach((id, nome) {
          print('id: $id nome: $nome');
        });
        
        setState(() {
          nomesTreinos = nomes;
        });
      }
    } catch (e) {
      print('Erro ao buscar nomes dos treinos: $e');
    }
  }

  String _obterNomeTreino(Map<String, dynamic> treino) {
    return treino['nome_treino'] ?? 'Treino';
  }

  Future<void> _salvarNovaOrdem() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      if (usuarioId == null) return;

      // Preparar dados para enviar
      final dados = treinosUsuario.asMap().entries.map((entry) {
        return {
          'id': entry.value['id'],
          'ordem': entry.key,
        };
      }).toList();

      final response = await http.post(
        Uri.parse('https://airfit.online/api/reorder_exercicios.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuario_id': usuarioId,
          'treinos': dados,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['success'] == true) {
          print('Ordem dos treinos salva com sucesso!');
          // Feedback visual para o usuário
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Ordem dos treinos atualizada!'),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        } else {
          print('Erro ao salvar ordem: ${result['message']}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao salvar ordem: ${result['message']}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        print('Erro na requisição: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao conectar com o servidor'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao salvar ordem dos treinos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar ordem dos treinos'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _abrirExerciciosTreino(BuildContext context, Map<String, dynamic> treino) async {
    print('Clicou no treino: ' + (treino['nome_treino'] ?? treino.toString()));
    final treinoId = treino['id'];
    if (treinoId == null) {
      print('Erro: ID do treino é nulo');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ID do treino não encontrado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    print('ID do treino: $treinoId');
    final url = Uri.parse('https://airfit.online/api/get_exercicios.php?id_treino=$treinoId');
    print('URL da requisição: $url');
    
    try {
      final response = await http.get(url);
      print('Status da resposta: ${response.statusCode}');
      print('Corpo da resposta RAW: "${response.body}"');
      print('Tamanho do corpo: ${response.body.length}');
      print('Corpo está vazio: ${response.body.isEmpty}');
      print('Corpo trimmed: "${response.body.trim()}"');
      print('Começa com [: ${response.body.trim().startsWith('[')}');
      
      List<Map<String, dynamic>> exercicios = [];
      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final bodyTrimmed = response.body.trim();
          if (bodyTrimmed.startsWith('[')) {
            try {
              final List dados = jsonDecode(bodyTrimmed);
              exercicios = dados.map((item) => Map<String, dynamic>.from(item)).toList();
              print('Exercícios encontrados: ${exercicios.length}');
              print('Dados dos exercícios: $exercicios');
            } catch (e) {
              print('Erro ao fazer parse do JSON: $e');
            }
          } else if (bodyTrimmed.startsWith('{')) {
            try {
              final Map<String, dynamic> dados = jsonDecode(bodyTrimmed);
              print('Resposta em formato de objeto: $dados');
              if (dados.containsKey('erro')) {
                print('Erro retornado pela API: ${dados['erro']}');
              }
            } catch (e) {
              print('Erro ao fazer parse do JSON objeto: $e');
            }
          } else {
            print('Resposta não é JSON válido. Conteúdo: "$bodyTrimmed"');
          }
        } else {
          print('Resposta da API está completamente vazia.');
        }
      } else {
        print('Erro na resposta: ${response.statusCode}');
        print('Corpo do erro: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar exercícios. Status: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      if (widget.onTreinoSelecionado != null) {
        widget.onTreinoSelecionado!({
          ...treino,
          'exercicios': exercicios,
        });
      }
    } catch (e) {
      print('Erro ao carregar exercícios: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar exercícios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF8FAFC), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _recarregarTreinos,
        color: const Color(0xFF3B82F6),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seção de treinos do usuário
            if (isLoading) ...[
              // Mostrar loading enquanto carrega
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ] else if (treinosUsuario.isNotEmpty) ...[
              Text(
                'Meus Treinos',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 16),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = treinosUsuario.removeAt(oldIndex);
                    treinosUsuario.insert(newIndex, item);
                  });
                  _salvarNovaOrdem();
                },
                itemCount: treinosUsuario.length,
                itemBuilder: (context, index) {
                  final treino = treinosUsuario[index];
                  return _treinoCard(
                  context,
                  treino: treino,
                  nomeTreino: _obterNomeTreino(treino),
                    index: index,
                    key: ValueKey(treino['id']),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Aviso de arrastar para reordenar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6B7280).withOpacity(0.15),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.swap_vert,
                      size: 12,
                      color: const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Arrastar para reordenar',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ] else if (!isLoading) ...[
              // Mensagem quando não há treinos cadastrados
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(24),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center_outlined,
                        size: 48,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum treino cadastrado',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF374151),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Você ainda não criou nenhum treino personalizado. Use o botão "Criar Treino" abaixo para começar!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                  ],
                ),
              ),
            ],
            
            // Banner Treinos Personalizados
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                image: DecorationImage(
                  image: const AssetImage('assets/backgrounds/criar-treino.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5),
                    BlendMode.darken,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Treinos Personalizados',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Escolha seus exercícios favoritos e crie seu treino diário personalizado.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.9),
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
                      onPressed: () {
                        print('DEBUG: Botão Criar Treino clicado');
                        _mostrarDialogoCriarTreino();
                      },
                      child: Text(
                        'Criar Treino',
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
            
            // Banner Treinos Prontos
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF3B82F6), const Color(0xFF60A5FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(28),
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
                          Icons.rocket_launch,
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
                              'Treinos Prontos',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Escolha entre diversos treinos já prontos com todos os exercícios já estabelecidos, criados por profissionais.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TreinosProntosPage(),
                          ),
                        );
                        // Recarregar treinos quando retornar da página de treinos prontos
                        await _recarregarTreinos();
                        
                        // Feedback visual para o usuário
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.refresh, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text('Lista de treinos atualizada!'),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Treinos Prontos',
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
          ],
        ),
        ),
      ),
    );
  }

  Widget _treinoCard(BuildContext context, {
    required Map<String, dynamic> treino,
    required String nomeTreino,
    int index = 0,
    Key? key,
  }) {
    return TweenAnimationBuilder<double>(
      key: key,
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + (index * 60)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: GestureDetector(
      onTap: () => _abrirExerciciosTreino(context, treino),
      child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
              // Número da ordem
            Container(
                width: 28,
                height: 28,
              decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                    nomeTreino,
                            style: GoogleFonts.inter(
                      color: const Color(0xFF1F2937),
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              letterSpacing: -0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${treino['total_exercicios'] ?? 0} exercícios',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w400,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _mostrarDialogoEditarTreino(treino),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoCriarTreino() async {
    print('DEBUG: Função _mostrarDialogoCriarTreino chamada');
    final TextEditingController nomeController = TextEditingController();
    bool isLoading = false;
    bool nomeVazio = true;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
          children: [
            Container(
                    padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                      Icons.add_circle_outline,
                color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Criar Novo Treino',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Digite o nome do seu novo treino:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    onChanged: (value) {
                      setState(() {
                        nomeVazio = value.trim().isEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Ex: Treino A - Peito e Tríceps',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) async {
                      if (nomeController.text.trim().isNotEmpty) {
                        await _criarTreino(nomeController.text.trim());
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading || nomeVazio
                      ? null
                      : () async {
                          setState(() => isLoading = true);
                          await _criarTreino(nomeController.text.trim());
                          Navigator.of(context).pop();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Criar Treino',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _criarTreino(String nomeTreino) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      if (usuarioId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usuário não identificado'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('https://airfit.online/api/api.php'),
        body: {
          'tabela': 'treinos',
          'acao': 'inserir',
          'usuario_id': usuarioId.toString(),
          'nome_treino': nomeTreino,
          'estatisticas': '',
          'id_exercicios': '',
          'foto_treino': 'img/treino-feminino/14.jpg',
          'ordem': '0',
        },
      );

      final data = jsonDecode(response.body);
      print('DEBUG: Resposta da API: $data');
      
      if (data['sucesso'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Treino "$nomeTreino" criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recarregar a lista de treinos
        _carregarTreinosUsuario();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar treino: ${data['erro'] ?? 'Erro desconhecido'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _mostrarDialogoEditarTreino(Map<String, dynamic> treino) async {
    final TextEditingController nomeController = TextEditingController(text: treino['nome_treino'] ?? '');
    bool isLoading = false;
    bool nomeVazio = nomeController.text.trim().isEmpty;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Color(0xFF3B82F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Editar Treino',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Digite o novo nome do treino:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nomeController,
                    onChanged: (value) {
                      setState(() {
                        nomeVazio = value.trim().isEmpty;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Ex: Treino A - Peito e Tríceps',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) async {
                      if (nomeController.text.trim().isNotEmpty) {
                        await _editarTreino(treino['id'], nomeController.text.trim());
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 16),
                  // Botões de Ação
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: const Color(0xFFF59E0B).withOpacity(0.3),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading || nomeVazio
                              ? null
                              : () async {
                                  setState(() => isLoading = true);
                                  await _editarTreino(treino['id'], nomeController.text.trim());
                                  Navigator.of(context).pop();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: const Color(0xFF3B82F6).withOpacity(0.3),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Salvar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Botão Excluir
                      Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                      label: const Text(
                        'Excluir Treino',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B7280),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        shadowColor: const Color(0xFF6B7280).withOpacity(0.3),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _mostrarDialogoExcluirTreino(treino);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _editarTreino(int treinoId, String novoNome) async {
    try {
      final response = await http.post(
        Uri.parse('https://airfit.online/api/api.php'),
        body: {
          'tabela': 'treinos',
          'acao': 'atualizar',
          'id': treinoId.toString(),
          'nome_treino': novoNome,
        },
      );

      final data = jsonDecode(response.body);
      print('DEBUG: Resposta da API (editar): $data');
      
      if (data['sucesso'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Treino atualizado para "$novoNome" com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recarregar a lista de treinos
        _carregarTreinosUsuario();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar treino: ${data['erro'] ?? 'Erro desconhecido'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarDialogoExcluirTreino(Map<String, dynamic> treino) {
    int segundosRestantes = 10;
    late StateSetter setStateDialog;
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            setStateDialog = setState;
            if (timer == null) {
              timer = Timer.periodic(const Duration(seconds: 1), (t) {
                if (segundosRestantes > 0) {
                  setState(() {
                    segundosRestantes--;
                  });
                } else {
                  timer?.cancel();
                }
              });
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                    children: [
                      Container(
                    padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                    child: const Icon(
                      Icons.delete_forever,
                      color: Color(0xFFEF4444),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Excluir Treino',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                    'Tem certeza que deseja excluir o treino "${treino['nome_treino']}"?',
                              style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFFEAA7),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Color(0xFF856404),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Esta ação não pode ser desfeita. Todos os exercícios associados serão removidos.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF856404),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Todas as estatísticas de progresso também serão deletadas.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFFD97706),
                                  fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: segundosRestantes == 0
                      ? () {
                          timer?.cancel();
                          Navigator.of(context).pop();
                          _excluirTreino(treino);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: segundosRestantes == 0
                      ? const Text(
                          'Excluir',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Text(
                          'Aguarde (${segundosRestantes}s)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      timer?.cancel();
    });
  }

  Future<void> _excluirTreino(Map<String, dynamic> treino) async {
    try {
      final response = await http.post(
        Uri.parse('https://airfit.online/api/api.php'),
        body: {
          'tabela': 'treinos',
          'acao': 'deletar', // Corrigido para a ação correta da API
          'id': treino['id'].toString(),
        },
      );

      final data = jsonDecode(response.body);
      print('DEBUG: Resposta da API (excluir): $data');
      
      if (data['sucesso'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Treino "${treino['nome_treino']}" excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Recarregar a lista de treinos
        _carregarTreinosUsuario();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir treino: ${data['erro'] ?? 'Erro desconhecido'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro de conexão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 

class ExecucaoTreinoPage extends StatefulWidget {
  final String nomeTreino;
  final List<Map<String, dynamic>> exercicios;

  const ExecucaoTreinoPage({
    Key? key,
    required this.nomeTreino,
    required this.exercicios,
  }) : super(key: key);

  @override
  State<ExecucaoTreinoPage> createState() => _ExecucaoTreinoPageState();
}

class _ExecucaoTreinoPageState extends State<ExecucaoTreinoPage> 
    with TickerProviderStateMixin {
  int exercicioAtual = 0;
  int serieAtual = 1;
  late Stopwatch stopwatch;
  late final PageController _pageController;
  bool descansando = false;
  int tempoRestante = 0;
  Timer? timerDescanso;
  Timer? timerCronometro;
  int tempoTotalTreino = 0;
  int _selectedIndex = 2; // Treinar
  
  // GlobalKey para o Scaffold
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Controladores de animação
  late AnimationController _glowController;
  late AnimationController _buttonController;
  late AnimationController _progressController;
  late AnimationController _fadeController;
  late Animation<double> _glowAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inicializar de forma assíncrona
    _inicializarTreino();
    
    _pageController = PageController(initialPage: 0);
    
    // Inicializar animações
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    
    _buttonAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _progressController.forward();
    _fadeController.forward();
    
    // Inicializar timer para atualizar o cronômetro
    timerCronometro = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final tempoAtual = await _obterTempoTotalTreino();
      setState(() {
        tempoTotalTreino = tempoAtual;
      });
      
      // Verificar timeout de 5 horas
      if (tempoAtual >= 5 * 60 * 60) { // 5 horas em segundos
        print('Timeout de 5 horas atingido - resetando cronômetro');
        timer.cancel();
        await _limparCronometroPersistente();
        stopwatch.reset();
        stopwatch.start();
        await _salvarInicioTreino();
        setState(() {
          tempoTotalTreino = 0;
        });
        
        // Reiniciar o timer após timeout
        timerCronometro = Timer.periodic(const Duration(seconds: 1), (newTimer) async {
          final novoTempoAtual = await _obterTempoTotalTreino();
          setState(() {
            tempoTotalTreino = novoTempoAtual;
          });
          print('Cronômetro reiniciado: ${formatTime(novoTempoAtual)}');
        });
        
        return; // Sair da função atual
      }
      
      print('Cronômetro atualizado: ${formatTime(tempoAtual)}');
    });
  }

  @override
  void dispose() {
    stopwatch.stop();
    _pageController.dispose();
    timerDescanso?.cancel();
    timerCronometro?.cancel();
    _glowController.dispose();
    _buttonController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void avancarExercicio() {
    if (exercicioAtual < widget.exercicios.length - 1) {
      setState(() {
        exercicioAtual++;
        serieAtual = 1;
        descansando = false;
        tempoRestante = 0;
        timerDescanso?.cancel();
      });
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  Future<void> _trocarExercicioComFade() async {
    // Fade out
    await _fadeController.reverse();
    
    // Lógica para avançar exercício
    if (exercicioAtual < widget.exercicios.length - 1) {
      setState(() {
        exercicioAtual++;
        serieAtual = 1;
        descansando = false;
        tempoRestante = 0;
        timerDescanso?.cancel();
      });
    }
    
    // Fade in
    await _fadeController.forward();
  }

  Future<void> _pularExercicioComFade() async {
    // Fade out
    await _fadeController.reverse();
    
    setState(() {
      // Move o exercício atual (posição 0) para o final da lista de não concluídos
      final exercicioPulado = widget.exercicios.removeAt(0);
      
      // Encontrar a posição onde inserir (antes dos concluídos)
      int posicaoInsercao = widget.exercicios.length;
      for (int i = 0; i < widget.exercicios.length; i++) {
        if (widget.exercicios[i]['concluido'] == true) {
          posicaoInsercao = i;
          break;
        }
      }
      
      // Inserir o exercício pulado antes dos concluídos
      widget.exercicios.insert(posicaoInsercao, exercicioPulado);
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      // Resetar variáveis do treino - o próximo exercício não concluído se torna o principal
      exercicioAtual = 0;
      serieAtual = 1;
      descansando = false;
      tempoRestante = 0;
      timerDescanso?.cancel();
    });
    
    // Salvar o estado atualizado dos exercícios
    await _salvarEstadoExercicios();
    
    // Fade in
    await _fadeController.forward();
  }

  bool _isCardioDescanso = false; // Variável para controlar se é descanso de Cardio

  void iniciarDescanso(int segundos, {bool isCardio = false}) {
    setState(() {
      descansando = true;
      tempoRestante = segundos;
      _isCardioDescanso = isCardio; // Armazenar se é Cardio
    });
    timerDescanso?.cancel();
    timerDescanso = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (tempoRestante > 1) {
        setState(() {
          tempoRestante--;
        });
      } else {
        timer.cancel();
        setState(() {
          descansando = false;
          tempoRestante = 0;
          _isCardioDescanso = false; // Resetar a variável
        });
        // Vibrar 5 vezes ao terminar o descanso/exercício
        if (await Vibration.hasVibrator() ?? false) {
          for (int i = 0; i < 5; i++) {
            Vibration.vibrate(duration: 200);
            await Future.delayed(const Duration(milliseconds: 250));
          }
        }
      }
    });
  }

  void concluirSerie() {
    final ex = widget.exercicios[exercicioAtual];
    final categoria = ex['categoria']?.toString() ?? '';
    final totalSeries = int.tryParse(ex['numero_series']?.toString() ?? '1') ?? 1;
    final tempoDescanso = int.tryParse(ex['tempo_descanso']?.toString() ?? '0') ?? 0;
    
    // Para exercícios de Cardio, Alongamento ou Funcional, executa o tempo do exercício
    if (categoria == 'Cardio / Corrida' || categoria == 'Alongamento / Mobilidade' || categoria == 'Funcional') {
      final tempoExercicio = tempoDescanso; // Para todos, tempo_descanso é usado como tempo do exercício (min para cardio, seg para outros)
      if (tempoExercicio > 0) {
        final tempoExercicioSegundos = categoria == 'Cardio / Corrida' ? tempoExercicio * 60 : tempoExercicio;
        iniciarDescanso(tempoExercicioSegundos, isCardio: categoria == 'Cardio / Corrida');
      } else {
        // Se não há tempo definido, avança direto
        if (serieAtual < totalSeries) {
          setState(() {
            serieAtual++;
          });
        } else {
          avancarExercicio();
        }
      }
    } else {
      // Para outros tipos de exercício, mantém a lógica original
      if (serieAtual < totalSeries) {
        iniciarDescanso(tempoDescanso > 0 ? tempoDescanso : 0);
        setState(() {
          serieAtual++;
        });
      } else {
        avancarExercicio();
      }
    }
  }

  void pularExercicio() {
    _pularExercicioComFade();
  }

  void concluirExercicio() {
    _concluirExercicioComFade();
  }

  Future<void> _concluirExercicioComFade() async {
    // Fade out
    await _fadeController.reverse();
    
    setState(() {
      // Marcar o exercício atual como concluído
      widget.exercicios[0]['concluido'] = true;
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      // Resetar variáveis do treino
      exercicioAtual = 0;
      serieAtual = 1;
      descansando = false;
      tempoRestante = 0;
      timerDescanso?.cancel();
    });
    
    // Salvar o estado atualizado dos exercícios
    await _salvarEstadoExercicios();
    
    // Fade in
    await _fadeController.forward();
    
    // Verificar se todos os exercícios foram concluídos
    await _verificarConclusaoTreino();
  }

  Future<void> _trocarParaExercicioComFade(int idx) async {
    // Verificar se o exercício está concluído - se estiver, não permitir seleção
    if (widget.exercicios[idx]['concluido'] == true) {
      return; // Não fazer nada se o exercício já foi concluído
    }
    
    // Fade out
    await _fadeController.reverse();
    
    setState(() {
      final item = widget.exercicios.removeAt(idx);
      widget.exercicios.insert(0, item);
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      exercicioAtual = 0;
      serieAtual = 1;
      descansando = false;
      tempoRestante = 0;
      timerDescanso?.cancel();
    });
    
    // Salvar o estado atualizado dos exercícios
    await _salvarEstadoExercicios();
    
    // Fade in
    await _fadeController.forward();
  }

  Future<void> _inicializarCronometroPersistente() async {
    final prefs = await SharedPreferences.getInstance();
    final tempoInicioSalvo = prefs.getInt('treino_inicio_timestamp');
    final nomeTreinoSalvo = prefs.getString('treino_nome_ativo');
    
    if (tempoInicioSalvo != null && nomeTreinoSalvo == widget.nomeTreino) {
      // Verificar se passou mais de 5 horas (5 * 60 * 60 * 1000 = 18000000 ms)
      final agora = DateTime.now().millisecondsSinceEpoch;
      final tempoDecorrido = agora - tempoInicioSalvo;
      final cincoHoras = 5 * 60 * 60 * 1000; // 5 horas em milliseconds
      
      if (tempoDecorrido >= cincoHoras) {
        // Timeout de 5 horas - resetar cronômetro
        print('Timeout de 5 horas atingido - resetando cronômetro');
        await _limparCronometroPersistente();
        stopwatch = Stopwatch()..start();
        await _salvarInicioTreino();
      } else {
        // Cronômetro continua do ponto onde parou
        stopwatch = Stopwatch()..start();
        print('Cronômetro restaurado: ${tempoDecorrido ~/ 1000}s já decorridos');
      }
    } else {
      // Primeiro treino ou treino diferente - iniciar novo cronômetro
      stopwatch = Stopwatch()..start();
      await _salvarInicioTreino();
      print('Novo cronômetro iniciado');
    }
    
    // Inicializar o tempo total do treino
    tempoTotalTreino = await _obterTempoTotalTreino();
  }

  Future<void> _salvarInicioTreino() async {
    final prefs = await SharedPreferences.getInstance();
    final agora = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('treino_inicio_timestamp', agora);
    await prefs.setString('treino_nome_ativo', widget.nomeTreino);
    print('Início do treino salvo: ${DateTime.now()}');
  }

  Future<void> _salvarEstadoExercicios() async {
    final prefs = await SharedPreferences.getInstance();
    final estadoExercicios = widget.exercicios.map((exercicio) {
      return {
        'nome': exercicio['nome_do_exercicio'],
        'concluido': exercicio['concluido'] ?? false,
      };
    }).toList();
    
    final estadoJson = jsonEncode(estadoExercicios);
    await prefs.setString('estado_exercicios_${widget.nomeTreino}', estadoJson);
    print('Estado dos exercícios salvo: ${estadoExercicios.length} exercícios');
  }

  Future<void> _restaurarEstadoExercicios() async {
    final prefs = await SharedPreferences.getInstance();
    final estadoSalvo = prefs.getString('estado_exercicios_${widget.nomeTreino}');
    
    if (estadoSalvo != null) {
      try {
        final List<dynamic> estadoExercicios = jsonDecode(estadoSalvo);
        
        // Aplicar o estado salvo aos exercícios
        for (var exercicio in widget.exercicios) {
          final estadoSalvoExercicio = estadoExercicios.firstWhere(
            (e) => e['nome'] == exercicio['nome_do_exercicio'],
            orElse: () => null,
          );
          
          if (estadoSalvoExercicio != null) {
            exercicio['concluido'] = estadoSalvoExercicio['concluido'];
          }
        }
        
        print('Estado dos exercícios restaurado: ${estadoExercicios.length} exercícios');
      } catch (e) {
        print('Erro ao restaurar estado dos exercícios: $e');
      }
    }
  }

  Future<void> _limparCronometroPersistente() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('treino_inicio_timestamp');
    await prefs.remove('treino_nome_ativo');
    await prefs.remove('estado_exercicios_${widget.nomeTreino}');
    print('Cronômetro persistente e estado dos exercícios limpos');
  }

  Future<void> _inicializarTreino() async {
    // 1. Primeiro restaurar o estado dos exercícios
    await _restaurarEstadoExercicios();
    
    // 2. Verificar se todos os exercícios estão concluídos e resetar se necessário
    await _verificarEResetarExercicios();
    
    // 3. Inicializar cronômetro persistente
    await _inicializarCronometroPersistente();
    
    print('Treino inicializado com estado restaurado');
  }

  void _reorganizarLista() {
    // Separar exercícios não concluídos dos concluídos
    final List<Map<String, dynamic>> naoConcluidos = [];
    final List<Map<String, dynamic>> concluidos = [];
    
    for (var exercicio in widget.exercicios) {
      if (exercicio['concluido'] == true) {
        concluidos.add(exercicio);
      } else {
        naoConcluidos.add(exercicio);
      }
    }
    
    // Recompor a lista: não concluídos primeiro, concluídos depois
    widget.exercicios.clear();
    widget.exercicios.addAll(naoConcluidos);
    widget.exercicios.addAll(concluidos);
    
    print('Lista reorganizada: ${naoConcluidos.length} não concluídos, ${concluidos.length} concluídos');
  }

  Future<void> _verificarEResetarExercicios() async {
    final todosExerciciosConcluidos = widget.exercicios.every((ex) => ex['concluido'] == true);
    if (todosExerciciosConcluidos) {
      // Se todos estão concluídos, resetar todos os exercícios para disponíveis
      for (var exercicio in widget.exercicios) {
        exercicio['concluido'] = false;
      }
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      // Salvar o estado resetado
      await _salvarEstadoExercicios();
      
      print('Todos os exercícios foram resetados - treino reiniciado');
    } else {
      // Se nem todos estão concluídos, manter o estado atual
      // Apenas reorganizar para garantir que concluídos fiquem no final
      _reorganizarLista();
      print('Exercícios mantidos no estado atual - alguns ainda pendentes');
    }
  }

  Future<void> _resetarTodosExercicios() async {
    setState(() {
      // Resetar todos os exercícios
      for (var exercicio in widget.exercicios) {
        exercicio['concluido'] = false;
      }
      
      // Reorganizar a lista mantendo concluídos sempre no final
      _reorganizarLista();
      
      // Resetar variáveis do treino
      exercicioAtual = 0;
      serieAtual = 1;
      descansando = false;
      tempoRestante = 0;
      timerDescanso?.cancel();
      
      // Reiniciar cronômetro persistente
      stopwatch.reset();
      stopwatch.start();
    });
    
    // Reiniciar cronômetro persistente
    await _limparCronometroPersistente();
    await _salvarInicioTreino();
    
    // Salvar o estado resetado dos exercícios
    await _salvarEstadoExercicios();
    
    print('Treino resetado - todos os exercícios disponíveis novamente');
  }

  Future<void> _verificarConclusaoTreino() async {
    final todosExerciciosConcluidos = widget.exercicios.every((ex) => ex['concluido'] == true);
    if (todosExerciciosConcluidos) {
      stopwatch.stop();
      timerCronometro?.cancel(); // Parar o timer quando concluir
      
      // Calcular peso total
      double pesoTotal = _calcularPesoTotal();
      Map<String, dynamic> premio = _determinarPremio(pesoTotal);
      
      // Mostrar modal de tempo e KM primeiro, depois o prêmio
      if (mounted) {
        _mostrarModalTempoKm(pesoTotal, premio);
      }
    }
  }

  Future<void> _mostrarPopupConclusao() async {
    final tempoTotal = await _obterTempoTotalTreino();
    final TextEditingController kmController = TextEditingController();
    final TextEditingController tempoController = TextEditingController(text: formatTime(tempoTotal));
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: const Color(0xFF3B82F6), size: 24),
              const SizedBox(width: 8),
              Text(
                'Treino Concluído!',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Parabéns! Você concluiu todos os exercícios.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Tempo Total:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: tempoController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  TimeInputFormatter(),
                ],
                decoration: InputDecoration(
                  hintText: '00:00:00',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFF3B82F6)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: kmController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantos KM foram percorridos?',
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                  hintText: 'Ex: 5.5',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFF3B82F6)),
                  ),
                  suffixText: 'KM',
                  suffixStyle: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Resetar exercícios para continuar treinando
                _resetarTodosExercicios();
              },
              child: Text(
                'Continuar Treinando',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final kmPercorridos = double.tryParse(kmController.text) ?? 0.0;
                final tempoEditado = _parseTempoEditado(tempoController.text);
                _salvarTreinoCompleto(tempoEditado, kmPercorridos);
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Voltar para a tela anterior
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Salvar e Sair',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogConcluirTreino() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calcular quantos exercícios foram concluídos
    final exerciciosConcluidos = widget.exercicios.where((ex) => ex['concluido'] == true).length;
    final totalExercicios = widget.exercicios.length;
    
    // Verificar se pelo menos 1 exercício foi concluído
    if (exerciciosConcluidos == 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: const Color(0xFFF59E0B),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Nenhum Exercício Concluído',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF374151),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você precisa concluir pelo menos 1 exercício para finalizar o treino.',
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF374151),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF59E0B),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFFF59E0B),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Complete pelo menos um exercício para salvar o treino no seu histórico.',
                          style: TextStyle(
                            color: const Color(0xFF92400E),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Entendi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: const Color(0xFF10B981),
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Concluir Treino',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF374151),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deseja realmente concluir o treino?',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF374151),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.fitness_center,
                          color: const Color(0xFF3B82F6),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Progresso do Treino',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF374151),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$exerciciosConcluidos de $totalExercicios exercícios concluídos',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tempo total: ${formatTime(tempoTotalTreino)}',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'O treino será salvo no seu histórico, mesmo que todos os exercícios não tenham sido completados.',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _concluirTreino();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Concluir Treino',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Função para calcular o peso total carregado no treino
  double _calcularPesoTotal() {
    double pesoTotal = 0.0;
    bool temExerciciosComPeso = false;
    
    for (var exercicio in widget.exercicios) {
      if (exercicio['concluido'] == true) {
        final peso = double.tryParse(exercicio['peso']?.toString() ?? '0') ?? 0.0;
        
        // Verificar se o exercício tem peso
        if (peso > 0) {
          temExerciciosComPeso = true;
        final series = int.tryParse(exercicio['numero_series']?.toString() ?? '1') ?? 1;
        final repeticoes = int.tryParse(exercicio['numero_repeticoes']?.toString() ?? '1') ?? 1;
        
        // Peso total = peso × séries × repetições
        pesoTotal += peso * series * repeticoes;
        }
      }
    }
    
    // Se não há exercícios com peso, retornar 0 para indicar que deve mostrar premio Águia
    if (!temExerciciosComPeso) {
      return 0.0;
    }
    
    return pesoTotal;
  }

  // Função para obter o plural correto em português
  String _getPluralCorreto(String nomeAnimal, int quantidade) {
    if (quantidade == 1) return nomeAnimal;
    
    // Regras específicas para cada animal
    switch (nomeAnimal) {
      case 'Porco':
        return 'Porcos';
      case 'Cavalo':
        return 'Cavalos';
      case 'Vaca':
        return 'Vacas';
      case 'Touro':
        return 'Touros';
      case 'Rinoceronte':
        return 'Rinocerontes';
      case 'Elefante':
        return 'Elefantes';
      case 'Urso Pardo':
        return 'Ursos Pardos';
      case 'Camelo':
        return 'Camelos';
      case 'Girafa':
        return 'Girafas';
      case 'Hipopótamo':
        return 'Hipopótamos';
      case 'Canguru':
        return 'Cangurus';
      case 'Leão':
        return 'Leões';
      case 'Tigre':
        return 'Tigres';
      case 'Búfalo':
        return 'Búfalos';
      case 'Zebra':
        return 'Zebras';
      case 'Alce':
        return 'Alces';
      case 'Javali':
        return 'Javalis';
      case 'Panda':
        return 'Pandas';
      case 'Crocodilo':
        return 'Crocodilos';
      case 'Cervo':
        return 'Cervos';
      case 'Orangotango':
        return 'Orangotangos';
      case 'Tamanduá':
        return 'Tamanduás';
      case 'Avestruz':
        return 'Avestruzes';
      case 'Lhama':
        return 'Lhamas';
      case 'Foca':
        return 'Focas';
      case 'Urso Polar':
        return 'Ursos Polares';
      case 'Gnu':
        return 'Gnus';
      case 'Antílope':
        return 'Antílopes';
      case 'Urso Negro':
        return 'Ursos Negros';
      case 'Dromedário':
        return 'Dromedários';
      case 'Lobo':
        return 'Lobos';
      case 'Baleia Jubarte':
        return 'Baleias Jubarte';
      case 'Gorila':
        return 'Gorilas';
      case 'Chimpanzé':
        return 'Chimpanzés';
      default:
        // Regra geral: adicionar 's' no final
        return nomeAnimal + 's';
    }
  }

  // Função para determinar o prêmio baseado no peso total (SISTEMA RANDÔMICO)
  Map<String, dynamic> _determinarPremio(double pesoTotal) {
    // Verificar se há exercícios com peso no treino
    bool temExerciciosComPeso = false;
    for (var exercicio in widget.exercicios) {
      if (exercicio['concluido'] == true) {
        final peso = double.tryParse(exercicio['peso']?.toString() ?? '0') ?? 0.0;
        if (peso > 0) {
          temExerciciosComPeso = true;
          break;
        }
      }
    }
    
    // Se não há peso total (treino sem exercícios com peso)
    if (pesoTotal <= 0) {
      // Premios especiais para treinos sem peso
      final premiosSemPeso = [
        {'nome': 'Lobo', 'emoji': '🐺', 'cor': Color(0xFF2563EB), 'peso': 0.0},
        {'nome': 'Águia', 'emoji': '🦅', 'cor': Color(0xFF3B82F6), 'peso': 0.0},
        {'nome': 'Tigre', 'emoji': '🐅', 'cor': Color(0xFFFB923C), 'peso': 0.0},
        {'nome': 'Leão', 'emoji': '🦁', 'cor': Color(0xFF6B7280), 'peso': 0.0},
        {'nome': 'Dragão', 'emoji': '🐉', 'cor': Color(0xFFDC2626), 'peso': 0.0},
        {'nome': 'Raposa', 'emoji': '🦊', 'cor': Color(0xFFF59E0B), 'peso': 0.0},
        {'nome': 'Cavalo', 'emoji': '🐎', 'cor': Color(0xFF4B5563), 'peso': 0.0},
      ];
      
      // Frases motivacionais para treinos sem peso
      final frasesMotivacionais = [
        "Resistir é transformar fadiga em força.",
        "Cada gota de suor é um passo mais perto da sua melhor versão.",
        "Você é mais forte do que imagina. Continue.",
        "Dor é passageira, mas a resistência construída é para sempre.",
        "Não pare quando estiver cansado. Pare quando tiver terminado.",
        "Sua mente desiste antes do seu corpo. Prove que ela está errada.",
        "A constância vence o cansaço.",
        "A resistência é forjada nos momentos em que você quer desistir.",
        "O limite só existe até você superá-lo.",
        "Respire fundo e continue. Um passo de cada vez.",
        "Desistir não te leva a lugar nenhum. Resistir te leva além.",
        "Seja teimoso: resista mais um minuto.",
        "Não é sobre ser o mais rápido, é sobre nunca parar.",
        "Sua resistência é o seu superpoder.",
        "Os dias difíceis são os que mais constroem.",
        "Quanto mais você resiste, mais você cresce.",
        "Vencer a preguiça é o primeiro treino.",
        "Sinta o cansaço, mas não se renda a ele.",
        "A força física começa com a resistência mental.",
        "Persista. Porque a resistência de hoje é a força de amanhã.",
      ];
      
      final random = Random();
      final animalEscolhido = premiosSemPeso[random.nextInt(premiosSemPeso.length)];
      final fraseEscolhida = frasesMotivacionais[random.nextInt(frasesMotivacionais.length)];
      
      return {
        'nome': animalEscolhido['nome'],
        'emoji': animalEscolhido['emoji'],
        'cor': animalEscolhido['cor'],
        'peso': animalEscolhido['peso'],
        'descricao': fraseEscolhida,
      };
    }
    
    // Se há exercícios com peso, mas o peso total é baixo, dar chance de premios especiais
    if (pesoTotal > 0 && pesoTotal < 100 && !temExerciciosComPeso) {
      // 30% de chance de dar premio especial mesmo com peso baixo
      final random = Random();
      if (random.nextDouble() < 0.3) {
        final premiosSemPeso = [
          {'nome': 'Lobo', 'emoji': '🐺', 'cor': Color(0xFF2563EB), 'peso': 0.0},
          {'nome': 'Águia', 'emoji': '🦅', 'cor': Color(0xFF3B82F6), 'peso': 0.0},
          {'nome': 'Tigre', 'emoji': '🐅', 'cor': Color(0xFFFB923C), 'peso': 0.0},
          {'nome': 'Leão', 'emoji': '🦁', 'cor': Color(0xFF6B7280), 'peso': 0.0},
          {'nome': 'Dragão', 'emoji': '🐉', 'cor': Color(0xFFDC2626), 'peso': 0.0},
          {'nome': 'Raposa', 'emoji': '🦊', 'cor': Color(0xFFF59E0B), 'peso': 0.0},
          {'nome': 'Cavalo', 'emoji': '🐎', 'cor': Color(0xFF4B5563), 'peso': 0.0},
        ];
        
        final frasesMotivacionais = [
          "Resistir é transformar fadiga em força.",
          "Cada gota de suor é um passo mais perto da sua melhor versão.",
          "Você é mais forte do que imagina. Continue.",
          "Dor é passageira, mas a resistência construída é para sempre.",
          "Não pare quando estiver cansado. Pare quando tiver terminado.",
          "Sua mente desiste antes do seu corpo. Prove que ela está errada.",
          "A constância vence o cansaço.",
          "A resistência é forjada nos momentos em que você quer desistir.",
          "O limite só existe até você superá-lo.",
          "Respire fundo e continue. Um passo de cada vez.",
          "Desistir não te leva a lugar nenhum. Resistir te leva além.",
          "Seja teimoso: resista mais um minuto.",
          "Não é sobre ser o mais rápido, é sobre nunca parar.",
          "Sua resistência é o seu superpoder.",
          "Os dias difíceis são os que mais constroem.",
          "Quanto mais você resiste, mais você cresce.",
          "Vencer a preguiça é o primeiro treino.",
          "Sinta o cansaço, mas não se renda a ele.",
          "A força física começa com a resistência mental.",
          "Persista. Porque a resistência de hoje é a força de amanhã.",
        ];
        
        final animalEscolhido = premiosSemPeso[random.nextInt(premiosSemPeso.length)];
        final fraseEscolhida = frasesMotivacionais[random.nextInt(frasesMotivacionais.length)];
        
                 return {
           'nome': animalEscolhido['nome'],
           'emoji': animalEscolhido['emoji'],
           'cor': animalEscolhido['cor'],
           'peso': animalEscolhido['peso'],
           'descricao': fraseEscolhida,
         };
      }
    }
    
    final premiosAnimais = [
      {'nome': 'Porco', 'emoji': '🐖', 'cor': Color(0xFFEC4899), 'peso': 100.0, 'descricao': 'Você carregou o peso de um porco!'},
      {'nome': 'Cavalo', 'emoji': '🐎', 'cor': Color(0xFF4B5563), 'peso': 500.0, 'descricao': 'Você carregou um cavalo inteiro!'},
      {'nome': 'Vaca', 'emoji': '🐄', 'cor': Color(0xFF10B981), 'peso': 600.0, 'descricao': 'Você moveu o peso de uma vaca!'},
      {'nome': 'Touro', 'emoji': '🐂', 'cor': Color(0xFFEF4444), 'peso': 700.0, 'descricao': 'Força bruta! O peso de um touro!'},
      {'nome': 'Rinoceronte', 'emoji': '🦏', 'cor': Color(0xFF6D28D9), 'peso': 2300.0, 'descricao': 'Impressionante! Você ergueu um rinoceronte!'},
      {'nome': 'Elefante Africano', 'emoji': '🐘', 'cor': Color(0xFFF59E0B), 'peso': 6000.0, 'descricao': 'Gigante! O peso de um elefante africano!'},
      {'nome': 'Urso Pardo', 'emoji': '🐻', 'cor': Color(0xFF8B5CF6), 'peso': 350.0, 'descricao': 'Você suportou o peso de um urso pardo!'},
      {'nome': 'Camelo', 'emoji': '🐫', 'cor': Color(0xFFE11D48), 'peso': 650.0, 'descricao': 'Resistência total! Peso de um camelo!'},
      {'nome': 'Girafa', 'emoji': '🦒', 'cor': Color(0xFF10B981), 'peso': 800.0, 'descricao': 'Você se elevou como uma girafa!'},
      {'nome': 'Hipopótamo', 'emoji': '🦛', 'cor': Color(0xFF3B82F6), 'peso': 1500.0, 'descricao': 'Monstruoso! Peso de um hipopótamo!'},
      {'nome': 'Canguru', 'emoji': '🦘', 'cor': Color(0xFFEF4444), 'peso': 90.0, 'descricao': 'Pulou com o peso de um canguru!'},
      {'nome': 'Leão', 'emoji': '🦁', 'cor': Color(0xFF6B7280), 'peso': 190.0, 'descricao': 'Você rugiu com o peso de um leão!'},
      {'nome': 'Tigre', 'emoji': '🐅', 'cor': Color(0xFFFB923C), 'peso': 220.0, 'descricao': 'Ágil e forte como um tigre!'},
      {'nome': 'Búfalo', 'emoji': '🐃', 'cor': Color(0xFF2563EB), 'peso': 1000.0, 'descricao': 'Você puxou o peso de um búfalo!'},
      {'nome': 'Zebra', 'emoji': '🦓', 'cor': Color(0xFF7C3AED), 'peso': 380.0, 'descricao': 'Você manteve o ritmo de uma zebra!'},
      {'nome': 'Alce', 'emoji': '🦌', 'cor': Color(0xFFDC2626), 'peso': 600.0, 'descricao': 'Você dominou o peso de um alce!'},
      {'nome': 'Javali', 'emoji': '🐗', 'cor': Color(0xFF059669), 'peso': 110.0, 'descricao': 'Feroz como um javali!'},
      {'nome': 'Panda', 'emoji': '🐼', 'cor': Color(0xFF1D4ED8), 'peso': 120.0, 'descricao': 'Fofo e forte como um panda!'},
      {'nome': 'Crocodilo', 'emoji': '🐊', 'cor': Color(0xFF6EE7B7), 'peso': 500.0, 'descricao': 'Você domou um crocodilo!'},
      {'nome': 'Cervo', 'emoji': '🦌', 'cor': Color(0xFFA855F7), 'peso': 150.0, 'descricao': 'Você carregou um cervo!'},
      {'nome': 'Orangotango', 'emoji': '🦧', 'cor': Color(0xFF9333EA), 'peso': 100.0, 'descricao': 'Você aguentou o peso de um orangotango!'},
      {'nome': 'Tamanduá', 'emoji': '🦡', 'cor': Color(0xFF6366F1), 'peso': 65.0, 'descricao': 'Força silenciosa de um tamanduá!'},
      {'nome': 'Avestruz', 'emoji': '🦤', 'cor': Color(0xFFF97316), 'peso': 160.0, 'descricao': 'Correu com o peso de um avestruz!'},
      {'nome': 'Lhama', 'emoji': '🦙', 'cor': Color(0xFF3B82F6), 'peso': 130.0, 'descricao': 'Você subiu os Andes com uma lhama!'},
      {'nome': 'Foca', 'emoji': '🦭', 'cor': Color(0xFF9333EA), 'peso': 150.0, 'descricao': 'Você levou o peso de uma foca brincando!'},
      {'nome': 'Urso Polar', 'emoji': '🐻‍❄️', 'cor': Color(0xFF9CA3AF), 'peso': 450.0, 'descricao': 'Você foi gelado e forte como um urso polar!'},
      {'nome': 'Gnu', 'emoji': '🐃', 'cor': Color(0xFF6D28D9), 'peso': 250.0, 'descricao': 'Você enfrentou um gnu!'},
      {'nome': 'Antílope', 'emoji': '🦌', 'cor': Color(0xFFF59E0B), 'peso': 150.0, 'descricao': 'Você correu com o peso de um antílope!'},
      {'nome': 'Urso Negro', 'emoji': '🐻', 'cor': Color(0xFF4B5563), 'peso': 270.0, 'descricao': 'Você enfrentou um urso negro!'},
      {'nome': 'Dromedário', 'emoji': '🐫', 'cor': Color(0xFFF87171), 'peso': 400.0, 'descricao': 'Travessia do deserto com um dromedário!'},
      {'nome': 'Lobo', 'emoji': '🐺', 'cor': Color(0xFF2563EB), 'peso': 60.0, 'descricao': 'Você correu como um lobo!'},
      {'nome': 'Hipopótamo', 'emoji': '🦛', 'cor': Color(0xFFF59E0B), 'peso': 1600.0, 'descricao': 'Você conquistou um hipopótamo!'},
      {'nome': 'Baleia Jubarte', 'emoji': '🐋', 'cor': Color(0xFF3B82F6), 'peso': 40000.0, 'descricao': 'Colossal! O peso de uma baleia jubarte!'},
      {'nome': 'Gorila', 'emoji': '🦍', 'cor': Color(0xFF1F2937), 'peso': 200.0, 'descricao': 'Rei da selva! Peso de um gorila!'},
      {'nome': 'Chimpanzé', 'emoji': '🐒', 'cor': Color(0xFF8B5CF6), 'peso': 70.0, 'descricao': 'Inteligente e forte! Chimpanzé!'},
      {'nome': 'Elefante', 'emoji': '🐘', 'cor': Color(0xFF059669), 'peso': 5000.0, 'descricao': 'Gigante! Peso de um elefante!'},
      {'nome': 'Rinoceronte', 'emoji': '🦏', 'cor': Color(0xFF6B7280), 'peso': 2500.0, 'descricao': 'Rinoceronte! Poderoso!'},
      {'nome': 'Girafa', 'emoji': '🦒', 'cor': Color(0xFFDC2626), 'peso': 1200.0, 'descricao': 'Girafa! Altura e força!'},
      {'nome': 'Búfalo', 'emoji': '🐃', 'cor': Color(0xFF1E293B), 'peso': 900.0, 'descricao': 'Búfalo! Selvagem!'},
      {'nome': 'Zebra', 'emoji': '🦓', 'cor': Color(0xFF0F766E), 'peso': 400.0, 'descricao': 'Zebra! Rara e forte!'},
      {'nome': 'Alce', 'emoji': '🦌', 'cor': Color(0xFF115E59), 'peso': 700.0, 'descricao': 'Alce! Majestoso!'},
      {'nome': 'Javali', 'emoji': '🐗', 'cor': Color(0xFF134E4A), 'peso': 150.0, 'descricao': 'Javali! Feroz!'},
      {'nome': 'Leão', 'emoji': '🦁', 'cor': Color(0xFF1A4339), 'peso': 250.0, 'descricao': 'Leão! Rei da selva!'},
      {'nome': 'Tigre', 'emoji': '🐅', 'cor': Color(0xFF1E3F35), 'peso': 300.0, 'descricao': 'Tigre! O maior felino!'},
      {'nome': 'Cavalo', 'emoji': '🐎', 'cor': Color(0xFF223B31), 'peso': 450.0, 'descricao': 'Cavalo! Nobre e forte!'},
      {'nome': 'Vaca', 'emoji': '🐄', 'cor': Color(0xFF26372D), 'peso': 750.0, 'descricao': 'Vaca! Grande e forte!'},
      {'nome': 'Touro', 'emoji': '🐂', 'cor': Color(0xFF2A3329), 'peso': 800.0, 'descricao': 'Touro! Bravo e forte!'},
      {'nome': 'Camelo', 'emoji': '🐫', 'cor': Color(0xFF2E2F25), 'peso': 800.0, 'descricao': 'Camelo! Duas corcovas!'}
    ];

    // Criar lista de animais candidatos baseado no peso total
    List<Map<String, dynamic>> candidatos = [];
    
    // Encontrar animais que fazem sentido para o peso total
    for (final animal in premiosAnimais) {
      double pesoAnimal = (animal['peso'] as num).toDouble();
      
      // Se o peso total é menor que o animal, considerar apenas se for próximo (até 3x maior)
      if (pesoTotal < pesoAnimal) {
        if (pesoAnimal <= pesoTotal * 3) {
          candidatos.add(animal);
        }
      } else {
        // Se o peso total é maior que o animal, adicionar como candidato
        candidatos.add(animal);
      }
    }
    
    // Se não há candidatos, usar o animal mais próximo
    if (candidatos.isEmpty) {
      candidatos = premiosAnimais;
    }
    
    // Escolher aleatoriamente um animal dos candidatos
    final random = Random();
    Map<String, dynamic> animalEscolhido = candidatos[random.nextInt(candidatos.length)];
    
    // Calcular quantidade aleatória baseada no peso total
    double pesoAnimal = (animalEscolhido['peso'] as num).toDouble();
    int quantidadeBase = (pesoTotal / pesoAnimal).ceil();
    
    // Adicionar variação aleatória na quantidade (±30%)
    int variacao = (quantidadeBase * 0.3).round();
    int quantidadeMin = (quantidadeBase - variacao).clamp(1, quantidadeBase);
    int quantidadeMax = (quantidadeBase + variacao).clamp(quantidadeBase, quantidadeBase * 2);
    int quantidade = random.nextInt(quantidadeMax - quantidadeMin + 1) + quantidadeMin;
    
    // Se for apenas 1 animal, usar o nome normal
    if (quantidade == 1) {
      return {
        'nome': animalEscolhido['nome'],
        'emoji': animalEscolhido['emoji'],
        'cor': animalEscolhido['cor'],
        'peso': animalEscolhido['peso'],
        'descricao': animalEscolhido['descricao'],
      };
    }

    // Para múltiplos animais, sempre mostrar o número exato com plural correto
    String nomeVariado = '$quantidade ${_getPluralCorreto(animalEscolhido['nome'], quantidade)}';
    String descricaoVariada = 'Você carregou o peso de $quantidade ${_getPluralCorreto(animalEscolhido['nome'], quantidade)}!';

    // Sempre retornar apenas 1 emoji, independente da quantidade
    return {
      'nome': nomeVariado,
      'emoji': animalEscolhido['emoji'],
      'cor': animalEscolhido['cor'],
      'peso': animalEscolhido['peso'],
      'descricao': descricaoVariada,
    };
  }

  // Função para mostrar o modal de prêmio
  void _mostrarModalPremio(double pesoTotal, Map<String, dynamic> premio) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone de troféu
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: premio['cor'].withOpacity(0.1),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Center(
                    child: Text(
                      '🏆',
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Título especial para premios de resistência
                Text(
                  premio['peso'] == 0.0 
                    ? 'Parabéns! Você ganhou um prêmio de resistência e força!'
                    : 'Parabéns!',
                  style: TextStyle(
                    fontSize: premio['peso'] == 0.0 ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                // Emoji do animal
                Text(
                  premio['emoji'],
                  style: TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 16),
                
                // Nome do prêmio
                Text(
                  premio['nome'],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: premio['cor'],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Descrição
                Text(
                  premio['peso'] == 0.0 
                    ? premio['descricao'].replaceAll('Treino concluído com sucesso! ', '')
                    : premio['descricao'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF6B7280),
                    fontStyle: premio['peso'] == 0.0 ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Peso total carregado (só mostrar se houver peso)
                if (pesoTotal > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fitness_center,
                            color: const Color(0xFF3B82F6),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Peso total:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Ícone para explicar o cálculo
                          GestureDetector(
                            onTap: () => _mostrarExplicacaoCalculo(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.help_outline,
                                color: const Color(0xFF3B82F6),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pesoTotal.toStringAsFixed(0)} kg',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botão para coletar prêmio
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Salvar o prêmio
                      await _salvarPremio(pesoTotal, premio);
                      
                      Navigator.of(context).pop();
                      // Navegar de volta para a home
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => HomePageWithIndex(initialIndex: 0)),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: premio['cor'],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Coletar Prêmio!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
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

  // Função para mostrar explicação do cálculo
  void _mostrarExplicacaoCalculo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone de informação
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.science,
                      size: 30,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Título
                Text(
                  'Como é calculado?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Fórmula
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Volume de Treino =',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Peso × Repetições × Séries',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Explicação
                Text(
                  'Este cálculo tem base científica e é usado em fisiologia do exercício para medir o volume total de carga levantada.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Exemplo prático
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Exemplo:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '50 kg × 10 reps × 4 séries = 2.000 kg',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Importância
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Importância:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mais volume = maior potencial para hipertrofia muscular',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Botão para fechar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Entendi!',
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
        );
      },
    );
  }

  // Função para mostrar modal perguntando tempo e KM
  Future<void> _mostrarModalTempoKm(double pesoTotal, Map<String, dynamic> premio) async {
    // Converter o tempo do cronômetro para minutos
    int tempoMinutos = tempoTotalTreino ~/ 60;
    double kmPercorridos = 0.0;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone de cronômetro
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.timer,
                          size: 40,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Título
                    Text(
                      'Finalizar Treino',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de tempo
                    TextField(
                      controller: TextEditingController(text: tempoMinutos.toString()),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Tempo do treino (minutos)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.timer),
                      ),
                      onChanged: (value) {
                        tempoMinutos = int.tryParse(value) ?? 0;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Instrução sobre KM
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Se você fez corrida, caminhada ou bike, insira a distância para salvar no seu histórico de treinos!',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de KM
                    TextField(
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'KM percorridos',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.directions_run),
                      ),
                      onChanged: (value) {
                        kmPercorridos = double.tryParse(value) ?? 0.0;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Botão para continuar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          
                          // Salvar o treino com os dados informados
                          await _salvarTreinoCompleto(tempoMinutos * 60, kmPercorridos);
                          
                          // Mostrar modal de prêmio
                          if (mounted) {
                            _mostrarModalPremio(pesoTotal, premio);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Finalizar e Ver Prêmio',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _concluirTreino() async {
    try {
      // Calcular peso total carregado
      double pesoTotal = _calcularPesoTotal();
      
      // Determinar prêmio baseado no peso
      Map<String, dynamic> premio = _determinarPremio(pesoTotal);
      
      // Primeiro mostrar modal para perguntar tempo e KM
      if (mounted) {
        await _mostrarModalTempoKm(pesoTotal, premio);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao concluir treino: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _salvarTreinoCompleto(int tempoSegundos, double kmPercorridos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      print('Salvando treino: usuarioId=$usuarioId, nome=${widget.nomeTreino}, tempo=$tempoSegundos, km=$kmPercorridos');
      
      if (usuarioId != null) {
        final url = Uri.parse('https://airfit.online/api/historico_treinos.php');
        final body = {
          'usuario_id': usuarioId.toString(),
          'nome_treino': widget.nomeTreino,
          'tempo_total': tempoSegundos.toString(),
          'km_percorridos': kmPercorridos.toString(),
          'data_treino': DateTime.now().toIso8601String(),
        };
        
        print('URL: $url');
        print('Body: $body');
        
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        );
        
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
        
        if (response.statusCode == 200) {
          try {
            final responseData = jsonDecode(response.body);
            if (responseData['sucesso'] == true) {
              // Limpar cronômetro persistente e estado dos exercícios após salvar com sucesso
              await _limparCronometroPersistente();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Treino salvo com sucesso!'),
                  backgroundColor: const Color(0xFF3B82F6),
                ),
              );
            } else {
              throw Exception(responseData['erro'] ?? 'Erro desconhecido');
            }
          } catch (jsonError) {
            print('Erro ao decodificar JSON: $jsonError');
            throw Exception('Resposta inválida do servidor');
          }
        } else {
          throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
        }
      } else {
        throw Exception('Usuário não logado');
      }
    } catch (e) {
      print('Erro ao salvar treino: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar treino: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final min = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return '$hours : $min : $sec';
  }

  int _parseTempoEditado(String tempoString) {
    try {
      // Remove espaços e caracteres especiais, mantendo apenas números e ':'
      final cleanString = tempoString.replaceAll(RegExp(r'[^\d:]'), '');
      
      // Divide por ':'
      final parts = cleanString.split(':');
      
      if (parts.length == 3) {
        final hours = int.tryParse(parts[0]) ?? 0;
        final minutes = int.tryParse(parts[1]) ?? 0;
        final seconds = int.tryParse(parts[2]) ?? 0;
        
        return hours * 3600 + minutes * 60 + seconds;
      } else if (parts.length == 2) {
        // Se só tem 2 partes, assume que são minutos:segundos
        final minutes = int.tryParse(parts[0]) ?? 0;
        final seconds = int.tryParse(parts[1]) ?? 0;
        
        return minutes * 60 + seconds;
      } else if (parts.length == 1 && parts[0].isNotEmpty) {
        // Se só tem 1 parte, assume que são segundos
        return int.tryParse(parts[0]) ?? 0;
      }
    } catch (e) {
      print('Erro ao parsear tempo: $e');
    }
    
    // Se não conseguir parsear, retorna 0
    return 0;
  }

  Future<int> _obterTempoTotalTreino() async {
    final prefs = await SharedPreferences.getInstance();
    final tempoInicioSalvo = prefs.getInt('treino_inicio_timestamp');
    final nomeTreinoSalvo = prefs.getString('treino_nome_ativo');
    
    if (tempoInicioSalvo != null && nomeTreinoSalvo == widget.nomeTreino) {
      final agora = DateTime.now().millisecondsSinceEpoch;
      final tempoDecorrido = agora - tempoInicioSalvo;
      return tempoDecorrido ~/ 1000; // Converter para segundos
    } else {
      return stopwatch.elapsed.inSeconds;
    }
  }

  @override
  Widget build(BuildContext context) {
    final exs = widget.exercicios;
    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: Colors.transparent,
      drawer: CustomDrawer(
        onMenuTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
      ),
      appBar: AppBarLogo(
        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFF8FAFC), const Color(0xFFE0E7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 100), // Padding inferior para o menu
          itemCount: exs.length + 1, // +1 para incluir o botão como um item da lista
          itemBuilder: (context, idx) {
            // Se for o último item, mostrar o botão Concluir Treino
            if (idx == exs.length) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _mostrarDialogConcluirTreino(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Verde
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'CONCLUIR TREINO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Exercícios normais
            if (idx == 0) {
              // Exercício ativo - Design futurista completamente novo
              final ex = exs[0];
              final nome = (ex['nome_do_exercicio'] ?? '').toString().toUpperCase();
              final img = ex['foto_gif'] ?? '';
              final reps = ex['numero_repeticoes']?.toString() ?? '-';
              final peso = ex['peso']?.toString() ?? '-';
              final totalSeries = int.tryParse(ex['numero_series']?.toString() ?? '1') ?? 1;
              
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          constraints: const BoxConstraints(maxWidth: 400),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xFF3B82F6).withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Stack(
                              children: [
                                // Conteúdo principal
                                Padding(
                                  padding: const EdgeInsets.all(28),
                                  child: Column(
                                    children: [
                                      // Header com timer
                                      _buildHolographicHeader(false),
                                      const SizedBox(height: 24),
                                      
                                      // Layout com GIF como fundo suave
                                      _buildGifBackgroundLayout(img, nome, reps, peso, totalSeries, false),
                                      const SizedBox(height: 24),
                                      
                                      // Barra de progresso
                                      _buildFuturisticProgressBar(totalSeries, false),
                                      const SizedBox(height: 28),
                                      
                                      // Painel de controle
                                      _buildFuturisticControlPanel(false, ex),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            } else {
              // Exercícios não ativos - Card menor e minimalista
              final ex = exs[idx];
              final nome = (ex['nome_do_exercicio'] ?? '').toString();
              final img = ex['foto_gif'] ?? '';
              final isConcluido = ex['concluido'] == true;
              
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isConcluido 
                        ? const Color(0xFFF0F0F0) // Cinza claro para concluído
                        : const Color(0xFFF5F5F5), // Cinza para pendente
                    borderRadius: BorderRadius.circular(12),
                    border: isConcluido 
                        ? Border.all(color: const Color(0xFFCCCCCC), width: 0.5)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // GIF pausado à esquerda
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8E8E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            OptimizedGifWidget(
                              imageUrl: img,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            // Overlay indicando estado do exercício apenas para concluídos
                            if (isConcluido)
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCCCCCC).withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Nome do exercício no centro
                      Expanded(
                        child: Text(
                          nome,
                          style: GoogleFonts.poppins(
                            color: isConcluido 
                                ? const Color(0xFF888888)
                                : const Color(0xFF2A2A2A),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                            decoration: isConcluido 
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Botão de play à direita ou ícone de concluído
                      isConcluido
                          ? Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  // Botão de check não tem ação, mas mantém o efeito visual
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCCCCC),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            )
                          : Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _trocarParaExercicioComFade(idx);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E0E0),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.play_arrow,
                                    color: const Color(0xFF666666),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, 'Home', 0, _selectedIndex),
                _buildNavItem(Icons.event_note_outlined, 'Histórico', 1, _selectedIndex),
                _buildNavItem(Icons.sports_gymnastics, 'Treinar', 2, _selectedIndex),
                _buildNavItem(Icons.psychology_alt_outlined, 'Assistente', 3, _selectedIndex),
                _buildNavItem(Icons.person_outline, 'Perfil', 4, _selectedIndex),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Novos widgets para o design futurista
  Widget _buildHolographicHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2D3748), // Cinza escuro
            const Color(0xFF4A5568), // Cinza médio
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF48BB78), // Verde para indicar ativo
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF48BB78).withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'TREINO ATIVO',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF718096), // Cinza claro
                  const Color(0xFFA0AEC0), // Cinza mais claro
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              formatTime(tempoTotalTreino),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

     Widget _buildGifBackgroundLayout(String img, String nome, String reps, String peso, int totalSeries, bool isDark) {
     return Container(
       height: 200,
       child: Container(
         width: double.infinity,
           height: 180,
         decoration: BoxDecoration(
             color: Colors.white, // Fundo branco
           borderRadius: BorderRadius.circular(20),
           // Removendo boxShadow (bordas/sombras)
         ),
         child: Stack(
           clipBehavior: Clip.none,
           children: [
             // GIF integrado no lado direito do mesmo card - altura aumentada em 30%
             Positioned(
               right: -20, // Movido de -40 para -20 (20px mais para a esquerda)
               top: 0,
               child: Container(
                 width: 200,
                 height: 180,
                 child: OptimizedGifWidget(
                   imageUrl: img,
                   width: 200,
                   height: 180,
                   fit: BoxFit.cover,
                   borderRadius: BorderRadius.circular(20),
                 ),
               ),
             ),
             
                          // Conteúdo principal (textos) posicionado mais à esquerda
             Positioned(
               left: 16,
               top: 16,
               bottom: 16,
               right: 120, // Aumentado para dar mais espaço ao GIF e evitar overflow
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Categoria pequena e clean
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                     decoration: BoxDecoration(
                       color: _getCategoriaColor(widget.exercicios[exercicioAtual]['categoria']?.toString() ?? ''),
                       borderRadius: BorderRadius.circular(12),
                     ),
                     child: Text(
                       _getCategoriaShortName(widget.exercicios[exercicioAtual]['categoria']?.toString() ?? ''),
                       style: GoogleFonts.poppins(
                         color: Colors.white,
                         fontWeight: FontWeight.w600,
                         fontSize: 10,
                         letterSpacing: 0.5,
                       ),
                     ),
                   ),
                   const SizedBox(height: 4),
                   
                   // Título melhorado - posicionado mais à esquerda
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     child: Text(
                       nome,
                       style: GoogleFonts.poppins(
                         color: Colors.black,
                         fontWeight: FontWeight.w700,
                         fontSize: 14,
                         letterSpacing: 0.3,
                         height: 1.2,
                         shadows: [
                           Shadow(
                             color: Colors.white.withOpacity(0.3),
                             blurRadius: 1,
                             offset: const Offset(0.5, 0.5),
                           ),
                         ],
                       ),
                       maxLines: 3,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   
                   const Spacer(),
                   
                   // Estatísticas melhoradas e destacadas
                   _buildEnhancedStats(reps, peso, totalSeries),
                 ],
               ),
             ),
           ],
         ),
       ),
     );
   }



   Widget _buildHorizontalGifLayout(String img, String nome, String reps, String peso, int totalSeries, bool isDark) {
     return Container(
       height: 180,
       child: Stack(
         children: [
           // GIF como fundo
           Container(
             decoration: BoxDecoration(
               color: const Color(0xFFE8E8E8), // Cinza claro como na imagem
               borderRadius: BorderRadius.circular(24),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.08),
                   blurRadius: 16,
                   offset: const Offset(0, 4),
                 ),
               ],
             ),
             child: ClipRRect(
               borderRadius: BorderRadius.circular(24),
               child: OptimizedGifWidget(
                 imageUrl: img,
                 width: double.infinity,
                 height: double.infinity,
                 fit: BoxFit.cover,
                 borderRadius: BorderRadius.circular(24),
               ),
             ),
           ),
           
           // Overlay suave para legibilidade
           Container(
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 colors: [
                   Colors.black.withValues(alpha: 0.4),
                   Colors.black.withValues(alpha: 0.1),
                   Colors.black.withValues(alpha: 0.5),
                 ],
                 begin: Alignment.topLeft,
                 end: Alignment.bottomRight,
               ),
               borderRadius: BorderRadius.circular(24),
             ),
           ),
           
           // Textos sobrepostos
           Positioned.fill(
             child: Padding(
               padding: const EdgeInsets.all(20),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   // Título no topo
                   Flexible(
                     child: Text(
                       nome,
                       style: GoogleFonts.poppins(
                         color: Colors.white,
                         fontWeight: FontWeight.w600,
                         fontSize: 18,
                         letterSpacing: 0.3,
                         shadows: [
                           Shadow(
                             color: Colors.black.withValues(alpha: 0.6),
                             blurRadius: 3,
                             offset: const Offset(0, 1),
                           ),
                         ],
                       ),
                       softWrap: true,
                       overflow: TextOverflow.visible,
                     ),
                   ),
                   
                   // Estatísticas na parte inferior
                   _buildCleanStats(reps, peso, totalSeries, isDark),
                 ],
               ),
             ),
           ),
         ],
       ),
     );
   }

   Widget _buildCleanStats(String reps, String peso, int totalSeries, bool isDark) {
     return Row(
       children: [
         // Estatística principal (Séries) - Verde limão
         Expanded(
           child: Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: const Color(0xFF3B82F6), // Azul como na imagem
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                   blurRadius: 8,
                   offset: const Offset(0, 2),
                 ),
               ],
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(
                   'Séries',
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 11,
                     fontWeight: FontWeight.w500,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
                 const SizedBox(height: 2),
                 Text(
                   '$serieAtual / $totalSeries',
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 16,
                     fontWeight: FontWeight.w700,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ],
             ),
           ),
         ),
         
         const SizedBox(width: 8),
         
         // Estatística secundária (Repetições) - Preto
         Expanded(
           child: Container(
             padding: const EdgeInsets.all(12),
             decoration: BoxDecoration(
               color: const Color(0xFF2A2A2A), // Preto como na imagem
               borderRadius: BorderRadius.circular(16),
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                   blurRadius: 8,
                   offset: const Offset(0, 2),
                 ),
               ],
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(
                   'Repetições',
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 11,
                     fontWeight: FontWeight.w500,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
                 const SizedBox(height: 2),
                 Text(
                   reps,
                   style: GoogleFonts.poppins(
                     color: Colors.white,
                     fontSize: 16,
                     fontWeight: FontWeight.w700,
                   ),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ],
             ),
           ),
         ),
       ],
     );
   }

   Widget _buildOverlayStats(String reps, String peso, int totalSeries, bool isDark) {
     return Column(
       mainAxisSize: MainAxisSize.min,
       children: [
         _buildOverlayStatRow(
           Icons.repeat,
           'Séries',
           '$serieAtual / $totalSeries',
           Colors.cyanAccent,
           isDark,
         ),
         const SizedBox(height: 6),
         _buildOverlayStatRow(
           Icons.cached,
           'Repetições',
           reps,
           Colors.blueAccent,
           isDark,
         ),
         const SizedBox(height: 6),
         _buildOverlayStatRow(
           Icons.fitness_center,
           'Peso',
           '$peso kg',
           Colors.purpleAccent,
           isDark,
         ),
       ],
     );
   }

   Widget _buildOverlayStatRow(IconData icon, String label, String value, Color color, bool isDark) {
     return Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Container(
           padding: const EdgeInsets.all(4),
           decoration: BoxDecoration(
             color: color.withOpacity(0.3),
             borderRadius: BorderRadius.circular(6),
             border: Border.all(
               color: color.withOpacity(0.6),
               width: 1,
             ),
           ),
           child: Icon(icon, size: 14, color: Colors.white),
         ),
         const SizedBox(width: 8),
         Flexible(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(
                 label,
                 style: GoogleFonts.poppins(
                   color: Colors.white.withOpacity(0.9),
                   fontSize: 9,
                   fontWeight: FontWeight.w500,
                   letterSpacing: 0.3,
                   shadows: [
                     Shadow(
                       color: Colors.black.withOpacity(0.8),
                       blurRadius: 2,
                       offset: const Offset(1, 1),
                     ),
                   ],
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
               Text(
                 value,
                 style: GoogleFonts.poppins(
                   color: Colors.white,
                   fontSize: 12,
                   fontWeight: FontWeight.w600,
                   shadows: [
                     Shadow(
                       color: Colors.black.withOpacity(0.8),
                       blurRadius: 2,
                       offset: const Offset(1, 1),
                     ),
                   ],
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
             ],
           ),
         ),
       ],
     );
   }

   Widget _buildCompactStats(String reps, String peso, int totalSeries, bool isDark) {
     return Column(
       children: [
         _buildCompactStatRow(
           Icons.repeat,
           'Séries',
           '$serieAtual / $totalSeries',
           Colors.blueAccent,
           isDark,
         ),
         const SizedBox(height: 8),
         _buildCompactStatRow(
           Icons.cached,
           'Repetições',
           reps,
           Colors.cyanAccent,
           isDark,
         ),
         const SizedBox(height: 8),
         _buildCompactStatRow(
           Icons.fitness_center,
           'Peso',
           '$peso kg',
           Colors.purpleAccent,
           isDark,
         ),
       ],
     );
   }

   Widget _buildCompactStatRow(IconData icon, String label, String value, Color color, bool isDark) {
     return Row(
       children: [
         Container(
           padding: const EdgeInsets.all(6),
           decoration: BoxDecoration(
             color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
             borderRadius: BorderRadius.circular(8),
             border: isDark ? Border.all(
               color: color.withOpacity(0.5),
               width: 1,
             ) : null,
           ),
           child: Icon(icon, size: 16, color: color),
         ),
         const SizedBox(width: 12),
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 label,
                 style: GoogleFonts.orbitron(
                   color: isDark ? color.withOpacity(0.8) : const Color(0xFF64748B),
                   fontSize: 10,
                   fontWeight: FontWeight.bold,
                   letterSpacing: 0.5,
                 ),
               ),
               Text(
                 value,
                 style: GoogleFonts.orbitron(
                   color: isDark ? Colors.white : const Color(0xFF1F2937),
                   fontSize: 14,
                   fontWeight: FontWeight.bold,
                 ),
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
             ],
           ),
         ),
       ],
     );
   }

   Widget _buildFuturisticImageFrame(String img, bool isDark) {
     return Container(
       decoration: BoxDecoration(
         borderRadius: BorderRadius.circular(20),
         gradient: isDark ? LinearGradient(
           colors: [
             Colors.cyanAccent.withOpacity(0.3),
             Colors.blueAccent.withOpacity(0.3),
             Colors.purpleAccent.withOpacity(0.3),
           ],
           begin: Alignment.topLeft,
           end: Alignment.bottomRight,
         ) : null,
         boxShadow: isDark ? [
           BoxShadow(
             color: Colors.cyanAccent.withOpacity(0.3),
             blurRadius: 20,
             spreadRadius: 2,
           ),
         ] : [
           BoxShadow(
             color: Colors.black.withOpacity(0.1),
             blurRadius: 15,
             offset: const Offset(0, 8),
           ),
         ],
       ),
       padding: const EdgeInsets.all(3),
       child: ClipRRect(
         borderRadius: BorderRadius.circular(17),
         child: Container(
           width: 140,
           height: 140,
           decoration: BoxDecoration(
             color: isDark ? const Color(0xFF0F172A) : Colors.white,
             borderRadius: BorderRadius.circular(17),
           ),
           child: OptimizedGifWidget(
             imageUrl: img,
             width: double.infinity,
             height: double.infinity,
             fit: BoxFit.cover,
             borderRadius: BorderRadius.circular(17),
           ),
         ),
       ),
     );
   }

  Widget _buildNeonTitle(String nome, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: isDark ? BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.cyanAccent.withOpacity(0.1),
            Colors.blueAccent.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.3),
          width: 1,
        ),
      ) : null,
      child: Text(
        nome,
        textAlign: TextAlign.center,
        style: isDark ? GoogleFonts.orbitron(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Colors.cyanAccent.withOpacity(0.5),
              blurRadius: 10,
            ),
          ],
        ) : const TextStyle(
          color: Color(0xFF2563EB),
          fontWeight: FontWeight.bold,
          fontSize: 20,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildHolographicStatsPanel(String reps, String peso, int totalSeries, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark ? LinearGradient(
          colors: [
            Colors.blueAccent.withOpacity(0.1),
            Colors.cyanAccent.withOpacity(0.1),
          ],
        ) : null,
        color: isDark ? null : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(
          color: Colors.blueAccent.withOpacity(0.3),
          width: 1,
        ) : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildHolographicStatItem(
            Icons.repeat,
            'SÉRIES',
            '$serieAtual / $totalSeries',
            Colors.blueAccent,
            isDark,
          ),
          _buildVerticalDivider(isDark),
          _buildHolographicStatItem(
            Icons.cached,
            'REPS',
            reps,
            Colors.cyanAccent,
            isDark,
          ),
          _buildVerticalDivider(isDark),
          _buildHolographicStatItem(
            Icons.fitness_center,
            'PESO',
            '$peso kg',
            Colors.purpleAccent,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHolographicStatItem(IconData icon, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: isDark ? Border.all(
                color: color.withOpacity(0.5),
                width: 1,
              ) : null,
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.orbitron(
              color: isDark ? color : const Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.orbitron(
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider(bool isDark) {
    return Container(
      width: 1,
      height: 40,
      decoration: BoxDecoration(
        gradient: isDark ? LinearGradient(
          colors: [
            Colors.transparent,
            Colors.cyanAccent.withOpacity(0.5),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ) : null,
        color: isDark ? null : const Color(0xFFE5E7EB),
      ),
    );
  }

     Widget _buildFuturisticProgressBar(int totalSeries, bool isDark) {
     return Column(
       children: [
         AnimatedBuilder(
           animation: _progressAnimation,
           builder: (context, child) {
             return Row(
               children: List.generate(totalSeries, (i) {
                 final isCompleted = i < serieAtual;
                 return Expanded(
                   child: Container(
                     margin: EdgeInsets.only(right: i == totalSeries - 1 ? 0 : 6),
                     height: 6,
                     decoration: BoxDecoration(
                       color: isCompleted 
                           ? const Color(0xFF3B82F6)
                           : const Color(0xFFE8E8E8),
                       borderRadius: BorderRadius.circular(3),
                     ),
                   ),
                 );
               }),
             );
           },
         ),
       ],
     );
   }

   Widget _buildEnhancedStats(String reps, String peso, int totalSeries) {
     // Obter a categoria do exercício atual
     final categoria = widget.exercicios[exercicioAtual]['categoria']?.toString() ?? '';
     final exercicio = widget.exercicios[exercicioAtual];
     
     return Container(
       padding: const EdgeInsets.all(8),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         mainAxisSize: MainAxisSize.min,
         children: [
           // Primeira linha - sempre presente
           _buildStatRow(
             icon: Icons.repeat,
             iconColor: Colors.white,
             backgroundColor: const Color(0xFF3B82F6),
             label: 'Séries',
             value: '$serieAtual / ${exercicio['numero_series'] ?? totalSeries}',
           ),
           
           const SizedBox(height: 6),
           
           // Segunda linha - específica por categoria
           _buildCategoriaSpecificStats(categoria, exercicio),
         ],
       ),
     );
   }

   Widget _buildStatRow({
     required IconData icon,
     required Color iconColor,
     required Color backgroundColor,
     required String label,
     required String value,
   }) {
     return Row(
       mainAxisSize: MainAxisSize.min,
       children: [
         Container(
           padding: const EdgeInsets.all(4),
           decoration: BoxDecoration(
             color: backgroundColor,
             borderRadius: BorderRadius.circular(4),
           ),
           child: Icon(
             icon,
             size: 12,
             color: iconColor,
           ),
         ),
         const SizedBox(width: 6),
         Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           mainAxisSize: MainAxisSize.min,
           children: [
             Text(
               label,
               style: GoogleFonts.poppins(
                 color: Colors.black,
                 fontSize: 9,
                 fontWeight: FontWeight.w500,
                 shadows: [
                   Shadow(
                     color: Colors.white.withOpacity(0.3),
                     blurRadius: 1,
                     offset: const Offset(0.5, 0.5),
                   ),
                 ],
               ),
             ),
             Text(
               value,
               style: GoogleFonts.poppins(
                 color: Colors.black,
                 fontSize: 12,
                 fontWeight: FontWeight.w700,
                 shadows: [
                   Shadow(
                     color: Colors.white.withOpacity(0.3),
                     blurRadius: 1,
                     offset: const Offset(0.5, 0.5),
                   ),
                 ],
               ),
             ),
           ],
         ),
       ],
     );
   }

   Widget _buildCategoriaSpecificStats(String categoria, Map<String, dynamic> exercicio) {
     switch (categoria) {
       case 'Com Pesos (Musculação)':
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 _buildStatRow(
                   icon: Icons.fitness_center,
                   iconColor: Colors.white,
                   backgroundColor: const Color(0xFF2A2A2A),
                   label: 'Repetições',
                   value: '${exercicio['numero_repeticoes'] ?? 0}',
                 ),
                 const SizedBox(width: 8),
                 _buildStatRow(
                   icon: Icons.monitor_weight,
                   iconColor: const Color(0xFF666666),
                   backgroundColor: const Color(0xFFE8E8E8),
                   label: 'Peso',
                   value: '${exercicio['peso'] ?? 0}kg',
                 ),
               ],
             ),
           ],
         );
         
       case 'Peso Corporal (Calistenia)':
         return Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             _buildStatRow(
               icon: Icons.fitness_center,
               iconColor: Colors.white,
               backgroundColor: const Color(0xFF2A2A2A),
               label: 'Repetições',
               value: '${exercicio['numero_repeticoes'] ?? 0}',
             ),
           ],
         );
         
       case 'Cardio / Corrida':
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 _buildStatRow(
                   icon: Icons.place,
                   iconColor: Colors.white,
                   backgroundColor: const Color(0xFF2A2A2A),
                   label: 'Distância',
                   value: '${exercicio['distancia'] ?? 0}km',
                 ),
                 const SizedBox(width: 8),
                 _buildStatRow(
                   icon: Icons.timer,
                   iconColor: const Color(0xFF666666),
                   backgroundColor: const Color(0xFFE8E8E8),
                   label: 'Tempo',
                   value: '${exercicio['tempo_descanso'] ?? 0}min',
                 ),
               ],
             ),
           ],
         );
         
       case 'Funcional':
         return Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             _buildStatRow(
               icon: Icons.timer,
               iconColor: Colors.white,
               backgroundColor: const Color(0xFF2A2A2A),
               label: 'Tempo',
               value: '${exercicio['tempo_descanso'] ?? 0}s',
             ),
           ],
         );
         
       case 'Alongamento / Mobilidade':
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 _buildStatRow(
                   icon: Icons.timer,
                   iconColor: Colors.white,
                   backgroundColor: const Color(0xFF2A2A2A),
                   label: 'Tempo',
                   value: '${exercicio['tempo_descanso'] ?? 0}s',
                 ),
                 const SizedBox(width: 8),
                 _buildStatRow(
                   icon: Icons.repeat,
                   iconColor: const Color(0xFF666666),
                   backgroundColor: const Color(0xFFE8E8E8),
                   label: 'Repetições',
                   value: '${exercicio['numero_repeticoes'] ?? 0}',
                 ),
               ],
             ),
           ],
         );
         
       case 'HIIT / Alta Intensidade':
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 _buildStatRow(
                   icon: Icons.whatshot,
                   iconColor: Colors.white,
                   backgroundColor: const Color(0xFF2A2A2A),
                   label: 'Esforço',
                   value: '${exercicio['numero_repeticoes'] ?? 0}s',
                 ),
                 const SizedBox(width: 8),
                 _buildStatRow(
                   icon: Icons.repeat,
                   iconColor: const Color(0xFF666666),
                   backgroundColor: const Color(0xFFE8E8E8),
                   label: 'Ciclos',
                   value: '${exercicio['numero_series'] ?? 0}',
                 ),
               ],
             ),
           ],
         );
         
       case 'Isometria':
         return Row(
           mainAxisSize: MainAxisSize.min,
           children: [
             _buildStatRow(
               icon: Icons.timer,
               iconColor: Colors.white,
               backgroundColor: const Color(0xFF2A2A2A),
               label: 'Tempo',
               value: '${exercicio['numero_repeticoes'] ?? 0}s',
             ),
           ],
         );
         
       default:
         // Interface genérica
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 _buildStatRow(
                   icon: Icons.fitness_center,
                   iconColor: Colors.white,
                   backgroundColor: const Color(0xFF2A2A2A),
                   label: 'Reps',
                   value: '${exercicio['numero_repeticoes'] ?? 0}',
                 ),
                 const SizedBox(width: 8),
                 _buildStatRow(
                   icon: Icons.monitor_weight,
                   iconColor: const Color(0xFF666666),
                   backgroundColor: const Color(0xFFE8E8E8),
                   label: 'Peso',
                   value: '${exercicio['peso'] ?? 0}kg',
                 ),
               ],
             ),
           ],
         );
     }
   }

   Color _getCategoriaColor(String categoria) {
     switch (categoria) {
       case 'Com Pesos (Musculação)':
         return const Color(0xFF3B82F6); // Azul
       case 'Peso Corporal (Calistenia)':
         return const Color(0xFF10B981); // Verde
       case 'Cardio / Corrida':
         return const Color(0xFFF59E0B); // Laranja
       case 'Funcional':
         return const Color(0xFF8B5CF6); // Roxo
       case 'Alongamento / Mobilidade':
         return const Color(0xFF06B6D4); // Ciano
       case 'HIIT / Alta Intensidade':
         return const Color(0xFFEF4444); // Vermelho
       case 'Isometria':
         return const Color(0xFF6B7280); // Cinza
       default:
         return const Color(0xFF6B7280); // Cinza padrão
     }
   }

   String _getCategoriaShortName(String categoria) {
     switch (categoria) {
       case 'Com Pesos (Musculação)':
         return 'MUSCULAÇÃO';
       case 'Peso Corporal (Calistenia)':
         return 'CALISTENIA';
       case 'Cardio / Corrida':
         return 'CARDIO';
       case 'Funcional':
         return 'FUNCIONAL';
       case 'Alongamento / Mobilidade':
         return 'ALONGAMENTO';
       case 'HIIT / Alta Intensidade':
         return 'HIIT';
       case 'Isometria':
         return 'ISOMETRIA';
       default:
         return 'EXERCÍCIO';
     }
   }

  Widget _buildHolographicDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.cyanAccent.withOpacity(0.5),
            Colors.blueAccent.withOpacity(0.5),
            Colors.transparent,
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

     // Interfaces específicas por categoria
     Widget _buildMusculacaoInterface(Map<String, dynamic> exercicio) {
       final peso = exercicio['peso']?.toString() ?? '0';
       final reps = exercicio['numero_repeticoes']?.toString() ?? '0';
       final series = exercicio['numero_series']?.toString() ?? '0';
       
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: const Color(0xFF3B82F6).withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
         ),
         child: Column(
           children: [
             Text(
               'MUSCULAÇÃO',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: const Color(0xFF3B82F6),
                 letterSpacing: 1,
               ),
             ),
             const SizedBox(height: 12),
             // Musculação: peso, repetições e séries (com descanso implícito)
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _buildInfoCard('PESO', '${peso}kg', Icons.fitness_center, const Color(0xFF3B82F6)),
                 _buildInfoCard('REPS', reps, Icons.repeat, const Color(0xFF3B82F6)),
                 _buildInfoCard('SÉRIE', '$serieAtual/$series', Icons.format_list_numbered, const Color(0xFF3B82F6)),
               ],
             ),
           ],
         ),
       );
     }

     Widget _buildCalisteniaInterface(Map<String, dynamic> exercicio) {
       final reps = exercicio['numero_repeticoes']?.toString() ?? '0';
       final series = exercicio['numero_series']?.toString() ?? '0';
       final descanso = exercicio['tempo_descanso']?.toString() ?? '0';
       
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: const Color(0xFF10B981).withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
         ),
         child: Column(
           children: [
             Text(
               'PESO CORPORAL (CALISTENIA)',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: const Color(0xFF10B981),
                 letterSpacing: 1,
               ),
             ),
             const SizedBox(height: 12),
             // Calistenia: repetições, séries e descanso (sem peso)
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _buildInfoCard('REPETIÇÕES', reps, Icons.accessibility_new, const Color(0xFF10B981)),
                 _buildInfoCard('SÉRIE', '$serieAtual/$series', Icons.format_list_numbered, const Color(0xFF10B981)),
                 _buildInfoCard('DESCANSO', '${descanso}s', Icons.timer, const Color(0xFF10B981)),
               ],
             ),
           ],
         ),
       );
     }

     Widget _buildCardioInterface(Map<String, dynamic> exercicio) {
       final duracao = exercicio['tempo_descanso']?.toString() ?? '0'; // Usando tempo_descanso como duração
       final distancia = exercicio['distancia']?.toString() ?? '0';
       
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: const Color(0xFFF59E0B).withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
         ),
         child: Column(
           children: [
             Text(
               'CARDIO / CORRIDA',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: const Color(0xFFF59E0B),
                 letterSpacing: 1,
               ),
             ),
             const SizedBox(height: 12),
             // Cardio tem duração e distância
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 _buildInfoCard('DURAÇÃO', '${duracao} min', Icons.timer, const Color(0xFFF59E0B)),
                 _buildInfoCard('DISTÂNCIA', '${distancia}km', Icons.place, const Color(0xFFF59E0B)),
               ],
             ),
           ],
         ),
       );
     }

     Widget _buildHIITInterface(Map<String, dynamic> exercicio) {
       final trabalho = exercicio['numero_repeticoes']?.toString() ?? '0';
       final descanso = exercicio['tempo_descanso']?.toString() ?? '0';
       final rounds = exercicio['numero_series']?.toString() ?? '0';
       
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: const Color(0xFFEF4444).withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
         ),
         child: Column(
           children: [
             Text(
               'HIIT / ALTA INTENSIDADE',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: const Color(0xFFEF4444),
                 letterSpacing: 1,
               ),
             ),
             const SizedBox(height: 12),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _buildInfoCard('TRABALHO', '${trabalho}s', Icons.whatshot, const Color(0xFFEF4444)),
                 _buildInfoCard('DESCANSO', '${descanso}s', Icons.pause, const Color(0xFFEF4444)),
                 _buildInfoCard('ROUND', '$serieAtual/$rounds', Icons.repeat, const Color(0xFFEF4444)),
               ],
             ),
           ],
         ),
       );
     }

     Widget _buildIsometriaInterface(Map<String, dynamic> exercicio) {
       final duracao = exercicio['numero_repeticoes']?.toString() ?? '0';
       final series = exercicio['numero_series']?.toString() ?? '0';
       final descanso = exercicio['tempo_descanso']?.toString() ?? '0';
       
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: const Color(0xFF6B7280).withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: const Color(0xFF6B7280).withOpacity(0.3)),
         ),
         child: Column(
           children: [
             Text(
               'ISOMETRIA',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: const Color(0xFF6B7280),
                 letterSpacing: 1,
               ),
             ),
             const SizedBox(height: 12),
             // Isometria: duração, séries e descanso (sem repetições ou peso)
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _buildInfoCard('DURAÇÃO', '${duracao}s', Icons.pause_circle_filled, const Color(0xFF6B7280)),
                 _buildInfoCard('SÉRIE', '$serieAtual/$series', Icons.format_list_numbered, const Color(0xFF6B7280)),
                 _buildInfoCard('DESCANSO', '${descanso}s', Icons.timer, const Color(0xFF6B7280)),
               ],
             ),
           ],
         ),
       );
     }

     Widget _buildFuncionalInterface(Map<String, dynamic> exercicio) {
       final reps = exercicio['numero_repeticoes']?.toString() ?? '0';
       final series = exercicio['numero_series']?.toString() ?? '0';
       final descanso = exercicio['tempo_descanso']?.toString() ?? '0';
       
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: const Color(0xFF8B5CF6).withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: const Color(0xFF8B5CF6).withOpacity(0.3)),
         ),
         child: Column(
           children: [
             Text(
               'FUNCIONAL',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: const Color(0xFF8B5CF6),
                 letterSpacing: 1,
               ),
             ),
             const SizedBox(height: 12),
             // Funcional: repetições/tempo, séries e descanso (sem peso)
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _buildInfoCard('REPS/TEMPO', reps, Icons.sports_gymnastics, const Color(0xFF8B5CF6)),
                 _buildInfoCard('SÉRIE', '$serieAtual/$series', Icons.format_list_numbered, const Color(0xFF8B5CF6)),
                 _buildInfoCard('DESCANSO', '${descanso}s', Icons.timer, const Color(0xFF8B5CF6)),
               ],
             ),
           ],
         ),
       );
     }

     Widget _buildAlongamentoInterface(Map<String, dynamic> exercicio) {
       final duracao = exercicio['tempo_descanso']?.toString() ?? '0';
       final repeticoes = exercicio['numero_series']?.toString() ?? '0';
       
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: const Color(0xFF06B6D4).withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.3)),
         ),
         child: Column(
           children: [
             Text(
               'ALONGAMENTO / MOBILIDADE',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: const Color(0xFF06B6D4),
                 letterSpacing: 1,
               ),
             ),
             const SizedBox(height: 12),
             // Alongamento só tem duração e repetições (sem peso ou séries)
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 _buildInfoCard('DURAÇÃO', '${duracao}s', Icons.timer, const Color(0xFF06B6D4)),
                 _buildInfoCard('REPETIÇÕES', repeticoes, Icons.repeat, const Color(0xFF06B6D4)),
               ],
             ),
           ],
         ),
       );
     }

     Widget _buildGenericoInterface(Map<String, dynamic> exercicio) {
       final reps = exercicio['numero_repeticoes']?.toString() ?? '0';
       final peso = exercicio['peso']?.toString() ?? '0';
       final series = exercicio['numero_series']?.toString() ?? '0';
       
       return Container(
         padding: const EdgeInsets.all(16),
         decoration: BoxDecoration(
           color: Colors.grey.withOpacity(0.1),
           borderRadius: BorderRadius.circular(12),
           border: Border.all(color: Colors.grey.withOpacity(0.3)),
         ),
         child: Column(
           children: [
             Text(
               'EXERCÍCIO',
               style: TextStyle(
                 fontSize: 12,
                 fontWeight: FontWeight.bold,
                 color: Colors.grey[700],
                 letterSpacing: 1,
               ),
             ),
             const SizedBox(height: 12),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceAround,
               children: [
                 _buildInfoCard('REPS', reps, Icons.repeat, Colors.grey[700]!),
                 _buildInfoCard('PESO', '${peso}kg', Icons.fitness_center, Colors.grey[700]!),
                 _buildInfoCard('SÉRIE', '$serieAtual/$series', Icons.format_list_numbered, Colors.grey[700]!),
               ],
             ),
           ],
         ),
       );
     }

     Widget _buildInfoCard(String label, String value, IconData? icon, Color color) {
     return Column(
       children: [
           if (icon != null)
             Icon(icon, color: color, size: 20)
           else
             Text(value, style: TextStyle(fontSize: 16)),
           const SizedBox(height: 4),
           Text(
             label,
             style: TextStyle(
               fontSize: 10,
               fontWeight: FontWeight.bold,
               color: color,
             ),
           ),
           if (icon != null) ...[
             const SizedBox(height: 2),
             Text(
               value,
               style: TextStyle(
                 fontSize: 14,
                 fontWeight: FontWeight.bold,
                 color: color,
               ),
             ),
           ],
         ],
       );
     }

     Widget _buildCategoriaSpecificInterface(String categoria, Map<String, dynamic> exercicio) {
       print('DEBUG: Categoria recebida: "$categoria"');
       print('DEBUG: Exercício completo: $exercicio');
       
       switch (categoria) {
         case 'Com Pesos (Musculação)':
           print('DEBUG: Usando interface de Musculação');
           return _buildMusculacaoInterface(exercicio);
         case 'Peso Corporal (Calistenia)':
           print('DEBUG: Usando interface de Calistenia');
           return _buildCalisteniaInterface(exercicio);
         case 'Cardio / Corrida':
           print('DEBUG: Usando interface de Cardio');
           return _buildCardioInterface(exercicio);
         case 'Funcional':
           print('DEBUG: Usando interface Funcional');
           return _buildFuncionalInterface(exercicio);
         case 'Alongamento / Mobilidade':
           print('DEBUG: Usando interface de Alongamento');
           return _buildAlongamentoInterface(exercicio);
         case 'HIIT / Alta Intensidade':
           print('DEBUG: Usando interface HIIT');
           return _buildHIITInterface(exercicio);
         case 'Isometria':
           print('DEBUG: Usando interface Isometria');
           return _buildIsometriaInterface(exercicio);
         default:
           print('DEBUG: Usando interface genérica - categoria não reconhecida');
           return _buildGenericoInterface(exercicio);
       }
     }

     Widget _buildFuturisticControlPanel(bool isDark, Map<String, dynamic> exercicio) {
       final categoria = exercicio['categoria']?.toString() ?? '';
       
       return Column(
         children: [
           // Layout principal com botão circular no centro
         Row(
           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
           children: [
             // Botão esquerdo - Concluir exercício
             _buildSideButton(
               text: 'CONCLUIR\nEXERCÍCIO',
               onPressed: concluirExercicio,
               icon: Icons.done_all,
               isDark: false,
             ),
             
             // Botão central circular - Ação principal
             _buildCentralButton(
               onPressed: descansando ? null : concluirSerie,
               isResting: descansando,
               restTime: tempoRestante,
               isDark: false,
               isCardio: descansando ? _isCardioDescanso : categoria == 'Cardio / Corrida',
             ),
             
             // Botão direito - Pular exercício
             _buildSideButton(
               text: 'PULAR\nEXERCÍCIO',
               onPressed: pularExercicio,
               icon: Icons.skip_next,
               isDark: false,
             ),
           ],
         ),
       ],
     );
   }

   Widget _buildCentralButton({
     required VoidCallback? onPressed,
     required bool isResting,
     required int restTime,
     required bool isDark,
     bool isCardio = false,
   }) {
     return GestureDetector(
       onTap: onPressed,
       child: Container(
         width: 64,
         height: 64,
         decoration: BoxDecoration(
           color: onPressed != null 
               ? const Color(0xFF3B82F6)
               : const Color(0xFFCCCCCC),
           shape: BoxShape.circle,
           boxShadow: onPressed != null ? [
             BoxShadow(
               color: Colors.black.withOpacity(0.1),
               blurRadius: 8,
               offset: const Offset(0, 3),
             ),
           ] : null,
         ),
         child: Center(
           child: isResting
               ? Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(
                       Icons.pause,
                       color: Colors.white,
                       size: 18,
                     ),
                     Text(
                       isCardio 
                           ? '${(restTime ~/ 60).toString().padLeft(2, '0')}:${(restTime % 60).toString().padLeft(2, '0')}'
                           : '${restTime}s',
                       style: GoogleFonts.poppins(
                         color: Colors.white,
                         fontSize: 8,
                         fontWeight: FontWeight.w500,
                       ),
                     ),
                   ],
                 )
               : Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(
                       Icons.play_arrow,
                       color: onPressed != null 
                           ? Colors.white
                           : Colors.grey[600],
                       size: 20,
                     ),
                     if (isCardio) ...[
                       const SizedBox(height: 2),
                       Text(
                         'EXECUTAR',
                         style: GoogleFonts.poppins(
                           color: onPressed != null 
                               ? Colors.white
                               : Colors.grey[600],
                           fontSize: 6,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ],
                   ],
                 ),
         ),
       ),
     );
   }

   Widget _buildSideButton({
     required String text,
     required VoidCallback onPressed,
     required IconData icon,
     required bool isDark,
   }) {
     return GestureDetector(
       onTap: onPressed,
       child: Container(
         width: 64,
         height: 64,
         decoration: BoxDecoration(
           color: const Color(0xFFF8F8F8),
           borderRadius: BorderRadius.circular(12),
           boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.04),
               blurRadius: 6,
               offset: const Offset(0, 2),
             ),
           ],
         ),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(
               icon,
               color: const Color(0xFF666666),
               size: 18,
             ),
             const SizedBox(height: 3),
             Text(
               text,
               textAlign: TextAlign.center,
               style: GoogleFonts.poppins(
                 color: const Color(0xFF666666),
                 fontSize: 8,
                 fontWeight: FontWeight.w500,
                 height: 1.1,
               ),
             ),
           ],
         ),
       ),
     );
   }

     Widget _buildQuantumButton({
     required String text,
     required VoidCallback? onPressed,
     required bool isPrimary,
     required IconData icon,
     required bool isDark,
   }) {
     return GestureDetector(
       onTapDown: onPressed != null ? (_) => _buttonController.forward() : null,
       onTapUp: onPressed != null ? (_) => _buttonController.reverse() : null,
       onTapCancel: onPressed != null ? () => _buttonController.reverse() : null,
       onTap: onPressed,
       child: AnimatedBuilder(
         animation: _buttonAnimation,
         builder: (context, child) {
           return Transform.scale(
             scale: onPressed != null ? _buttonAnimation.value : 1.0,
             child: Container(
               padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
               decoration: BoxDecoration(
                 color: onPressed != null
                     ? (isPrimary
                         ? const Color(0xFF3B82F6) // Azul para botão principal
                         : const Color(0xFFE8E8E8)) // Cinza claro para botões secundários
                     : const Color(0xFFCCCCCC), // Cinza para desabilitado
                 borderRadius: BorderRadius.circular(16),
                 boxShadow: onPressed != null ? [
                   BoxShadow(
                     color: Colors.black.withOpacity(0.1),
                     blurRadius: 8,
                     offset: const Offset(0, 2),
                   ),
                 ] : null,
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(
                     icon,
                     size: 18,
                     color: onPressed != null
                         ? (isPrimary 
                             ? Colors.white // Branco no botão azul
                             : const Color(0xFF666666)) // Cinza escuro nos secundários
                         : Colors.grey[500],
                   ),
                   const SizedBox(width: 8),
                   Text(
                     text,
                     style: GoogleFonts.poppins(
                                            color: onPressed != null
                         ? (isPrimary 
                             ? Colors.white // Branco no botão azul
                             : const Color(0xFF666666)) // Cinza escuro nos secundários
                         : Colors.grey[500],
                       fontSize: 14,
                       fontWeight: FontWeight.w600,
                       letterSpacing: 0.3,
                     ),
                   ),
                 ],
               ),
             ),
           );
         },
       ),
     );
   }

  Widget _buildNavItem(IconData icon, String label, int index, int selectedIndex) {
    final bool isSelected = index == selectedIndex;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            if (index != 2) {
              // Navegar para a HomePage com o índice correto
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomePageWithIndex(initialIndex: index)),
                (route) => false,
              );
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.only(bottom: 2),
                  width: isSelected ? 35 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                              Icon(
                icon,
                size: 23, // Aumentado de 20 para 23 (13% maior)
                color: isSelected 
                  ? const Color(0xFF3B82F6) 
                  : const Color(0xFF6B7280),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9, // Aumentado de 8 para 9 (13% maior)
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected 
                      ? const Color(0xFF3B82F6) 
                      : const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Função para salvar o prêmio conquistado
  Future<void> _salvarPremio(double pesoTotal, Map<String, dynamic> premio) async {
    try {
      print('=== INICIANDO SALVAMENTO DO PRÊMIO ===');
      final prefs = await SharedPreferences.getInstance();
      final usuarioId = prefs.getInt('usuario_id');
      
      if (usuarioId == null) {
        print('❌ Usuário não logado');
        return;
      }
      
      print('✅ UsuarioId: $usuarioId');
      print('✅ Animal: ${premio['nome']}');
      print('✅ Emoji: ${premio['emoji']}');
      print('✅ Peso animal: ${premio['peso']}');
      print('✅ Peso total: $pesoTotal');
      print('✅ Nome treino: ${widget.nomeTreino}');
      
      final url = Uri.parse('https://airfit.online/api/salvar_premio_v2.php');
      final body = jsonEncode({
        'usuario_id': usuarioId,
        'nome_animal': premio['nome'], // Salvar o nome completo (ex: "15 Tigres")
        'emoji_animal': premio['emoji'],
        'peso_animal': premio['peso'],
        'peso_total_levantado': pesoTotal > 0 ? pesoTotal : 0.0, // Se for Águia, salvar 0
        'data_conquista': DateTime.now().toIso8601String(),
        'nome_treino': widget.nomeTreino,
      });
      
      print('🌐 URL: $url');
      print('📦 Body: $body');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
      
      print('📡 Status da resposta: ${response.statusCode}');
      print('📄 Corpo da resposta: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['sucesso'] == true) {
            print('✅ Prêmio salvo com sucesso!');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🎉 Prêmio ${premio['nome']} coletado com sucesso!'),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          } else {
            print('❌ Erro ao salvar prêmio: ${responseData['erro']}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ Erro ao salvar prêmio: ${responseData['erro']}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        } catch (jsonError) {
          print('❌ Erro ao decodificar JSON: $jsonError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Erro ao processar resposta do servidor'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        print('❌ Erro HTTP ${response.statusCode}: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro de conexão: ${response.statusCode}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erro ao salvar prêmio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar prêmio: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }


} 

class _InfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoBlock({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF2563EB)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
} 

class _BarraProgressoSeries extends StatelessWidget {
  final int total;
  final int atual;
  const _BarraProgressoSeries({required this.total, required this.atual});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) =>
        Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
            height: 10,
            decoration: BoxDecoration(
              color: i < atual ? const Color(0xFF2563EB) : const Color(0xFFE0E7EF),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
} 

class _FuturisticInfoBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _FuturisticInfoBlock({required this.icon, required this.label, required this.value, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16213E) : const Color(0xFFF4F7FE),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? Colors.cyanAccent : const Color(0xFF2563EB),
            width: 1.5,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.18),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isDark ? Colors.cyanAccent : const Color(0xFF2563EB)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF2563EB))),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : const Color(0xFF2563EB))),
          ],
        ),
      ),
    );
  }
}

class _FuturisticButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isMain;
  final bool isDark;
  final IconData? icon;
  const _FuturisticButton({required this.text, this.onPressed, required this.isMain, required this.isDark, this.icon});
  @override
  Widget build(BuildContext context) {
    if (!isDark) {
      return ElevatedButton(
        onPressed: onPressed,
        child: icon != null ? Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Icon(icon, size: 18), const SizedBox(width: 8), Text(text)],
        ) : Text(text),
      );
    }
    if (isMain) {
      // Botão com gradiente
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.cyanAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(text, style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        fontSize: 16,
                      )),
                    ],
                  )
                : Text(text, style: GoogleFonts.orbitron(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 16,
                  )),
          ),
        ),
      );
    }
    // Botão secundário
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
        shadowColor: Colors.blueAccent.withOpacity(0.4),
        textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
      child: icon != null ? Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Icon(icon, size: 18, color: Colors.cyanAccent), const SizedBox(width: 8), Text(text)],
      ) : Text(text),
    );
  }
}