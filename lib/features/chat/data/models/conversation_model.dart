import '../../domain/entities/conversation_entity.dart';

class ConversationModel extends ConversationEntity {
  const ConversationModel({
    required super.id,
    required super.type,
    required super.title,
    super.avatarUrl,
    super.groupId,
    super.userId,
    super.contextType,
    super.contextId,
    super.lastMessage,
    required super.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'direct',
      title: json['title']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      groupId: json['group_id']?.toString(),
      userId: json['user_id']?.toString(),
      contextType: json['context_type']?.toString(),
      contextId: json['context_id']?.toString(),
      lastMessage: (json['last_message_preview'] ?? json['last_message'])
          ?.toString(),
      updatedAt:
          DateTime.tryParse(
            (json['last_message_at'] ??
                        json['updated_at'] ??
                        json['created_at'])
                    ?.toString() ??
                '',
          ) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  ConversationModel withDisplay({required String title, String? avatarUrl}) {
    return ConversationModel(
      id: id,
      type: type,
      title: title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      groupId: groupId,
      userId: userId,
      contextType: contextType,
      contextId: contextId,
      lastMessage: lastMessage,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'avatar_url': avatarUrl,
      'group_id': groupId,
      'user_id': userId,
      'context_type': contextType,
      'context_id': contextId,
      'last_message': lastMessage,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
