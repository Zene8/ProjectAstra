import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart'; // Import for JsonSerializable

part 'chat_models.g.dart'; // CRITICAL: This line tells Dart to include the generated code

@HiveType(typeId: 0) // Ensure unique typeId
enum MessageType {
  @HiveField(0)
  ai,
  @HiveField(1)
  user,
}

@HiveType(typeId: 1) // Ensure unique typeId, different from MessageType's
class ChatMessage {
  @HiveField(0)
  final MessageType type;
  @HiveField(1)
  final String text;
  @HiveField(2)
  final String? thinkingText;
  @HiveField(3)
  final DateTime timestamp;
  @HiveField(4) // New field for suggested actions
  final List<SuggestedAction>? suggestedActions;

  ChatMessage({
    required this.type,
    required this.text,
    this.thinkingText,
    required this.timestamp,
    this.suggestedActions,
  });
}

@HiveType(typeId: 2) // New typeId for SuggestedAction
@JsonSerializable() // Make SuggestedAction serializable
class SuggestedAction {
  @HiveField(0)
  final String type;
  @HiveField(1)
  final String description;
  @HiveField(2)
  final Map<String, dynamic>? payload;

  SuggestedAction({
    required this.type,
    required this.description,
    this.payload,
  });

  factory SuggestedAction.fromJson(Map<String, dynamic> json) =>
      _$SuggestedActionFromJson(json);
  Map<String, dynamic> toJson() => _$SuggestedActionToJson(this);
}
