import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'chat_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/session_token.dart';
import '../../domain/usecases/chat_usecases.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetMessagesUseCase? getMessagesUseCase;
  final SendMessageUseCase? sendMessageUseCase;
  final MarkAsReadUseCase? markAsReadUseCase;

  io.Socket? _socket;
  String? _currentUserId;

  /// true = user seat (donor/receiver); false = group admin/mod seat.
  bool _asUserSide = true;
  static const _pageSize = 50;
  bool _markReadInFlight = false;
  int _historyOffset = 0;

  ChatCubit({
    this.getMessagesUseCase,
    this.sendMessageUseCase,
    this.markAsReadUseCase,
  }) : super(const ChatState());

  bool get asUserSide => _asUserSide;
  bool get asGroup => !_asUserSide;

  Future<void> connect(String conversationId, {bool asUserSide = true}) async {
    _asUserSide = asUserSide;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken) ?? '';
    _currentUserId = resolveCurrentUserId(prefs);
    if (_currentUserId != null &&
        prefs.getString(AppConstants.keyUserId) != _currentUserId) {
      await prefs.setString(AppConstants.keyUserId, _currentUserId!);
    }

    emit(
      state.copyWith(
        activeConversationId: conversationId,
        isLoadingHistory: true,
      ),
    );
    await _loadFirstPage(conversationId, replace: true);

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
        final senderId =
            normalizeUserId(payload['sender_id']?.toString()) ?? '';
        final senderSide = payload['sender_side']?.toString();
        final msgType = payload['type']?.toString() ?? 'text';
        final existing = state.messages.cast<ChatMessage?>().firstWhere(
          (m) => sameUserId(m?.senderId, senderId),
          orElse: () => null,
        );
        final newMessage = ChatMessage(
          id: payload['id']?.toString() ?? const Uuid().v4(),
          content: payload['content']?.toString() ?? '',
          senderId: senderId,
          senderSide: senderSide,
          senderName:
              payload['sender_name']?.toString() ?? existing?.senderName,
          senderAvatar:
              payload['sender_avatar']?.toString() ?? existing?.senderAvatar,
          createdAt:
              DateTime.tryParse(payload['created_at']?.toString() ?? '') ??
              DateTime.now(),
          isMine: _isMine(
            type: msgType,
            senderSide: senderSide,
            senderId: senderId,
          ),
          type: msgType,
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
      asUserSide: _asUserSide,
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
    final result = await getMessagesUseCase!(
      conversationId,
      limit: _pageSize,
      asUserSide: _asUserSide,
    );
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
    return byId.values.map(_withOwnership).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  ChatMessage _withOwnership(ChatMessage message) {
    final isMine = _isMine(
      type: message.type,
      senderSide: message.senderSide,
      senderId: message.senderId,
    );
    if (message.isMine == isMine) return message;
    return message.copyWith(isMine: isMine);
  }

  bool _isMine({
    required String type,
    required String? senderSide,
    required String senderId,
  }) {
    if (type == 'system') return false;
    final side = (senderSide ?? '').toLowerCase().trim();
    if (side == 'group' || side == 'user') {
      // User seat: tin side=user bên phải. Group seat: tin side=group bên phải.
      return _asUserSide ? side == 'user' : side == 'group';
    }
    return sameUserId(senderId, _currentUserId);
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

    final side = asGroup ? 'group' : 'user';
    final tempMsg = ChatMessage(
      id: const Uuid().v4(),
      content: content,
      senderId: _currentUserId ?? 'me',
      senderSide: side,
      createdAt: DateTime.now(),
      isMine: true,
      type: type,
      metadata: metadata,
    );

    emit(state.copyWith(messages: List.from(state.messages)..add(tempMsg)));

    if (sendMessageUseCase != null) {
      final result = await sendMessageUseCase!(
        convId,
        content,
        type: type,
        asGroup: asGroup,
      );
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
          final owned = _withOwnership(actualMsg);
          final messages =
              state.messages
                  .where(
                    (message) =>
                        message.id != tempMsg.id && message.id != owned.id,
                  )
                  .toList()
                ..add(owned);
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          emit(state.copyWith(messages: messages));
          return owned;
        },
      );
    } else {
      final data = <String, dynamic>{
        'conversationId': convId,
        'content': content,
        'type': type,
        'asGroup': asGroup,
      };
      if (metadata != null) {
        data['metadata'] = metadata;
      }
      _socket?.emit('send_message', data);
      return null;
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
