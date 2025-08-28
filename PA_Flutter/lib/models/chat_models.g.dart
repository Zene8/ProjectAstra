// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageTypeAdapter extends TypeAdapter<MessageType> {
  @override
  final int typeId = 0;

  @override
  MessageType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageType.ai;
      case 1:
        return MessageType.user;
      default:
        return MessageType.ai;
    }
  }

  @override
  void write(BinaryWriter writer, MessageType obj) {
    switch (obj) {
      case MessageType.ai:
        writer.writeByte(0);
        break;
      case MessageType.user:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 1;

  @override
  ChatMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChatMessage(
      type: fields[0] as MessageType,
      text: fields[1] as String,
      thinkingText: fields[2] as String?,
      timestamp: fields[3] as DateTime,
      suggestedActions: (fields[4] as List?)?.map((e) => e as SuggestedAction).toList(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.text)
      ..writeByte(2)
      ..write(obj.thinkingText)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.suggestedActions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SuggestedActionAdapter extends TypeAdapter<SuggestedAction> {
  @override
  final int typeId = 2;

  @override
  SuggestedAction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SuggestedAction(
      type: fields[0] as String,
      description: fields[1] as String,
      payload: (fields[2] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SuggestedAction obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.description)
      ..writeByte(2)
      ..write(obj.payload);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestedActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      type: $enumDecode(_$MessageTypeEnumMap, json["type"]),
      text: json["text"] as String,
      thinkingText: json["thinkingText"] as String?,
      timestamp: DateTime.parse(json["timestamp"] as String),
      suggestedActions: (json["suggestedActions"] as List<dynamic>?)
          ?.map((e) => SuggestedAction.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      "type": _$MessageTypeEnumMap[instance.type]!,
      "text": instance.text,
      "thinkingText": instance.thinkingText,
      "timestamp": instance.timestamp.toIso8601String(),
      "suggestedActions":
          instance.suggestedActions?.map((e) => e.toJson()).toList(),
    };

const _$MessageTypeEnumMap = {
  MessageType.ai: "ai",
  MessageType.user: "user",
};

SuggestedAction _$SuggestedActionFromJson(Map<String, dynamic> json) =>
    SuggestedAction(
      type: json["type"] as String,
      description: json["description"] as String,
      payload: json["payload"] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$SuggestedActionToJson(SuggestedAction instance) =>
    <String, dynamic>{
      "type": instance.type,
      "description": instance.description,
      "payload": instance.payload,
    };