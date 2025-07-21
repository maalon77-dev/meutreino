import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/meta.dart';
import '../services/meta_service.dart';

class AtualizarProgressoPage extends StatefulWidget {
  final Meta meta;
  final int usuarioId;

  const AtualizarProgressoPage({
    super.key,
    required this.meta,
    required this.usuarioId,
  });

  @override
  State<AtualizarProgressoPage> createState() => _AtualizarProgressoPageState();
}

class _AtualizarProgressoPageState extends State<AtualizarProgressoPage> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _observacaoController = TextEditingController();
  bool _isLoading = false;
  Meta? _metaAtualizada;

  @override
  void initState() {
    super.initState();
    _metaAtualizada = widget.meta;
    _carregarMetaAtualizada();
  }

  @override
  void dispose() {
    _valorController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  Future<void> _carregarMetaAtualizada() async {
    try {
      final metaAtualizada = await metaService.obterMetaPorId(widget.meta.id, widget.usuarioId);
      if (metaAtualizada != null) {
        setState(() {
          _metaAtualizada = metaAtualizada;
        });
      }
    } catch (e) {
      print('Erro ao carregar meta atualizada: $e');
    }
  }

  Future<void> _atualizarProgresso() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final valor = double.parse(_valorController.text);
      final observacao = _observacaoController.text.trim().isEmpty 
          ? null 
          : _observacaoController.text.trim();

      // Verificar se a meta estava concluída antes da atualização
      final metaAntes = _metaAtualizada ?? widget.meta;
      final percentualAntes = metaAntes.percentualConclusao;
      final estavaConcluida = percentualAntes >= 100;

      print('📊 Percentual antes da atualização: ${percentualAntes.toStringAsFixed(1)}%');

      await metaService.adicionarProgresso(
        widget.meta.id,
        valor,
        observacao,
        usuarioId: widget.usuarioId,
      );

      // Recarregar a meta atualizada
      await _carregarMetaAtualizada();

      if (mounted) {
        // Verificar se a meta foi concluída agora
        final metaDepois = _metaAtualizada ?? widget.meta;
        final percentualDepois = metaDepois.percentualConclusao;
        final foiConcluida = percentualDepois >= 100;

        print('📊 Percentual depois da atualização: ${percentualDepois.toStringAsFixed(1)}%');

        // Se a meta foi concluída agora (não estava antes), mostrar mensagem
        if (foiConcluida && !estavaConcluida) {
          print('🎉 Meta concluída!');
          await _mostrarParabens();
        } else if (foiConcluida && estavaConcluida) {
          print('ℹ️ Meta já estava concluída');
        } else {
          print('📈 Meta ainda em progresso');
        }

        setState(() {
          _isLoading = false;
        });

        // Retornar true para indicar que houve atualização
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Erro ao atualizar progresso: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar progresso: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _mostrarParabens() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 48,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Parabéns! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Você concluiu a meta:\n"${widget.meta.nome}"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Continue assim! Sua dedicação está sendo recompensada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Continuar',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = _metaAtualizada ?? widget.meta;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Atualizar Progresso',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1F2937)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card da meta
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      LinearProgressIndicator(
                        value: meta.percentualConclusao / 100,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Formulário de atualização
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Novo Progresso',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de valor
                    TextFormField(
                      controller: _valorController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Valor (${meta.tipo.unidade})',
                        hintText: 'Digite o novo valor',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.trending_up),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Digite um valor';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Digite um número válido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Campo de observação
                    TextFormField(
                      controller: _observacaoController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Observação (opcional)',
                        hintText: 'Como foi seu progresso hoje?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.note),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Botão de atualizar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _atualizarProgresso,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                                'Atualizar Progresso',
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
          ],
        ),
      ),
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
} 