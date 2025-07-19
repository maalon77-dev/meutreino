// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meta.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MetaAdapter extends TypeAdapter<Meta> {
  @override
  final int typeId = 0;

  @override
  Meta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meta(
      id: fields[0] as String,
      nome: fields[1] as String,
      tipo: fields[2] as TipoMeta,
      valorInicial: fields[3] as double,
      valorDesejado: fields[4] as double,
      prazo: fields[5] as DateTime?,
      dataCriacao: fields[6] as DateTime,
      progressos: (fields[7] as List?)?.cast<ProgressoMeta>(),
      concluida: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Meta obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.tipo)
      ..writeByte(3)
      ..write(obj.valorInicial)
      ..writeByte(4)
      ..write(obj.valorDesejado)
      ..writeByte(5)
      ..write(obj.prazo)
      ..writeByte(6)
      ..write(obj.dataCriacao)
      ..writeByte(7)
      ..write(obj.progressos)
      ..writeByte(8)
      ..write(obj.concluida);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProgressoMetaAdapter extends TypeAdapter<ProgressoMeta> {
  @override
  final int typeId = 2;

  @override
  ProgressoMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgressoMeta(
      valor: fields[0] as double,
      data: fields[1] as DateTime,
      observacao: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProgressoMeta obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.valor)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.observacao);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressoMetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TipoMetaAdapter extends TypeAdapter<TipoMeta> {
  @override
  final int typeId = 1;

  @override
  TipoMeta read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TipoMeta.peso;
      case 1:
        return TipoMeta.distancia;
      case 2:
        return TipoMeta.repeticoes;
      case 3:
        return TipoMeta.frequencia;
      case 4:
        return TipoMeta.carga;
      case 5:
        return TipoMeta.medidas;
      default:
        return TipoMeta.peso;
    }
  }

  @override
  void write(BinaryWriter writer, TipoMeta obj) {
    switch (obj) {
      case TipoMeta.peso:
        writer.writeByte(0);
        break;
      case TipoMeta.distancia:
        writer.writeByte(1);
        break;
      case TipoMeta.repeticoes:
        writer.writeByte(2);
        break;
      case TipoMeta.frequencia:
        writer.writeByte(3);
        break;
      case TipoMeta.carga:
        writer.writeByte(4);
        break;
      case TipoMeta.medidas:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TipoMetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
