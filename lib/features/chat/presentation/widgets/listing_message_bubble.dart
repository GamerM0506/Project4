import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/chat_state.dart';
import '../cubit/chat_cubit.dart';

class ListingMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isAdmin;

  const ListingMessageBubble({
    super.key,
    required this.message,
    this.isAdmin = true, // Temporarily set to true for demo
  });

  @override
  Widget build(BuildContext context) {
    final meta = message.metadata ?? {};
    final title = meta['name']?.toString() ?? 'Sản phẩm quyên góp';
    final condition = meta['condition']?.toString() ?? 'used';
    final status =
        meta['status']?.toString() ??
        meta['donation_status']?.toString() ??
        'pending';

    final isApproved =
        status == 'accepted' ||
        status == 'received' ||
        status == 'completed' ||
        status == 'active';
    final colorScheme = Theme.of(context).colorScheme;
    final isMine = message.isMine;

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: MediaQuery.of(context).size.width * 0.75,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Image Placeholder
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Icon(
                Icons.card_giftcard,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tình trạng: ${_conditionText(condition)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isApproved
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isApproved ? 'Đã duyệt vào kho' : 'Chờ duyệt',
                          style: TextStyle(
                            color: isApproved ? Colors.green : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isAdmin && !isApproved) ...[
                    const Divider(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ChatCubit>().approveDonation(message);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Đang duyệt sản phẩm vào kho chung...',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: const Text('Duyệt & nhập kho'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _conditionText(String value) {
  return switch (value.toLowerCase()) {
    'new' => 'Mới',
    'like_new' => 'Gần như mới',
    'good' => 'Tốt',
    'used' => 'Đã qua sử dụng',
    'worn' => 'Hao mòn',
    _ => 'Không xác định',
  };
}
