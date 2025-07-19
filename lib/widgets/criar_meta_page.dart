import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meta.dart';
import '../services/meta_service.dart';

class CriarMetaPage extends StatefulWidget {
  final int usuarioId;
  
  const CriarMetaPage({super.key, required this.usuarioId});

  @override
  State<CriarMetaPage> createState() => _CriarMetaPageState();
}

class _CriarMetaPageState extends State<CriarMetaPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorInicialController = TextEditingController();
  final _valorDesejadoController = TextEditingController();
  final _observacaoController = TextEditingController();
  
  TipoMeta _tipoSelecionado = TipoMeta.peso;
  DateTime? _prazoSelecionado;
  bool _isLoading = false;

  @override
  void dispose() {
    _nomeController.dispose();
    _valorInicialController.dispose();
    _valorDesejadoController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarPrazo() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (data != null) {
      setState(() {
        _prazoSelecionado = data;
      });
    }
  }

  Future<void> _criarMeta() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final valorInicial = double.parse(_valorInicialController.text);
      final valorDesejado = double.parse(_valorDesejadoController.text);

      await metaService.criarMeta(
        nome: _nomeController.text.trim(),
        tipo: _tipoSelecionado,
        valorInicial: valorInicial,
        valorDesejado: valorDesejado,
        prazo: _prazoSelecionado,
        usuarioId: widget.usuarioId,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meta criada com sucesso! 🎉'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar meta: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Nova Meta',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card principal
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome da meta
                    const Text(
                      'Nome da Meta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Perder 10kg, Correr 5km...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Digite um nome para a meta';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Tipo da meta
                    const Text(
                      'Tipo da Meta',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: TipoMeta.values.length,
                      itemBuilder: (context, index) {
                        final tipo = TipoMeta.values[index];
                        final isSelected = tipo == _tipoSelecionado;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _tipoSelecionado = tipo;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? _getTipoColor(tipo).withOpacity(0.1)
                                  : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? _getTipoColor(tipo)
                                    : const Color(0xFFE5E7EB),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 12),
                                Text(
                                  tipo.icone,
                                  style: const TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tipo.nome,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isSelected 
                                              ? _getTipoColor(tipo)
                                              : const Color(0xFF374151),
                                        ),
                                      ),
                                      Text(
                                        tipo.descricao,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isSelected 
                                              ? _getTipoColor(tipo).withOpacity(0.8)
                                              : const Color(0xFF6B7280),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Valores
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Valor Inicial',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _valorInicialController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0.0',
                                  suffixText: _tipoSelecionado.unidade,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite o valor inicial';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Digite um número válido';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Valor Desejado',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _valorDesejadoController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '0.0',
                                  suffixText: _tipoSelecionado.unidade,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite o valor desejado';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Digite um número válido';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Prazo (opcional)
                    const Text(
                      'Prazo (Opcional)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selecionarPrazo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _prazoSelecionado != null
                                  ? DateFormat('dd/MM/yyyy').format(_prazoSelecionado!)
                                  : 'Selecionar prazo',
                              style: TextStyle(
                                color: _prazoSelecionado != null
                                    ? const Color(0xFF374151)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                            const Spacer(),
                            if (_prazoSelecionado != null)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _prazoSelecionado = null;
                                  });
                                },
                                icon: const Icon(Icons.clear, color: Color(0xFF6B7280)),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Botão criar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _criarMeta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Criar Meta',
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
} 