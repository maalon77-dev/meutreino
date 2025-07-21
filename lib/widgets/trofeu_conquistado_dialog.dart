import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trofeu_animal.dart';

class TrofeuConquistadoDialog extends StatelessWidget {
  final TrofeuAnimal trofeu;
  final String nomeMeta;
  final DateTime dataConquista;

  const TrofeuConquistadoDialog({
    super.key,
    required this.trofeu,
    required this.nomeMeta,
    required this.dataConquista,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              trofeu.corRaridade.withOpacity(0.1),
              trofeu.corRaridade.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: trofeu.corRaridade.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: trofeu.corRaridade.withOpacity(0.3),
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: trofeu.corRaridade.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: trofeu.corRaridade,
                  width: 3,
                ),
              ),
              child: Text(
                '🏆',
                style: const TextStyle(fontSize: 48),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Título
            Text(
              'META CONCLUÍDA!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: trofeu.corRaridade,
                letterSpacing: 1.2,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Nome da meta
            Text(
              nomeMeta,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // Animal conquistado
            Container(
              padding: const EdgeInsets.all(16),
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
                children: [
                  // Emoji do animal
                  Text(
                    trofeu.emoji,
                    style: const TextStyle(fontSize: 64),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Nome do animal
                  Text(
                    trofeu.nome,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Raridade
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: trofeu.corRaridade.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: trofeu.corRaridade,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      trofeu.raridadeTexto,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: trofeu.corRaridade,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Descrição
                  Text(
                    trofeu.descricao,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Mensagem motivacional
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: trofeu.corRaridade.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: trofeu.corRaridade.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome,
                    color: trofeu.corRaridade,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      trofeu.mensagemMotivacional,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: trofeu.corRaridade,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Data da conquista
            Text(
              'Conquistado em ${DateFormat('dd/MM/yyyy HH:mm').format(dataConquista)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Botão fechar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: trofeu.corRaridade,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continuar',
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
  }
} 