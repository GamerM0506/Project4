import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../injection_container.dart';
import '../cubit/chat_inbox_cubit.dart';
import '../cubit/chat_inbox_state.dart';

class ChatInboxPage extends StatelessWidget {
  final String? groupId;

  const ChatInboxPage({super.key, this.groupId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChatInboxCubit>()..fetchConversations(groupId: groupId),
      child: _ChatInboxView(groupId: groupId),
    );
  }
}

class _ChatInboxView extends StatelessWidget {
  final String? groupId;

  const _ChatInboxView({this.groupId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: context.read<ChatInboxCubit>().search,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm tin nhắn...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<ChatInboxCubit, ChatInboxState>(
              builder: (context, state) {
                if (state is ChatInboxLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ChatInboxError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(state.message),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context
                              .read<ChatInboxCubit>()
                              .fetchConversations(groupId: groupId),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                } else if (state is ChatInboxLoaded) {
                  final conversations = state.conversations;

                  if (conversations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer.withOpacity(
                                  0.4,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 56,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Chưa có cuộc trò chuyện nào',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Hãy tham gia Hội nhóm và bấm "Nhắn tin & Quyên góp" để bắt đầu kết nối với nhóm!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: () {
                                context.go(AppRoutes.groups);
                              },
                              icon: const Icon(Icons.groups_outlined),
                              label: const Text('Khám phá Hội nhóm ngay'),
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conv = conversations[index];
                      final partnerIsGroup = groupId == null;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        color: colorScheme.surfaceContainerLowest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withOpacity(0.3),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          leading: AppAvatar(
                            imageUrl: conv.avatarUrl,
                            name: conv.title,
                            radius: 24,
                          ),
                          title: Text(
                            conv.title.isNotEmpty
                                ? conv.title
                                : (partnerIsGroup
                                      ? 'Hội nhóm thiện nguyện'
                                      : 'Người dùng'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              conv.lastMessage ??
                                  'Bắt đầu trò chuyện & quyên góp...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 20),
                          onTap: () {
                            final currentUserId = sl<SharedPreferences>()
                                .getString(AppConstants.keyUserId);
                            context.push(
                              AppRoutes.chatRoom,
                              extra: {
                                'conversationId': conv.id,
                                'groupId': conv.groupId,
                                'name': conv.title,
                                'avatarUrl': conv.avatarUrl,
                                'isUserSide': conv.userId == currentUserId,
                              },
                            );
                          },
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
