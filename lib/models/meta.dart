class Meta {
  String id;
  String nome;
  TipoMeta tipo;
  double valorInicial;
  double valorDesejado;
  DateTime? prazo;
  DateTime dataCriacao;
  List<ProgressoMeta> progressos;
  bool concluida;

  Meta({
    required this.id,
    required this.nome,
    required this.tipo,
    required this.valorInicial,
    required this.valorDesejado,
    this.prazo,
    required this.dataCriacao,
    List<ProgressoMeta>? progressos,
    this.concluida = false,
  }) : progressos = progressos ?? [];

  double get percentualConclusao {
    if (valorDesejado == valorInicial) return 0.0;
    
    double diferenca = valorDesejado - valorInicial;
    double progresso = valorAtual - valorInicial;
    
    if (diferenca == 0) return 0.0;
    
    double percentual = (progresso / diferenca) * 100;
    return percentual.clamp(0.0, 100.0);
  }

  double get valorAtual {
    if (progressos.isEmpty) {
      return valorInicial;
    }
    
    // Ordenar progressos por data para garantir que o último seja o mais recente
    final progressosOrdenados = List<ProgressoMeta>.from(progressos);
    progressosOrdenados.sort((a, b) => a.data.compareTo(b.data));
    
    return progressosOrdenados.last.valor;
  }

  bool get estaConcluida {
    if (tipo == TipoMeta.peso) {
      return valorAtual <= valorDesejado;
    } else {
      return valorAtual >= valorDesejado;
    }
  }



  void adicionarProgresso(double valor, String? observacao) {
    progressos.add(ProgressoMeta(
      valor: valor,
      data: DateTime.now(),
      observacao: observacao,
    ));
    
    // Verificar se a meta foi concluída
    if (estaConcluida && !concluida) {
      concluida = true;
    }
  }

  // Método para atualizar progressos vindos do banco
  void atualizarProgressos(List<ProgressoMeta> novosProgressos) {
    progressos.clear();
    progressos.addAll(novosProgressos);
    
    // Ordenar progressos por data (mais recente primeiro)
    progressos.sort((a, b) => b.data.compareTo(a.data));
    
    // Verificar se a meta foi concluída
    if (estaConcluida && !concluida) {
      concluida = true;
    }
  }
}

enum TipoMeta {
  peso, // Aumentar ou diminuir peso
  distancia, // Correr/caminhar mais km
  repeticoes, // Fazer mais repetições
  frequencia, // Treinar mais vezes por semana
  carga, // Aumentar carga nos exercícios
  medidas, // Medidas corporais
}

extension TipoMetaExtension on TipoMeta {
  String get nome {
    switch (this) {
      case TipoMeta.peso:
        return 'Peso';
      case TipoMeta.distancia:
        return 'Distância';
      case TipoMeta.repeticoes:
        return 'Repetições';
      case TipoMeta.frequencia:
        return 'Frequência';
      case TipoMeta.carga:
        return 'Carga';
      case TipoMeta.medidas:
        return 'Medidas';
    }
  }

  String get descricao {
    switch (this) {
      case TipoMeta.peso:
        return 'Controlar peso corporal';
      case TipoMeta.distancia:
        return 'Aumentar distância percorrida';
      case TipoMeta.repeticoes:
        return 'Fazer mais repetições';
      case TipoMeta.frequencia:
        return 'Treinar mais vezes por semana';
      case TipoMeta.carga:
        return 'Aumentar carga nos exercícios';
      case TipoMeta.medidas:
        return 'Controlar medidas corporais';
    }
  }

  String get icone {
    switch (this) {
      case TipoMeta.peso:
        return '⚖️'; // Ícone alterado para balança
      case TipoMeta.distancia:
        return '🏃';
      case TipoMeta.repeticoes:
        return '💪';
      case TipoMeta.frequencia:
        return '📅';
      case TipoMeta.carga:
        return '🏋️';
      case TipoMeta.medidas:
        return '📏';
    }
  }

  bool get diminui {
    return this == TipoMeta.peso; // Peso geralmente diminui
  }

  String get unidade {
    switch (this) {
      case TipoMeta.peso:
        return 'kg';
      case TipoMeta.distancia:
        return 'km';
      case TipoMeta.repeticoes:
        return 'reps';
      case TipoMeta.frequencia:
        return 'vezes/semana';
      case TipoMeta.carga:
        return 'kg';
      case TipoMeta.medidas:
        return 'cm';
    }
  }
}

class ProgressoMeta {
  double valor;
  DateTime data;
  String? observacao;

  ProgressoMeta({
    required this.valor,
    required this.data,
    this.observacao,
  });
} 