import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/chat_usecases.dart';
import 'chat_inbox_state.dart';

class ChatInboxCubit extends Cubit<ChatInboxState> {
  final GetConversationsUseCase getConversationsUseCase;
  List<ConversationEntity> _allConversations = const [];

  ChatInboxCubit({required this.getConversationsUseCase})
    : super(ChatInboxInitial());

  Future<void> fetchConversations({String? groupId}) async {
    emit(ChatInboxLoading());
    final result = await getConversationsUseCase(groupId: groupId);
    result.fold((failure) => emit(ChatInboxError(failure)), (conversations) {
      _allConversations = conversations;
      emit(ChatInboxLoaded(conversations));
    });
  }

  void search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      emit(ChatInboxLoaded(_allConversations));
      return;
    }
    emit(
      ChatInboxLoaded(
        _allConversations.where((conversation) {
          return conversation.title.toLowerCase().contains(normalized) ||
              (conversation.lastMessage?.toLowerCase().contains(normalized) ??
                  false);
        }).toList(),
      ),
    );
  }
}
