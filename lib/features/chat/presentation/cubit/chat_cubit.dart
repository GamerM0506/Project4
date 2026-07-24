import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'chat_state.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/usecases/chat_usecases.dart';
import '../../../donation/domain/usecases/donation_usecases.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetMessagesUseCase? getMessagesUseCase;
  final SendMessageUseCase? sendMessageUseCase;
  final CreateDonationUseCase? createDonationUseCase;
  final AcceptDonationUseCase? acceptDonationUseCase;
  final ApiClient? apiClient;

  IO.Socket? _socket;
  final String baseUrl = 'http://${AppConstants.apiHost}:8000';

  ChatCubit({
    this.getMessagesUseCase,
    this.sendMessageUseCase,
    this.createDonationUseCase,
    this.acceptDonationUseCase,
    this.apiClient,
  }) : super(const ChatState());

  Future<void> connect(String conversationId) async {
    emit(state.copyWith(activeConversationId: conversationId));

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

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setPath('/api/communication/socket.io')
          .setAuth({'token': token})
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .build(),
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
          final metadata =
              data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null;
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
          id: data['id']?.toString() ?? const Uuid().v4(),
          content: data['content'] ?? '',
          senderId: data['sender_id']?.toString() ?? '',
          senderName: data['sender_name']?.toString(),
          senderAvatar: data['sender_avatar']?.toString(),
          createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
          isMine: false,
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
  }

  void sendMessage(String content, {String type = 'text', Map<String, dynamic>? metadata}) {
    if (content.trim().isEmpty && type == 'text') return;
    final convId = state.activeConversationId;
    if (convId == null) return;

    final tempMsg = ChatMessage(
      id: const Uuid().v4(),
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

    if (sendMessageUseCase != null) {
      sendMessageUseCase!.call(convId, content, type: type, metadata: metadata).then((result) {
        result.fold(
          (l) => print('Failed to send message: $l'),
          (actualMsg) {},
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
      emit(state.copyWith(
        error: 'Group ID không hợp lệ. Mở chat từ nhóm (cần UUID nhóm).',
      ));
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
        sendMessage(
          'Tôi muốn quyên góp: $title',
          type: 'donation_proposal',
          metadata: {
            'donation_id': donation.id,
            'donation_code': donation.code,
            'group_id': donation.groupId,
            'name': title,
            'description': description,
            'condition': conditionMapped,
            'quantity': quantity,
            if (categoryId != null) 'category_id': categoryId,
            'status': donation.status,
          },
        );
      },
    );
  }

  /// Moderator: review + check items → inventory, then update chat metadata.
  Future<void> approveDonation(ChatMessage message) async {
    final meta = message.metadata;
    if (meta == null) return;

    final donationId = meta['donation_id']?.toString();
    if (donationId == null || donationId.isEmpty) {
      emit(state.copyWith(
        error: 'Thiếu donation_id. Hãy tạo thẻ quyên góp mới (API đúng).',
      ));
      return;
    }

    if (acceptDonationUseCase == null) {
      emit(state.copyWith(error: 'Donation service chưa được cấu hình'));
      return;
    }

    final condition = _mapCondition(meta['condition']?.toString() ?? 'used');

    final result = await acceptDonationUseCase!(
      donationId: donationId,
      defaultCondition: condition,
    );

    await result.fold(
      (err) async {
        emit(state.copyWith(error: err));
      },
      (donation) async {
        final newMeta = Map<String, dynamic>.from(meta);
        newMeta['status'] = donation.status;
        newMeta['donation_status'] = donation.status;

        final updatedMessages = state.messages.map((m) {
          if (m.id == message.id) {
            return m.copyWith(metadata: newMeta);
          }
          return m;
        }).toList();
        emit(state.copyWith(messages: updatedMessages, error: null));

        await _patchMessageMetadata(message.id, newMeta);
      },
    );
  }

  Future<void> _patchMessageMetadata(String messageId, Map<String, dynamic> metadata) async {
    final convId = state.activeConversationId;
    if (convId == null) return;

    try {
      final dio = apiClient?.dio ??
          Dio(BaseOptions(
            baseUrl: baseUrl,
            headers: {'Content-Type': 'application/json'},
          ));

      if (apiClient == null) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString(AppConstants.keyAccessToken) ?? '';
        await dio.patch(
          '$baseUrl/api/communication/conversations/$convId/messages/$messageId/metadata',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
          data: metadata,
        );
      } else {
        await dio.patch(
          '${AppConstants.chatApiBaseUrl}/conversations/$convId/messages/$messageId/metadata',
          data: metadata,
        );
      }
    } catch (e) {
      print('Update message metadata error: $e');
    }
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
