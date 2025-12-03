// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ConversationHistoryAdapterAdapter
    extends TypeAdapter<ConversationHistoryAdapter> {
  @override
  final int typeId = 0;

  @override
  ConversationHistoryAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ConversationHistoryAdapter(
      id: fields[0] as String,
      videoId: fields[1] as String,
      videoTitle: fields[2] as String,
      qaHistory: (fields[3] as List).cast<QAEntryAdapter>(),
      lastUpdatedMs: fields[4] as int,
      createdAtMs: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ConversationHistoryAdapter obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.videoId)
      ..writeByte(2)
      ..write(obj.videoTitle)
      ..writeByte(3)
      ..write(obj.qaHistory)
      ..writeByte(4)
      ..write(obj.lastUpdatedMs)
      ..writeByte(5)
      ..write(obj.createdAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationHistoryAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class QAEntryAdapterAdapter extends TypeAdapter<QAEntryAdapter> {
  @override
  final int typeId = 1;

  @override
  QAEntryAdapter read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QAEntryAdapter(
      question: fields[0] as String,
      answer: fields[1] as String,
      timestampMs: fields[2] as int,
      videoPosition: fields[3] as double?,
      tokensUsed: fields[4] as int,
    );
  }

  @override
  void write(BinaryWriter writer, QAEntryAdapter obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.answer)
      ..writeByte(2)
      ..write(obj.timestampMs)
      ..writeByte(3)
      ..write(obj.videoPosition)
      ..writeByte(4)
      ..write(obj.tokensUsed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QAEntryAdapterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
