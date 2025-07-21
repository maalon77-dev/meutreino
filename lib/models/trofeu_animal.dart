import 'package:flutter/material.dart';

class TrofeuAnimal {
  final String id;
  final String nome;
  final String emoji;
  final String descricao;
  final String categoria;
  final int raridade; // 1-5 (1 = comum, 5 = lendário)
  final String mensagemMotivacional;

  const TrofeuAnimal({
    required this.id,
    required this.nome,
    required this.emoji,
    required this.descricao,
    required this.categoria,
    required this.raridade,
    required this.mensagemMotivacional,
  });

  String get raridadeTexto {
    switch (raridade) {
      case 1:
        return 'Comum';
      case 2:
        return 'Incomum';
      case 3:
        return 'Raro';
      case 4:
        return 'Épico';
      case 5:
        return 'Lendário';
      default:
        return 'Desconhecido';
    }
  }

  Color get corRaridade {
    switch (raridade) {
      case 1:
        return const Color(0xFF6B7280); // Cinza
      case 2:
        return const Color(0xFF10B981); // Verde
      case 3:
        return const Color(0xFF3B82F6); // Azul
      case 4:
        return const Color(0xFF8B5CF6); // Roxo
      case 5:
        return const Color(0xFFFFD700); // Dourado
      default:
        return const Color(0xFF6B7280);
    }
  }
}

class TrofeuConquistado {
  final String id;
  final String trofeuId;
  final String usuarioId;
  final String metaId;
  final String nomeMeta;
  final DateTime dataConquista;
  final TrofeuAnimal trofeu;

  TrofeuConquistado({
    required this.id,
    required this.trofeuId,
    required this.usuarioId,
    required this.metaId,
    required this.nomeMeta,
    required this.dataConquista,
    required this.trofeu,
  });

  factory TrofeuConquistado.fromJson(Map<String, dynamic> json, TrofeuAnimal trofeu) {
    return TrofeuConquistado(
      id: json['id'].toString(),
      trofeuId: json['id'].toString(),
      usuarioId: json['usuario_id'].toString(),
      metaId: json['id'].toString(), // Usar o ID do prêmio como metaId
      nomeMeta: json['nome_meta'] ?? '',
      dataConquista: DateTime.parse(json['data_conquista']),
      trofeu: trofeu,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trofeu_id': trofeuId,
      'usuario_id': usuarioId,
      'meta_id': metaId,
      'nome_meta': nomeMeta,
      'data_conquista': dataConquista.toIso8601String(),
    };
  }
}

