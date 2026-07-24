import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/conversation_model.dart';
import '../../presentation/cubit/chat_state.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationModel>> getConversations();
  Future<List<ChatMessage>> getMessages(String conversationId);
  Future<ChatMessage> sendMessage(String conversationId, String content, {String type = 'text', Map<String, dynamic>? metadata});
  Future<void> markAsRead(String conversationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  static const String _keyLocalConversations = 'LOCAL_CHAT_CONVERSATIONS';
  static const String _keyLocalMessagesPrefix = 'LOCAL_CHAT_MESSAGES_';

  ChatRemoteDataSourceImpl({required this.apiClient});

  static Future<void> saveLocalConversation({
    required String id,
    required String title,
    String type = 'group',
    String? lastMessage,
    ApiClient? client,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyLocalConversations);
      List<dynamic> list = raw != null ? jsonDecode(raw) : [];
      String existingLastMsg = 'Bắt đầu trò chuyện & quyên góp...';
      final existingIndex = list.indexWhere((item) => item['id'] == id);
      if (existingIndex != -1) {
        existingLastMsg = list[existingIndex]['last_message'] ?? existingLastMsg;
        list.removeAt(existingIndex);
      }

      list.insert(0, {
        'id': id,
        'title': title,
        'type': type,
        'last_message': lastMessage ?? existingLastMsg,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await prefs.setString(_keyLocalConversations, jsonEncode(list));

      if (client != null) {
        try {
          await client.dio.post(
            '${AppConstants.chatApiBaseUrl}/conversations',
            data: {
              'id': id,
              'title': title,
              'type': type,
            },
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  Future<List<ConversationModel>> getConversations() async {
    List<ConversationModel> remoteList = [];
    try {
      final response = await apiClient.dio.get('${AppConstants.chatApiBaseUrl}/conversations');
      final data = response.data is List ? response.data as List : (response.data['data'] as List? ?? []);
      remoteList = data.map((e) => ConversationModel.fromJson(e)).toList();
    } catch (_) {}

    List<ConversationModel> localList = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyLocalConversations);
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        localList = decoded.map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e))).toList();
      }
    } catch (_) {}

    final Map<String, ConversationModel> map = {};
    for (var c in localList) {
      map[c.id] = c;
    }
    for (var c in remoteList) {
      map[c.id] = c;
    }

    final merged = map.values.toList();
    merged.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return merged;
  }

  @override
  Future<List<ChatMessage>> getMessages(String conversationId) async {
    List<ChatMessage> remoteMessages = [];
    try {
      final response = await apiClient.dio.get('${AppConstants.chatApiBaseUrl}/conversations/$conversationId/messages');
      final data = response.data is List ? response.data as List : (response.data['data'] as List? ?? []);
      remoteMessages = data.map((e) => ChatMessage(
        id: e['id']?.toString() ?? '',
        content: e['content']?.toString() ?? '',
        senderId: e['sender_id']?.toString() ?? '',
        senderName: e['sender_name']?.toString(),
        senderAvatar: e['sender_avatar']?.toString(),
        createdAt: DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now(),
        isMine: false,
        type: e['type']?.toString() ?? 'text',
        metadata: e['metadata'] != null ? Map<String, dynamic>.from(e['metadata']) : null,
      )).toList();
    } catch (_) {}

    List<ChatMessage> localMessages = [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_keyLocalMessagesPrefix$conversationId');
      if (raw != null) {
        final List decoded = jsonDecode(raw);
        localMessages = decoded.map((e) => ChatMessage(
          id: e['id']?.toString() ?? '',
          content: e['content']?.toString() ?? '',
          senderId: e['sender_id']?.toString() ?? 'user',
          senderName: e['sender_name']?.toString() ?? 'Bạn',
          senderAvatar: e['sender_avatar']?.toString(),
          createdAt: DateTime.tryParse(e['created_at']?.toString() ?? '') ?? DateTime.now(),
          isMine: e['is_mine'] == true || e['sender_id'] == 'user',
          type: e['type']?.toString() ?? 'text',
          metadata: e['metadata'] != null ? Map<String, dynamic>.from(e['metadata']) : null,
        )).toList();
      }
    } catch (_) {}

    final Map<String, ChatMessage> map = {};
    for (var m in localMessages) {
      final key = m.id.isNotEmpty ? m.id : 'local_${m.createdAt.millisecondsSinceEpoch}_${m.content.hashCode}';
      map[key] = m;
    }
    for (var m in remoteMessages) {
      final key = m.id.isNotEmpty ? m.id : 'remote_${m.createdAt.millisecondsSinceEpoch}_${m.content.hashCode}';
      map[key] = m;
    }

    final merged = map.values.toList();
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  @override
  Future<ChatMessage> sendMessage(String conversationId, String content, {String type = 'text', Map<String, dynamic>? metadata}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Update conversation last message
    final rawConv = prefs.getString(_keyLocalConversations);
    if (rawConv != null) {
      try {
        List<dynamic> list = jsonDecode(rawConv);
        for (var item in list) {
          if (item['id'] == conversationId) {
            item['last_message'] = content;
            item['updated_at'] = DateTime.now().toIso8601String();
            break;
          }
        }
        await prefs.setString(_keyLocalConversations, jsonEncode(list));
      } catch (_) {}
    }

    // 2. Save message locally
    final createdMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      senderId: 'user',
      senderName: 'Bạn',
      createdAt: DateTime.now(),
      isMine: true,
      type: type,
      metadata: metadata,
    );

    try {
      final msgKey = '$_keyLocalMessagesPrefix$conversationId';
      final rawMsgs = prefs.getString(msgKey);
      List<dynamic> msgList = rawMsgs != null ? jsonDecode(rawMsgs) : [];
      msgList.add({
        'id': createdMsg.id,
        'content': createdMsg.content,
        'sender_id': createdMsg.senderId,
        'sender_name': createdMsg.senderName,
        'created_at': createdMsg.createdAt.toIso8601String(),
        'is_mine': true,
        'type': createdMsg.type,
        'metadata': createdMsg.metadata,
      });
      await prefs.setString(msgKey, jsonEncode(msgList));
    } catch (_) {}

    // 3. Post to backend REST API
    try {
      final dataBody = <String, dynamic>{
        'content': content,
        'type': type,
      };
      if (metadata != null) {
        dataBody['metadata'] = metadata;
      }

      final response = await apiClient.dio.post(
        '${AppConstants.chatApiBaseUrl}/conversations/$conversationId/messages',
        data: dataBody,
      );
      final e = response.data is Map ? (response.data['data'] ?? response.data) : {};
      if (e['id'] != null) {
        return createdMsg.copyWith(id: e['id'].toString());
      }
    } catch (_) {}

    return createdMsg;
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    try {
      await apiClient.dio.post('${AppConstants.chatApiBaseUrl}/conversations/$conversationId/read');
    } catch (_) {}
  }
}
