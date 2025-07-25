import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trofeu_animal.dart';

class TrofeuService {
  static const String _baseUrl = 'https://airfit.online/api/salvar_premio_v2.php';

  // Conceder troféu ao completar uma meta
  static Future<TrofeuAnimal?> concederTrofeuMeta({
    required String usuarioId,
    required String metaId,
    required String nomeMeta,
  }) async {
    try {
      // Obter troféu aleatório
      final trofeu = TrofeusAnimais.obterTrofeuAleatorio();

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'usuario_id': usuarioId,
          'nome_animal': trofeu.nome,
          'emoji_animal': trofeu.emoji,
          'tipo_conquista': 'meta',
          'nome_meta': nomeMeta,
          'raridade_trofeu': trofeu.raridade,
          'categoria_trofeu': trofeu.categoria,
          'descricao_trofeu': trofeu.descricao,
          'mensagem_motivacional': trofeu.mensagemMotivacional,
          'data_conquista': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucesso'] == true) {
          print('🏆 Troféu concedido: ${trofeu.nome} (${trofeu.raridadeTexto})');
          return trofeu;
        } else {
          print('❌ Erro ao conceder troféu: ${data['erro']}');
          return null;
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao conceder troféu: $e');
      return null;
    }
  }

  // Obter troféus conquistados por meta
  static Future<List<TrofeuConquistado>> obterTrofeusMeta({
    required String usuarioId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?usuario_id=$usuarioId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucesso'] == true) {
          final trofeus = <TrofeuConquistado>[];
          
          for (var premioData in data['premios'] ?? []) {
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

          print('🏆 Troféus carregados: ${trofeus.length} encontrados');
          return trofeus;
        } else {
          print('❌ Erro ao carregar troféus: ${data['erro']}');
          return [];
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erro ao carregar troféus: $e');
      return [];
    }
  }

  // Obter mensagem motivacional aleatória
  static String obterMensagemMotivacional() {
    final mensagens = [
      'Cada passo conta! Continue firme na sua jornada! 💪',
              'A força é a ponte entre objetivos e realizações! 🌉',
      'Você está mais forte do que imagina! 🔥',
      'O progresso não acontece da noite para o dia, mas acontece! ⭐',
      'Cada dia é uma nova oportunidade de ser melhor! 🌅',
      'A consistência é mais importante que a perfeição! 🎯',
      'Você está construindo uma versão incrível de si mesmo! 🏗️',
      'A determinação transforma sonhos em realidade! ✨',
      'Cada esforço te aproxima do seu objetivo! 🎯',
      'Você tem o poder de mudar sua vida! ⚡',
      'A persistência vence a resistência! 🛡️',
      'Cada meta alcançada é uma vitória! 🏆',
      'Você está no caminho certo! Continue! 🛤️',
      'A força está dentro de você! 💎',
      'Cada progresso é uma celebração! 🎉',
      'Você está fazendo história! 📚',
      'A determinação é sua superpotência! 🦸‍♂️',
      'Cada dia é uma nova chance de brilhar! ⭐',
      'Você está inspirando outros com sua dedicação! 🌟',
      'O sucesso é uma jornada, não um destino! 🗺️',
    ];

    final random = DateTime.now().millisecondsSinceEpoch;
    final index = random % mensagens.length;
    return mensagens[index];
  }

  // Obter mensagem motivacional específica para o tipo de meta
  static String obterMensagemPorTipoMeta(String tipoMeta) {
    switch (tipoMeta.toLowerCase()) {
      case 'peso':
        return 'Cada grama perdida é uma vitória! Continue firme na sua transformação! ⚖️';
      case 'distancia':
        return 'Cada quilômetro percorrido te torna mais forte! Continue correndo! 🏃‍♂️';
      case 'repeticoes':
        return 'Cada repetição te aproxima da força que você busca! Continue! 💪';
      case 'frequencia':
        return 'A consistência é sua maior aliada! Continue treinando regularmente! 📅';
      case 'carga':
        return 'Cada kg a mais é uma prova da sua evolução! Continue forte! 🏋️';
      case 'medidas':
        return 'Cada centímetro é uma conquista! Continue medindo seu progresso! 📏';
      default:
        return obterMensagemMotivacional();
    }
  }
} 