import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/meta.dart';

class MetaService {
  static const String _baseUrl = 'https://airfit.online/api/metas.php';
  final _uuid = Uuid();

  // Inicializar (mantido para compatibilidade)
  Future<void> initialize() async {
    // Não precisa mais inicializar Hive
    print('🌐 MetaService inicializado - usando API online');
  }

  // Criar nova meta
  Future<Meta> criarMeta({
    required String nome,
    required TipoMeta tipo,
    required double valorInicial,
    required double valorDesejado,
    DateTime? prazo,
    required int usuarioId,
  }) async {
    try {
      final meta = Meta(
        id: _uuid.v4(),
        nome: nome,
        tipo: tipo,
        valorInicial: valorInicial,
        valorDesejado: valorDesejado,
        prazo: prazo,
        dataCriacao: DateTime.now(),
      );

      final response = await http.post(
        Uri.parse('$_baseUrl?acao=criar_meta'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'id': meta.id,
          'usuario_id': usuarioId,
          'nome': meta.nome,
          'tipo': meta.tipo.name,
          'valor_inicial': meta.valorInicial,
          'valor_desejado': meta.valorDesejado,
          'prazo': meta.prazo?.toIso8601String().split('T')[0],
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucesso'] == true) {
          print('✅ Meta salva online: ${meta.nome} (ID: ${meta.id})');
          return meta;
        } else {
          throw Exception(data['erro'] ?? 'Erro desconhecido');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao criar meta: $e');
      rethrow;
    }
  }

  // Obter todas as metas
  Future<List<Meta>> obterTodasMetas(int usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?acao=listar_metas&usuario_id=$usuarioId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucesso'] == true) {
          final metas = <Meta>[];
          for (var metaData in data['metas']) {
            final meta = Meta(
              id: metaData['id'],
              nome: metaData['nome'],
              tipo: TipoMeta.values.firstWhere((e) => e.name == metaData['tipo']),
              valorInicial: double.parse(metaData['valor_inicial'].toString()),
              valorDesejado: double.parse(metaData['valor_desejado'].toString()),
              prazo: metaData['prazo'] != null ? DateTime.parse(metaData['prazo']) : null,
              dataCriacao: DateTime.parse(metaData['data_criacao']),
              concluida: metaData['concluida'] == 1,
            );

            // Adicionar progressos
            if (metaData['progressos'] != null) {
              for (var progressoData in metaData['progressos']) {
                meta.adicionarProgresso(
                  double.parse(progressoData['valor'].toString()),
                  progressoData['observacao'],
                );
              }
            }

            metas.add(meta);
          }

          print('📋 Metas carregadas online: ${metas.length} encontradas');
          for (var meta in metas) {
            print('  - ${meta.nome} (${meta.tipo.nome}) - ${meta.concluida ? "Concluída" : "Ativa"}');
          }
          return metas;
        } else {
          throw Exception(data['erro'] ?? 'Erro desconhecido');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao carregar metas: $e');
      return [];
    }
  }

  // Obter metas ativas (não concluídas)
  Future<List<Meta>> obterMetasAtivas(int usuarioId) async {
    final todas = await obterTodasMetas(usuarioId);
    return todas.where((meta) => !meta.concluida).toList();
  }

  // Obter metas concluídas
  Future<List<Meta>> obterMetasConcluidas(int usuarioId) async {
    final todas = await obterTodasMetas(usuarioId);
    return todas.where((meta) => meta.concluida).toList();
  }

  // Obter meta por ID
  Future<Meta?> obterMetaPorId(String id, int usuarioId) async {
    final todas = await obterTodasMetas(usuarioId);
    try {
      return todas.firstWhere((meta) => meta.id == id);
    } catch (e) {
      return null;
    }
  }

  // Atualizar meta
  Future<void> atualizarMeta(Meta meta, int usuarioId) async {
    // Para atualizar uma meta, precisamos recriar ela
    // Isso é uma limitação da API atual
    print('⚠️ Atualização de meta não implementada na API');
  }

  // Adicionar progresso a uma meta
  Future<void> adicionarProgresso(String metaId, double valor, String? observacao) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?acao=atualizar_progresso'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'meta_id': metaId,
          'valor': valor,
          'observacao': observacao,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucesso'] == true) {
          print('✅ Progresso salvo online: Meta $metaId - Valor: $valor');
        } else {
          throw Exception(data['erro'] ?? 'Erro desconhecido');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao salvar progresso: $e');
      rethrow;
    }
  }

  // Excluir meta
  Future<void> excluirMeta(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl?acao=excluir_meta&meta_id=$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucesso'] == true) {
          print('✅ Meta excluída online: $id');
        } else {
          throw Exception(data['erro'] ?? 'Erro desconhecido');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao excluir meta: $e');
      rethrow;
    }
  }

  // Marcar meta como concluída
  Future<void> marcarComoConcluida(String id, {bool concluida = true}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?acao=marcar_concluida'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'meta_id': id,
          'concluida': concluida,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucesso'] == true) {
          print('✅ Status da meta atualizado online: $id - Concluída: $concluida');
        } else {
          throw Exception(data['erro'] ?? 'Erro desconhecido');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao marcar meta como concluída: $e');
      rethrow;
    }
  }

  // Obter estatísticas
  Future<Map<String, dynamic>> obterEstatisticas(int usuarioId) async {
    final todas = await obterTodasMetas(usuarioId);
    final ativas = todas.where((meta) => !meta.concluida).toList();
    final concluidas = todas.where((meta) => meta.concluida).toList();

    return {
      'total': todas.length,
      'ativas': ativas.length,
      'concluidas': concluidas.length,
      'percentualConclusao': todas.isEmpty ? 0.0 : (concluidas.length / todas.length) * 100,
    };
  }

  // Fechar conexão (mantido para compatibilidade)
  Future<void> dispose() async {
    // Não precisa mais fechar Hive
    print('🔌 MetaService finalizado');
  }
}

// Singleton para o serviço
final metaService = MetaService(); 