import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/chat_usecases.dart';
import 'chat_inbox_state.dart';

class ChatInboxCubit extends Cubit<ChatInboxState> {
  final GetConversationsUseCase getConversationsUseCase;

  ChatInboxCubit({required this.getConversationsUseCase}) : super(ChatInboxInitial());

  Future<void> fetchConversations() async {
    emit(ChatInboxLoading());
    final result = await getConversationsUseCase();
    result.fold(
      (failure) => emit(ChatInboxError(failure)),
      (conversations) => emit(ChatInboxLoaded(conversations)),
    );
  }
}
