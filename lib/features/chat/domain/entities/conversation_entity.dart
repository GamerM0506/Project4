import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final String type;
  final String title;
  final String? lastMessage;
  final DateTime updatedAt;

  const ConversationEntity({
    required this.id,
    required this.type,
    required this.title,
    this.lastMessage,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [id, type, title, lastMessage, updatedAt];
}
