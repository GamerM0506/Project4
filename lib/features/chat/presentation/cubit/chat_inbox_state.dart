import 'package:equatable/equatable.dart';
import '../../domain/entities/conversation_entity.dart';

abstract class ChatInboxState extends Equatable {
  const ChatInboxState();

  @override
  List<Object> get props => [];
}

class ChatInboxInitial extends ChatInboxState {}

class ChatInboxLoading extends ChatInboxState {}

class ChatInboxLoaded extends ChatInboxState {
  final List<ConversationEntity> conversations;

  const ChatInboxLoaded(this.conversations);

  @override
  List<Object> get props => [conversations];
}

class ChatInboxError extends ChatInboxState {
  final String message;

  const ChatInboxError(this.message);

  @override
  List<Object> get props => [message];
}
