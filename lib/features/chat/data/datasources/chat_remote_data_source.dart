import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/session_token.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/conversation_model.dart';
import '../../presentation/cubit/chat_state.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationModel>> getConversations({String? groupId});
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,

    /// true = đang xem với tư cách user seat; false = admin/mod phía group.
    bool asUserSide = true,
  });
  Future<ChatMessage> sendMessage(
    String conversationId,
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
    bool asGroup = false,
  });
  Future<void> markAsRead(String conversationId);
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final ApiClient apiClient;

  final Map<String, Future<({String name, String? avatarUrl})>> _profileCache =
      {};
  final Map<String, Future<({String name, String? avatarUrl})>> _groupCache =
      {};

  ChatRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ConversationModel>> getConversations({String? groupId}) async {
    Set<String> managedGroupIds = {};
    String? currentUserId;

    if (groupId == null) {
      currentUserId = _currentUserId();
      try {
        final groupsResponse = await apiClient.dio.get(
          '${AppConstants.communityApiBaseUrl}/groups/me',
          queryParameters: {'limit': 100, 'member_status': 'approved'},
        );
        final items = groupsResponse.data['data']['items'] as List;
        managedGroupIds = items
            .map((e) => e['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
      } catch (_) {}
    }

    final response = await apiClient.dio.get(
      '${AppConstants.chatApiBaseUrl}/conversations',
      queryParameters: {
        if (groupId != null)
          'groupId': groupId
        else if (managedGroupIds.isNotEmpty)
          'groupIds': managedGroupIds.join(','),
      },
    );
    final data = response.data is List
        ? response.data as List
        : (response.data['data'] as List? ?? []);
    var conversations = data
        .map((e) => ConversationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    if (groupId == null) {
      conversations = conversations
          .where(
            (conversation) =>
                conversation.groupId != null &&
                managedGroupIds.contains(conversation.groupId),
          )
          .toList();
    }

    if (conversations.isEmpty) return [];

    if (groupId != null) {
      final userIds = conversations
          .map((c) => c.userId)
          .whereType<String>()
          .toSet();
      final profileMap = await _publicProfileBatch(userIds);
      return conversations
          .map(
            (c) => c.withDisplay(
              title: profileMap[c.userId]?.name ?? 'Người dùng',
              avatarUrl: profileMap[c.userId]?.avatarUrl,
            ),
          )
          .toList();
    }

    final userSideConv = conversations
        .where((c) => sameUserId(c.userId, currentUserId))
        .toList();
    final groupSideConv = conversations
        .where((c) => !sameUserId(c.userId, currentUserId))
        .toList();

    final groupIdsForGroups = userSideConv
        .map((c) => c.groupId)
        .whereType<String>()
        .toSet();
    final groupMap = await _publicGroupBatch(groupIdsForGroups);

    final userIdsForUsers = groupSideConv
        .map((c) => c.userId)
        .whereType<String>()
        .toSet();
    final profileMap = await _publicProfileBatch(userIdsForUsers);

    return conversations.map((c) {
      if (sameUserId(c.userId, currentUserId)) {
        return c.withDisplay(
          title: groupMap[c.groupId]?.name ?? 'Hội nhóm',
          avatarUrl: groupMap[c.groupId]?.avatarUrl,
        );
      }
      final peerId = normalizeUserId(c.userId);
      return c.withDisplay(
        title:
            (peerId != null ? profileMap[peerId]?.name : null) ?? 'Người dùng',
        avatarUrl: peerId != null ? profileMap[peerId]?.avatarUrl : null,
      );
    }).toList();
  }

  Future<Map<String, ({String name, String? avatarUrl})>> _publicProfileBatch(
    Iterable<String> userIds,
  ) async {
    final ids = userIds
        .map(normalizeUserId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();
    if (ids.isEmpty) return {};

    final result = <String, ({String name, String? avatarUrl})>{};
    final uncached = <String>[];
    for (final id in ids) {
      final cached = _profileCache[id];
      if (cached != null) {
        result[id] = await cached;
      } else {
        uncached.add(id);
      }
    }
    if (uncached.isEmpty) return result;

    try {
      final response = await apiClient.dio.get(
        '${AppConstants.authApiBaseUrl}/profile/batch',
        queryParameters: {'ids': uncached.join(',')},
      );
      final envelope = Map<String, dynamic>.from(response.data as Map);
      final list = envelope['data'] as List? ?? [];
      for (final item in list) {
        final m = Map<String, dynamic>.from(item as Map);
        final id = normalizeUserId(m['id']?.toString()) ?? '';
        if (id.isEmpty) continue;
        final fullName = m['full_name']?.toString().trim();
        final username = m['username']?.toString().trim();
        final profile = (
          name: fullName?.isNotEmpty == true
              ? fullName!
              : (username?.isNotEmpty == true ? username! : 'Người dùng'),
          avatarUrl: m['avatar_url']?.toString(),
        );
        _profileCache[id] = Future.value(profile);
        result[id] = profile;
      }
      for (final id in uncached) {
        final key = normalizeUserId(id) ?? id;
        if (!result.containsKey(key)) {
          final fallback = (name: 'Người dùng', avatarUrl: null);
          _profileCache[key] = Future.value(fallback);
          result[key] = fallback;
        }
      }
    } catch (_) {
      for (final id in uncached) {
        result[id] = (name: 'Người dùng', avatarUrl: null);
      }
    }
    return result;
  }

  Future<Map<String, ({String name, String? avatarUrl})>> _publicGroupBatch(
    Iterable<String> groupIds,
  ) async {
    final ids = groupIds.where((id) => id.isNotEmpty).toSet();
    if (ids.isEmpty) return {};

    final result = <String, ({String name, String? avatarUrl})>{};
    final uncached = <String>[];
    for (final id in ids) {
      final cached = _groupCache[id];
      if (cached != null) {
        result[id] = await cached;
      } else {
        uncached.add(id);
      }
    }
    if (uncached.isEmpty) return result;

    try {
      final response = await apiClient.dio.get(
        '${AppConstants.communityApiBaseUrl}/groups/batch',
        queryParameters: {'ids': uncached.join(',')},
      );
      final envelope = Map<String, dynamic>.from(response.data as Map);
      final list = envelope['data'] as List? ?? [];
      for (final item in list) {
        final m = Map<String, dynamic>.from(item as Map);
        final id = m['id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final name = m['name']?.toString().trim();
        final profile = (
          name: name?.isNotEmpty == true ? name! : 'Hội nhóm',
          avatarUrl: m['avatar_url']?.toString(),
        );
        _groupCache[id] = Future.value(profile);
        result[id] = profile;
      }
      for (final id in uncached) {
        if (!result.containsKey(id)) {
          final fallback = (name: 'Hội nhóm', avatarUrl: null);
          _groupCache[id] = Future.value(fallback);
          result[id] = fallback;
        }
      }
    } catch (_) {
      for (final id in uncached) {
        result[id] = (name: 'Hội nhóm', avatarUrl: null);
      }
    }
    return result;
  }

  SharedPreferences get _prefs => apiClient.sharedPreferences;

  String? _currentUserId() => resolveCurrentUserId(_prefs);

  /// Tin "của mình" theo phía đang xem: user seat ↔ group seat.
  static bool isMessageMine({
    required String type,
    required String? senderSide,
    required String senderId,
    required String? currentUserId,
    required bool asUserSide,
  }) {
    if (type == 'system') return false;
    final side = (senderSide ?? '').toLowerCase().trim();
    if (side == 'group' || side == 'user') {
      return asUserSide ? side == 'user' : side == 'group';
    }
    // Fallback cũ nếu backend thiếu sender_side
    return sameUserId(senderId, currentUserId);
  }

  @override
  Future<List<ChatMessage>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
    bool asUserSide = true,
  }) async {
    final currentUserId = _currentUserId();
    final response = await apiClient.dio.get(
      '${AppConstants.chatApiBaseUrl}/conversations/$conversationId/messages',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    final data = response.data is List
        ? response.data as List
        : (response.data['data'] as List? ?? []);
    final rawMessages = data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final senderIds = rawMessages
        .map((e) => normalizeUserId(e['sender_id']?.toString()) ?? '')
        .where((id) => id.isNotEmpty && !sameUserId(id, currentUserId))
        .toSet();
    final profileMap = await _publicProfileBatch(senderIds);

    final messages = rawMessages.map((e) {
      final senderId = normalizeUserId(e['sender_id']?.toString()) ?? '';
      final senderSide = e['sender_side']?.toString();
      final profile = profileMap[senderId];
      final type = e['type']?.toString() ?? 'text';
      return ChatMessage(
        id: e['id']?.toString() ?? '',
        content: e['content']?.toString() ?? '',
        senderId: senderId,
        senderSide: senderSide,
        senderName: profile?.name,
        senderAvatar: profile?.avatarUrl,
        createdAt:
            DateTime.tryParse(e['created_at']?.toString() ?? '') ??
            DateTime.now(),
        isMine: isMessageMine(
          type: type,
          senderSide: senderSide,
          senderId: senderId,
          currentUserId: currentUserId,
          asUserSide: asUserSide,
        ),
        type: type,
        metadata: e['metadata'] != null
            ? Map<String, dynamic>.from(e['metadata'] as Map)
            : null,
      );
    }).toList();
    messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return messages;
  }

  @override
  Future<ChatMessage> sendMessage(
    String conversationId,
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
    bool asGroup = false,
  }) async {
    final response = await apiClient.dio.post(
      '${AppConstants.chatApiBaseUrl}/conversations/$conversationId/messages',
      data: {'content': content, 'type': type, 'asGroup': asGroup},
    );
    final e = response.data is Map
        ? Map<String, dynamic>.from(response.data['data'] ?? response.data)
        : <String, dynamic>{};
    final currentUserId = _currentUserId() ?? '';
    final senderId =
        normalizeUserId(e['sender_id']?.toString()) ?? currentUserId;
    final senderSide =
        e['sender_side']?.toString() ?? (asGroup ? 'group' : 'user');
    final msgType = e['type']?.toString() ?? type;
    return ChatMessage(
      id: e['id']?.toString() ?? '',
      content: e['content']?.toString() ?? content,
      senderId: senderId,
      senderSide: senderSide,
      senderName: e['sender_name']?.toString(),
      senderAvatar: e['sender_avatar']?.toString(),
      createdAt:
          DateTime.tryParse(e['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isMine: isMessageMine(
        type: msgType,
        senderSide: senderSide,
        senderId: senderId,
        currentUserId: currentUserId,
        asUserSide: !asGroup,
      ),
      type: msgType,
    );
  }

  @override
  Future<void> markAsRead(String conversationId) async {
    await apiClient.dio.post(
      '${AppConstants.chatApiBaseUrl}/conversations/$conversationId/read',
    );
  }
}
