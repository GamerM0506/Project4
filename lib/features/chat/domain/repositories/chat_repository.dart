import 'package:dartz/dartz.dart';
import '../entities/conversation_entity.dart';
import '../../presentation/cubit/chat_state.dart';

abstract class ChatRepository {
  Future<Either<String, List<ConversationEntity>>> getConversations({
    String? groupId,
  });
  Future<Either<String, List<ChatMessage>>> getMessages(
    String conversationId, {
    int limit = 50,
    int offset = 0,
  });
  Future<Either<String, ChatMessage>> sendMessage(
    String conversationId,
    String content, {
    String type = 'text',
    Map<String, dynamic>? metadata,
  });
  Future<Either<String, void>> markAsRead(String conversationId);
}
