import 'package:dartz/dartz.dart';
import '../repositories/chat_repository.dart';
import '../entities/conversation_entity.dart';
import '../../presentation/cubit/chat_state.dart';

class GetConversationsUseCase {
  final ChatRepository repository;

  GetConversationsUseCase(this.repository);

  Future<Either<String, List<ConversationEntity>>> call() {
    return repository.getConversations();
  }
}

class GetMessagesUseCase {
  final ChatRepository repository;

  GetMessagesUseCase(this.repository);

  Future<Either<String, List<ChatMessage>>> call(String conversationId) {
    return repository.getMessages(conversationId);
  }
}

class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<String, ChatMessage>> call(String conversationId, String content, {String type = 'text', Map<String, dynamic>? metadata}) {
    return repository.sendMessage(conversationId, content, type: type, metadata: metadata);
  }
}

class MarkAsReadUseCase {
  final ChatRepository repository;

  MarkAsReadUseCase(this.repository);

  Future<Either<String, void>> call(String conversationId) {
    return repository.markAsRead(conversationId);
  }
}
