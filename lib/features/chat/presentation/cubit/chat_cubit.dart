import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'chat_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../../../donation/domain/usecases/donation_usecases.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetMessagesUseCase? getMessagesUseCase;
  final SendMessageUseCase? sendMessageUseCase;
  final MarkAsReadUseCase? markAsReadUseCase;
  final CreateDonationUseCase? createDonationUseCase;
  final AcceptDonationUseCase? acceptDonationUseCase;

  io.Socket? _socket;
  String? _currentUserId;
  static const _pageSize = 50;
  bool _markReadInFlight = false;
  int _historyOffset = 0;

  ChatCubit({
    this.getMessagesUseCase,
    this.sendMessageUseCase,
    this.markAsReadUseCase,
    this.createDonationUseCase,
    this.acceptDonationUseCase,
  }) : super(const ChatState());

  Future<void> connect(String conversationId) async {
    emit(
      state.copyWith(
        activeConversationId: conversationId,
        isLoadingHistory: true,
      ),
    );
    await _loadFirstPage(conversationId, replace: true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken) ?? '';
    _currentUserId = prefs.getString(AppConstants.keyUserId);

    _socket = io.io(
      AppConstants.socketBaseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .setPath('/api/communication/socket.io')
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
    );

    _socket?.onConnect((_) {
      emit(state.copyWith(isConnected: false));
      _socket?.emitWithAck(
        'join_conversation',
        {'conversationId': conversationId},
        ack: (response) async {
          final payload = response is Map
              ? Map<String, dynamic>.from(response)
              : const <String, dynamic>{};
          if (payload['ok'] != true) {
            emit(
              state.copyWith(
                isConnected: false,
                error:
                    payload['error']?.toString() ??
                    'Không thể tham gia cuộc trò chuyện.',
              ),
            );
            return;
          }
          emit(state.copyWith(isConnected: true));
          await _loadFirstPage(conversationId);
          _markRead();
        },
      );
    });

    _socket?.onDisconnect((_) {
      emit(state.copyWith(isConnected: false));
    });

    _socket?.on('new_message', (data) {
      if (data is Map) {
        final payload = Map<String, dynamic>.from(data);
        final senderId = payload['sender_id']?.toString() ?? '';
        final existing = state.messages.cast<ChatMessage?>().firstWhere(
          (m) => m?.senderId == senderId,
          orElse: () => null,
        );
        final newMessage = ChatMessage(
          id: payload['id']?.toString() ?? const Uuid().v4(),
          content: payload['content']?.toString() ?? '',
          senderId: senderId,
          senderName:
              payload['sender_name']?.toString() ?? existing?.senderName,
          senderAvatar:
              payload['sender_avatar']?.toString() ?? existing?.senderAvatar,
          createdAt:
              DateTime.tryParse(payload['created_at']?.toString() ?? '') ??
              DateTime.now(),
          isMine: senderId == _currentUserId,
          type: payload['type']?.toString() ?? 'text',
          metadata: payload['metadata'] != null
              ? Map<String, dynamic>.from(payload['metadata'])
              : null,
        );

        if (!state.messages.any((message) => message.id == newMessage.id)) {
          final messages = List<ChatMessage>.from(state.messages)
            ..add(newMessage)
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
          emit(state.copyWith(messages: messages));
          if (!newMessage.isMine) _markRead();
        }
      }
    });

    _socket?.onConnectError((err) {
      emit(state.copyWith(isConnected: false, error: 'Connection Error: $err'));
    });

    _socket?.connect();
  }

  Future<void> loadOlderMessages() async {
    final conversationId = state.activeConversationId;
    if (conversationId == null ||
        state.isLoadingOlder ||
        state.isLoadingHistory ||
        !state.hasMore ||
        getMessagesUseCase == null) {
      return;
    }
    emit(state.copyWith(isLoadingOlder: true));
    final result = await getMessagesUseCase!(
      conversationId,
      limit: _pageSize,
      offset: _historyOffset,
    );
    result.fold(
      (failure) => emit(state.copyWith(isLoadingOlder: false, error: failure)),
      (messages) {
        _historyOffset += messages.length;
        emit(
          state.copyWith(
            messages: _mergeMessages(state.messages, messages),
            isLoadingOlder: false,
            hasMore: messages.length == _pageSize,
          ),
        );
      },
    );
  }

  Future<void> _loadFirstPage(
    String conversationId, {
    bool replace = false,
  }) async {
    if (getMessagesUseCase == null) {
      emit(state.copyWith(isLoadingHistory: false));
      return;
    }
    final result = await getMessagesUseCase!(conversationId, limit: _pageSize);
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoadingHistory: false, error: failure)),
      (messages) {
        if (replace) _historyOffset = messages.length;
        emit(
          state.copyWith(
            messages: replace
                ? _mergeMessages(const [], messages)
                : _mergeMessages(state.messages, messages),
            isLoadingHistory: false,
            hasMore: messages.length == _pageSize,
          ),
        );
        _markRead();
      },
    );
  }

  List<ChatMessage> _mergeMessages(
    List<ChatMessage> current,
    List<ChatMessage> incoming,
  ) {
    final byId = {for (final message in current) message.id: message};
    for (final message in incoming) {
      byId[message.id] = message;
    }
    return byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> _markRead() async {
    final conversationId = state.activeConversationId;
    if (conversationId == null ||
        markAsReadUseCase == null ||
        _markReadInFlight) {
      return;
    }
    _markReadInFlight = true;
    await markAsReadUseCase!(conversationId);
    _markReadInFlight = false;
  }

  Future<ChatMessage?> sendMessage(
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    if (content.trim().isEmpty && type == 'text') return null;
    final convId = state.activeConversationId;
    if (convId == null) return null;

    final tempMsg = ChatMessage(
      id: const Uuid().v4(),
      content: content,
      senderId: 'me',
      createdAt: DateTime.now(),
      isMine: true,
      type: type,
      metadata: metadata,
    );

    emit(state.copyWith(messages: List.from(state.messages)..add(tempMsg)));

    if (sendMessageUseCase != null) {
      final result = await sendMessageUseCase!(convId, content, type: type);
      return result.fold(
        (failure) {
          emit(
            state.copyWith(
              messages: state.messages
                  .where((message) => message.id != tempMsg.id)
                  .toList(),
              error: failure,
            ),
          );
          return null;
        },
        (actualMsg) {
          final messages =
              state.messages
                  .where(
                    (message) =>
                        message.id != tempMsg.id && message.id != actualMsg.id,
                  )
                  .toList()
                ..add(actualMsg);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          emit(state.copyWith(messages: messages));
          return actualMsg;
        },
      );
    } else {
      final data = <String, dynamic>{
        'conversationId': convId,
        'content': content,
        'type': type,
      };
      if (metadata != null) {
        data['metadata'] = metadata;
      }
      _socket?.emit('send_message', data);
      return null;
    }
  }

  /// Donor: create donation via donation-service, then post proposal card in chat.
  Future<void> submitDonationProposal({
    required String groupId,
    required String title,
    required String description,
    required int quantity,
    String condition = 'used',
    String? categoryId,
  }) async {
    if (createDonationUseCase == null) {
      emit(state.copyWith(error: 'Donation service chưa được cấu hình'));
      return;
    }

    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (!uuidRegex.hasMatch(groupId)) {
      emit(
        state.copyWith(
          error: 'Group ID không hợp lệ. Mở chat từ nhóm (cần UUID nhóm).',
        ),
      );
      return;
    }

    final conditionMapped = _mapCondition(condition);
    final item = <String, dynamic>{
      'name': title,
      'quantity': quantity < 1 ? 1 : quantity,
      'condition_declared': conditionMapped,
      'images': <Map<String, dynamic>>[],
    };
    if (categoryId != null && uuidRegex.hasMatch(categoryId)) {
      item['category_id'] = categoryId;
    }

    final result = await createDonationUseCase!(
      groupId: groupId,
      title: title,
      description: description.isEmpty ? null : description,
      items: [item],
    );

    await result.fold(
      (err) async {
        emit(state.copyWith(error: err));
      },
      (donation) async {
        await sendMessage('Tôi muốn quyên góp: $title (Mã: ${donation.code})');
      },
    );
  }

  String _mapCondition(String raw) {
    final v = raw.toLowerCase().trim();
    const allowed = {'new', 'like_new', 'good', 'used', 'worn'};
    if (allowed.contains(v)) return v;
    switch (v) {
      case 'like new':
      case 'likenew':
        return 'like_new';
      case 'excellent':
        return 'like_new';
      case 'fair':
      case 'acceptable':
        return 'used';
      default:
        return 'used';
    }
  }

  void clearError() {
    emit(state.copyWith(error: null));
  }

  void setError(String error) {
    emit(state.copyWith(error: error));
  }

  void disconnect() {
    final convId = state.activeConversationId;
    if (convId != null) {
      _socket?.emit('leave_conversation', {'conversationId': convId});
    }
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    emit(const ChatState(isConnected: false));
  }

  @override
  Future<void> close() {
    disconnect();
    return super.close();
  }
}
