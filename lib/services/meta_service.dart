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
            final progressos = <ProgressoMeta>[];
            if (metaData['progressos'] != null) {
              print('📊 Progressos encontrados para meta ${metaData['nome']}: ${metaData['progressos'].length}');
              for (var progressoData in metaData['progressos']) {
                final progresso = ProgressoMeta(
                  valor: double.parse(progressoData['valor'].toString()),
                  data: DateTime.parse(progressoData['data_progresso']),
                  observacao: progressoData['observacao'],
                );
                progressos.add(progresso);
              }
            }
            meta.progressos = progressos;
            // Corrigir status de conclusão
            meta.concluida = meta.estaConcluida;
            metas.add(meta);
          }
          
          print('✅ Metas carregadas online: ${metas.length} encontradas');
          return metas;
        } else {
          throw Exception(data['erro'] ?? 'Erro desconhecido');
        }
      } else {
        throw Exception('Erro HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao carregar metas: $e');
      rethrow;
    }
  }

  // Obter meta por ID
  Future<Meta?> obterMetaPorId(String id, int usuarioId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?acao=obter_meta&meta_id=$id&usuario_id=$usuarioId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucesso'] == true && data['meta'] != null) {
          final metaData = data['meta'];
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
          final progressos = <ProgressoMeta>[];
          if (metaData['progressos'] != null) {
            for (var progressoData in metaData['progressos']) {
              final progresso = ProgressoMeta(
                valor: double.parse(progressoData['valor'].toString()),
                data: DateTime.parse(progressoData['data_progresso']),
                observacao: progressoData['observacao'],
              );
              progressos.add(progresso);
            }
          }
          meta.progressos = progressos;
          
          return meta;
        }
      }
      return null;
    } catch (e) {
      print('❌ Erro ao obter meta por ID: $e');
      return null;
    }
  }

  // Adicionar progresso
  Future<void> adicionarProgresso(
    String metaId,
    double valor,
    String? observacao, {
    required int usuarioId,
  }) async {
    try {
      print('📊 Adicionando progresso para meta: $metaId - Valor: $valor');
      
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
          print('✅ Progresso salvo online: $valor');
          
          // Verificar se a meta foi concluída
          await _verificarConclusao(metaId, usuarioId);
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

  // Verificar se a meta foi concluída
  Future<void> _verificarConclusao(String metaId, int usuarioId) async {
    try {
      // Obter a meta atualizada
      final meta = await obterMetaPorId(metaId, usuarioId);
      if (meta != null && meta.estaConcluida && !meta.concluida) {
        // Marcar como concluída
        await marcarComoConcluida(metaId);
        print('🎉 Meta concluída: ${meta.nome}');
      }
    } catch (e) {
      print('❌ Erro ao verificar conclusão: $e');
    }
  }

  // Excluir meta
  Future<void> excluirMeta(String id) async {
    try {
      print('🗑️ Tentando excluir meta: $id');
      
      // Usar POST em vez de DELETE para maior compatibilidade
      final response = await http.post(
        Uri.parse('$_baseUrl?acao=excluir_meta'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'meta_id': id,
        }),
      );

      print('📡 Status da resposta: ${response.statusCode}');
      print('📄 Corpo da resposta: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['sucesso'] == true) {
          print('✅ Meta excluída online: $id');
        } else {
          final erro = data['erro'] ?? 'Erro desconhecido';
          print('❌ Erro na resposta: $erro');
          throw Exception(erro);
        }
      } else {
        print('❌ Erro HTTP: ${response.statusCode}');
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