import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String content;
  final String senderId;

  /// 'user' | 'group' — phía gửi theo backend (conversation user ↔ group).
  final String? senderSide;
  final String? senderName;
  final String? senderAvatar;
  final DateTime createdAt;
  final bool isMine;
  final String type; // 'text', 'image', 'system', ...
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.senderId,
    this.senderSide,
    this.senderName,
    this.senderAvatar,
    required this.createdAt,
    required this.isMine,
    this.type = 'text',
    this.metadata,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    String? senderId,
    String? senderSide,
    String? senderName,
    String? senderAvatar,
    DateTime? createdAt,
    bool? isMine,
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderSide: senderSide ?? this.senderSide,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    content,
    senderId,
    senderSide,
    senderName,
    senderAvatar,
    createdAt,
    isMine,
    type,
    metadata,
  ];
}

class ChatState extends Equatable {
  final bool isConnected;
  final List<ChatMessage> messages;
  final String? activeConversationId;
  final String? error;
  final bool isLoadingHistory;
  final bool isLoadingOlder;
  final bool hasMore;

  const ChatState({
    this.isConnected = false,
    this.messages = const [],
    this.activeConversationId,
    this.error,
    this.isLoadingHistory = false,
    this.isLoadingOlder = false,
    this.hasMore = true,
  });

  ChatState copyWith({
    bool? isConnected,
    List<ChatMessage>? messages,
    String? activeConversationId,
    String? error,
    bool? isLoadingHistory,
    bool? isLoadingOlder,
    bool? hasMore,
  }) {
    return ChatState(
      isConnected: isConnected ?? this.isConnected,
      messages: messages ?? this.messages,
      activeConversationId: activeConversationId ?? this.activeConversationId,
      error: error, // Clear error if null is not passed explicitly
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
    isConnected,
    messages,
    activeConversationId,
    error,
    isLoadingHistory,
    isLoadingOlder,
    hasMore,
  ];
}
