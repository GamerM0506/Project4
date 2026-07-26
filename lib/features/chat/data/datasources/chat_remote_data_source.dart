import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/conversation_model.dart';
import '../../presentation/cubit/chat_state.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationModel>> getConversations({String? groupId});
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  });
  Future<ChatMessage> sendMessage(
    String conversationId,
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
  });
  Future<void> markAsRead(String conversationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ConversationModel>> getConversations({String? groupId}) async {
    final response = await apiClient.dio.get(
      '${AppConstants.chatApiBaseUrl}/conversations',
      queryParameters: groupId == null ? null : {'groupId': groupId},
    );
    final data = response.data is List
        ? response.data as List
        : (response.data['data'] as List? ?? []);
    return data
        .map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString(AppConstants.keyUserId);
    final response = await apiClient.dio.get(
      '${AppConstants.chatApiBaseUrl}/conversations/$conversationId/messages',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data is List
        ? response.data as List
        : (response.data['data'] as List? ?? []);
    final messages = data
        .map(
          (e) => ChatMessage(
            id: e['id']?.toString() ?? '',
            content: e['content']?.toString() ?? '',
            senderId: e['sender_id']?.toString() ?? '',
            senderName: e['sender_name']?.toString(),
            senderAvatar: e['sender_avatar']?.toString(),
            createdAt:
                DateTime.tryParse(e['created_at']?.toString() ?? '') ??
                DateTime.now(),
            isMine:
                currentUserId != null &&
                e['sender_id']?.toString() == currentUserId,
            type: e['type']?.toString() ?? 'text',
            metadata: e['metadata'] != null
                ? Map<String, dynamic>.from(e['metadata'])
                : null,
          ),
        )
        .toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  @override
  Future<ChatMessage> sendMessage(
    String conversationId,
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    final response = await apiClient.dio.post(
      '${AppConstants.chatApiBaseUrl}/conversations/$conversationId/messages',
      data: {'content': content, 'type': type},
    );
    final e = response.data is Map
        ? Map<String, dynamic>.from(response.data['data'] ?? response.data)
        : <String, dynamic>{};
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString(AppConstants.keyUserId) ?? '';
    return ChatMessage(
      id: e['id']?.toString() ?? '',
      content: e['content']?.toString() ?? content,
      senderId: e['sender_id']?.toString() ?? currentUserId,
      senderName: e['sender_name']?.toString(),
      senderAvatar: e['sender_avatar']?.toString(),
      createdAt:
          DateTime.tryParse(e['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isMine: true,
      type: e['type']?.toString() ?? type,
    );
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    await apiClient.dio.post(
      '${AppConstants.chatApiBaseUrl}/conversations/$conversationId/read',
    );
  }
}