// Lista de 20 animais raros para troféus
class TrofeusAnimais {
  static const List<TrofeuAnimal> todos = [
    // Lendários (Raridade 5)
    TrofeuAnimal(
      id: 'dragão_cristal',
      nome: 'Dragão de Cristal',
      emoji: '🐉',
      descricao: 'Uma criatura mítica que brilha como diamante. Símbolo de força e determinação absoluta.',
      categoria: 'Lendário',
      raridade: 5,
      mensagemMotivacional: 'Como um dragão de cristal, você brilha com determinação! Continue assim! 💎',
    ),
    TrofeuAnimal(
      id: 'fênix_eterna',
      nome: 'Fênix Eterna',
      emoji: '🦅',
      descricao: 'A ave que renasce das cinzas. Representa superação e transformação constante.',
      categoria: 'Lendário',
      raridade: 5,
      mensagemMotivacional: 'Como uma fênix, você sempre se levanta mais forte! 🔥',
    ),
    TrofeuAnimal(
      id: 'unicórnio_arco_iris',
      nome: 'Unicórnio do Arco-íris',
      emoji: '🦄',
      descricao: 'Criatura mágica que espalha cores e esperança por onde passa.',
      categoria: 'Lendário',
      raridade: 5,
      mensagemMotivacional: 'Sua determinação é tão mágica quanto um unicórnio! ✨',
    ),

    // Épicos (Raridade 4)
    TrofeuAnimal(
      id: 'tigre_dourado',
      nome: 'Tigre Dourado',
      emoji: '🐯',
      descricao: 'O rei da selva com pelagem dourada. Símbolo de coragem e liderança.',
      categoria: 'Épico',
      raridade: 4,
      mensagemMotivacional: 'Você tem a coragem de um tigre dourado! Continue forte! 🐯',
    ),
    TrofeuAnimal(
      id: 'lobo_lunar',
      nome: 'Lobo Lunar',
      emoji: '🐺',
      descricao: 'Guardião da noite que caça sob a luz da lua. Representa instinto e perseverança.',
      categoria: 'Épico',
      raridade: 4,
      mensagemMotivacional: 'Como um lobo lunar, você persiste mesmo na escuridão! 🌙',
    ),
    TrofeuAnimal(
      id: 'águia_real',
      nome: 'Águia Real',
      emoji: '🦅',
      descricao: 'A rainha dos céus com visão extraordinária. Símbolo de foco e precisão.',
      categoria: 'Épico',
      raridade: 4,
      mensagemMotivacional: 'Sua visão de objetivo é como a de uma águia real! 👁️',
    ),
    TrofeuAnimal(
      id: 'leão_cristal',
      nome: 'Leão de Cristal',
      emoji: '🦁',
      descricao: 'O rei da selva com coração transparente. Representa nobreza e clareza de propósito.',
      categoria: 'Épico',
      raridade: 4,
      mensagemMotivacional: 'Seu coração é tão nobre quanto um leão de cristal! 💎',
    ),

    // Raros (Raridade 3)
    TrofeuAnimal(
      id: 'pantera_negra',
      nome: 'Pantera Negra',
      emoji: '🐆',
      descricao: 'Caçadora silenciosa e elegante. Símbolo de graça e eficiência.',
      categoria: 'Raro',
      raridade: 3,
      mensagemMotivacional: 'Sua graça e determinação são como uma pantera negra! 🐆',
    ),
    TrofeuAnimal(
      id: 'urso_polar',
      nome: 'Urso Polar',
      emoji: '🐻‍❄️',
      descricao: 'Gigante gentil do gelo. Representa força pacífica e resistência.',
      categoria: 'Raro',
      raridade: 3,
      mensagemMotivacional: 'Você tem a força resistente de um urso polar! ❄️',
    ),
    TrofeuAnimal(
      id: 'golfinho_arco_iris',
      nome: 'Golfinho do Arco-íris',
      emoji: '🐬',
      descricao: 'Nadador alegre que espalha felicidade. Símbolo de alegria e fluidez.',
      categoria: 'Raro',
      raridade: 3,
      mensagemMotivacional: 'Sua alegria no progresso é como um golfinho do arco-íris! 🌈',
    ),
    TrofeuAnimal(
      id: 'coruja_sabedoria',
      nome: 'Coruja da Sabedoria',
      emoji: '🦉',
      descricao: 'Guardiã do conhecimento noturno. Representa sabedoria e paciência.',
      categoria: 'Raro',
      raridade: 3,
      mensagemMotivacional: 'Sua sabedoria na jornada é como a de uma coruja! 🧠',
    ),
    TrofeuAnimal(
      id: 'cervo_real',
      nome: 'Cervo Real',
      emoji: '🦌',
      descricao: 'Nobre habitante da floresta. Símbolo de elegância e harmonia.',
      categoria: 'Raro',
      raridade: 3,
      mensagemMotivacional: 'Sua elegância no progresso é como a de um cervo real! 🦌',
    ),

    // Incomuns (Raridade 2)
    TrofeuAnimal(
      id: 'raposa_astuta',
      nome: 'Raposa Astuta',
      emoji: '🦊',
      descricao: 'Caçadora inteligente e adaptável. Representa criatividade e adaptação.',
      categoria: 'Incomum',
      raridade: 2,
      mensagemMotivacional: 'Sua astúcia na superação é como a de uma raposa! 🦊',
    ),
    TrofeuAnimal(
      id: 'coelho_veloz',
      nome: 'Coelho Veloz',
      emoji: '🐰',
      descricao: 'Saltador ágil e rápido. Símbolo de velocidade e agilidade.',
      categoria: 'Incomum',
      raridade: 2,
      mensagemMotivacional: 'Sua velocidade no progresso é como a de um coelho! 🐰',
    ),
    TrofeuAnimal(
      id: 'panda_gentil',
      nome: 'Panda Gentil',
      emoji: '🐼',
      descricao: 'Gigante gentil e pacífico. Representa calma e persistência.',
      categoria: 'Incomum',
      raridade: 2,
      mensagemMotivacional: 'Sua gentileza na jornada é como a de um panda! 🐼',
    ),
    TrofeuAnimal(
      id: 'pinguim_dançarino',
      nome: 'Pinguim Dançarino',
      emoji: '🐧',
      descricao: 'Bailarino do gelo. Símbolo de alegria e determinação.',
      categoria: 'Incomum',
      raridade: 2,
      mensagemMotivacional: 'Sua alegria no progresso é como a de um pinguim dançarino! 🐧',
    ),
    TrofeuAnimal(
      id: 'tartaruga_sabia',
      nome: 'Tartaruga Sábia',
      emoji: '🐢',
      descricao: 'Viajante paciente e sábio. Representa paciência e sabedoria.',
      categoria: 'Incomum',
      raridade: 2,
      mensagemMotivacional: 'Sua paciência na jornada é como a de uma tartaruga sábia! 🐢',
    ),

    // Comuns (Raridade 1)
    TrofeuAnimal(
      id: 'gato_curioso',
      nome: 'Gato Curioso',
      emoji: '🐱',
      descricao: 'Explorador curioso e independente. Símbolo de curiosidade e independência.',
      categoria: 'Comum',
      raridade: 1,
      mensagemMotivacional: 'Sua curiosidade pelo progresso é como a de um gato! 🐱',
    ),
    TrofeuAnimal(
      id: 'cachorro_fiel',
      nome: 'Cachorro Fiel',
      emoji: '🐕',
      descricao: 'Companheiro leal e dedicado. Representa lealdade e dedicação.',
      categoria: 'Comum',
      raridade: 1,
      mensagemMotivacional: 'Sua dedicação é como a de um cachorro fiel! 🐕',
    ),
    TrofeuAnimal(
      id: 'hamster_energético',
      nome: 'Hamster Energético',
      emoji: '🐹',
      descricao: 'Pequeno mas cheio de energia. Símbolo de energia e determinação.',
      categoria: 'Comum',
      raridade: 1,
      mensagemMotivacional: 'Sua energia no progresso é como a de um hamster! 🐹',
    ),
    TrofeuAnimal(
      id: 'pássaro_cantor',
      nome: 'Pássaro Cantor',
      emoji: '🐦',
      descricao: 'Músico da natureza. Representa alegria e liberdade.',
      categoria: 'Comum',
      raridade: 1,
      mensagemMotivacional: 'Sua alegria no progresso é como a de um pássaro cantor! 🐦',
    ),
  ];

  // Obter troféu aleatório baseado na raridade
  static TrofeuAnimal obterTrofeuAleatorio() {
    final random = DateTime.now().millisecondsSinceEpoch;
    final index = random % todos.length;
    return todos[index];
  }

  // Obter troféu por ID
  static TrofeuAnimal? obterPorId(String id) {
    try {
      return todos.firstWhere((trofeu) => trofeu.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obter troféus por raridade
  static List<TrofeuAnimal> obterPorRaridade(int raridade) {
    return todos.where((trofeu) => trofeu.raridade == raridade).toList();
  }
} 