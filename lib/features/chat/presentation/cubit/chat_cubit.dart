import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_state.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/constants/app_constants.dart';
import '../../domain/usecases/chat_usecases.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetMessagesUseCase? getMessagesUseCase;
  final SendMessageUseCase? sendMessageUseCase;

  IO.Socket? _socket;
  final String baseUrl = 'http://216.108.237.20:8000'; // Port of API gateway

  ChatCubit({this.getMessagesUseCase, this.sendMessageUseCase}) : super(const ChatState());

  Future<void> connect(String conversationId) async {
    emit(state.copyWith(activeConversationId: conversationId));

    // Fetch message history immediately
    if (getMessagesUseCase != null) {
      final result = await getMessagesUseCase!(conversationId);
      result.fold(
        (l) => print('Failed to fetch messages: $l'),
        (messages) {
          emit(state.copyWith(messages: messages));
        },
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyAccessToken) ?? '';

    _socket = IO.io(baseUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setPath('/api/communication/socket.io')
      .setAuth({'token': token})
      .setExtraHeaders({'Authorization': 'Bearer $token'})
      .build()
    );

    _socket?.onConnect((_) {
      print('Socket Connected');
      emit(state.copyWith(isConnected: true, activeConversationId: conversationId));
      _socket?.emit('join_conversation', {'conversationId': conversationId});
    });

    _socket?.onDisconnect((_) {
      print('Socket Disconnected');
      emit(state.copyWith(isConnected: false));
    });

    _socket?.on('new_message', (data) {
      print('New message received: $data');
      if (data is Map<String, dynamic>) {
        if (data['metadata_updated'] == true) {
           final msgId = data['id']?.toString();
           final metadata = data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null;
           final newMessages = state.messages.map((m) {
             if (m.id == msgId) {
               return m.copyWith(metadata: metadata);
             }
             return m;
           }).toList();
           emit(state.copyWith(messages: newMessages));
           return;
        }

        final newMessage = ChatMessage(
          id: data['id']?.toString() ?? Uuid().v4(),
          content: data['content'] ?? '',
          senderId: data['sender_id']?.toString() ?? '',
          senderName: data['sender_name']?.toString(),
          senderAvatar: data['sender_avatar']?.toString(),
          createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
          isMine: false, // In reality, compare with current user ID
          type: data['type']?.toString() ?? 'text',
          metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
        );
        
        emit(state.copyWith(
          messages: List.from(state.messages)..add(newMessage),
        ));
      }
    });

    _socket?.onConnectError((err) {
      print('Socket Connect Error: $err');
      emit(state.copyWith(isConnected: false, error: 'Connection Error: $err'));
    });

    _socket?.connect();

    // Fetch message history from REST API
    if (getMessagesUseCase != null) {
      final result = await getMessagesUseCase!(conversationId);
      result.fold(
        (l) => print('Failed to fetch messages: $l'),
        (messages) {
          emit(state.copyWith(messages: messages));
        },
      );
    } else {
      // Load initial mock messages just for UI demonstration if no API
      if (state.messages.isEmpty) {
        emit(state.copyWith(messages: [
          ChatMessage(
            id: Uuid().v4(),
            content: 'Chào bạn, nhóm của chúng ta sắp có sự kiện mới nhé!',
            senderId: 'other_user',
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
            isMine: false,
          ),
        ]));
      }
    }
  }

  void sendMessage(String content, {String type = 'text', Map<String, dynamic>? metadata}) {
    if (content.trim().isEmpty && type == 'text') return;
    final convId = state.activeConversationId;
    if (convId == null) return;

    // Add to UI immediately for optimistic update
    final tempMsg = ChatMessage(
      id: Uuid().v4(),
      content: content,
      senderId: 'me',
      createdAt: DateTime.now(),
      isMine: true,
      type: type,
      metadata: metadata,
    );
    
    emit(state.copyWith(
      messages: List.from(state.messages)..add(tempMsg),
    ));

    // Send to server
    if (sendMessageUseCase != null) {
      sendMessageUseCase!.call(convId, content, type: type, metadata: metadata).then((result) {
        result.fold(
          (l) => print('Failed to send message: $l'),
          (actualMsg) {
             // Optionally update temp message with actual ID from server
          },
        );
      });
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
    }
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

  Future<void> approveDonation(ChatMessage message) async {
    final meta = message.metadata;
    if (meta == null) return;
    try {
      final dio = Dio(BaseOptions(baseUrl: baseUrl));
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.keyAccessToken) ?? '';

      // Approve in marketplace
      await dio.post(
        '/api/marketplace/inventory/approve-proposal',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
        data: {
          'message_id': message.id,
          'group_id': 'default-group', // mock for now
          'donor_id': message.senderId,
          'item': {
            'name': meta['name'],
            'description': meta['description'],
            'condition': meta['condition'],
            'category_id': meta['category_id'],
          }
        },
      );

      // And we also update the message in communication service
      final newMeta = Map<String, dynamic>.from(meta);
      newMeta['status'] = 'active'; // Approved
      final convId = state.activeConversationId;
      if (convId != null) {
        await dio.patch(
          '/api/communication/conversations/$convId/messages/${message.id}/metadata',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
          data: newMeta,
        );
      }
    } catch (e) {
      print('Approve Donation Error: $e');
    }
  }

  @override
  Future<void> close() {
    disconnect();
    return super.close();
  }
}
