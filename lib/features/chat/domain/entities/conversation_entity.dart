import 'package:equatable/equatable.dart';

class ConversationEntity extends Equatable {
  final String id;
  final String type;
  final String title;
  final String? avatarUrl;
  final String? groupId;
  final String? userId;
  final String? contextType;
  final String? contextId;
  final String? lastMessage;
  final DateTime updatedAt;

  const ConversationEntity({
    required this.id,
    required this.type,
    required this.title,
    this.avatarUrl,
    this.groupId,
    this.userId,
    this.contextType,
    this.contextId,
    this.lastMessage,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    avatarUrl,
    groupId,
    userId,
    contextType,
    contextId,
    lastMessage,
    updatedAt,
  ];
}
