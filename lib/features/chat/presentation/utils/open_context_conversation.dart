import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/usecases/chat_usecases.dart';

Future<void> openContextConversation(
  BuildContext context, {
  required String contextType,
  required String contextId,
  required String groupId,
  required String name,
  bool asGroup = false,
}) async {
  final result = await sl<GetConversationsUseCase>()(
    groupId: asGroup ? groupId : null,
  );
  if (!context.mounted) return;

  await result.fold((error) async => _showError(context, error), (
    conversations,
  ) async {
    ConversationEntity? match;
    for (final conversation in conversations) {
      if (conversation.contextType == contextType &&
          conversation.contextId == contextId) {
        match = conversation;
        break;
      }
    }

    if (match == null) {
      _showError(
        context,
        contextType == 'request'
            ? 'Cuộc trò chuyện sẽ có sau khi yêu cầu được duyệt.'
            : 'Cuộc trò chuyện chưa được tạo. Vui lòng thử lại sau.',
      );
      return;
    }

    await context.push(
      AppRoutes.chatRoom,
      extra: {
        'conversationId': match.id,
        'groupId': match.groupId ?? groupId,
        'name': name,
      },
    );
  });
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
