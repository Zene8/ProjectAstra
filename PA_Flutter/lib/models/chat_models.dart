import 'package:hive/hive.dart';

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

  ChatMessage({
    required this.type,
    required this.text,
    this.thinkingText,
    required this.timestamp,
  });
}
