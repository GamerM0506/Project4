import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  /// Câu hỏi thường gặp — nội dung tĩnh, backend chưa có API trợ giúp.
  static const _faqs = <({String question, String answer})>[
    (
      question: 'Chợ Tử Tế là gì?',
      answer:
          'Nền tảng kết nối cộng đồng qua các đợt quyên góp do hội nhóm tổ chức. '
          'Mỗi đợt công khai nhu cầu, số lượng mục tiêu và tiến độ tiếp nhận.',
    ),
    (
      question: 'Làm sao để đóng góp vật phẩm?',
      answer:
          'Vào mục "Đợt quyên góp", chọn một đợt đang mở và chọn đúng loại vật phẩm '
          'hội nhóm đang cần. Nhập số lượng, tình trạng và cách bàn giao rồi gửi để '
          'hội nhóm duyệt.',
    ),
    (
      question: 'Vì sao tôi phải tham gia hội nhóm mới quyên góp được?',
      answer:
          'Mỗi đợt quyên góp thuộc về một hội nhóm. Bạn cần là thành viên đã được '
          'duyệt của hội nhóm đó để gửi đóng góp, thích và bình luận. Bấm "Tham gia" '
          'ở trang đợt hoặc trang hội nhóm để gửi yêu cầu.',
    ),
    (
      question: 'Ai phụ trách trao tặng vật phẩm?',
      answer:
          'Hội nhóm tiếp nhận và kiểm tra từng món, sau đó tổ chức trao tặng theo '
          'đối tượng thụ hưởng của đợt. Bạn theo dõi được tiến độ ngay trên trang đợt.',
    ),
    (
      question: 'Làm sao để tham gia một hội nhóm?',
      answer:
          'Vào mục "Hội nhóm", tìm nhóm bạn quan tâm rồi nhấn "Tham gia". Quản trị '
          'viên sẽ duyệt trước khi bạn thành thành viên chính thức.',
    ),
    (
      question: 'Tôi quên mật khẩu, phải làm gì?',
      answer:
          'Ở màn đăng nhập, chọn "Quên mật khẩu", nhập email đã đăng ký để nhận mã '
          'xác thực, sau đó đặt lại mật khẩu mới.',
    ),
    (
      question: 'Tại sao tài khoản của tôi bị khóa?',
      answer:
          'Tài khoản có thể bị khóa nếu vi phạm tiêu chuẩn cộng đồng (tin rác, lừa '
          'đảo, nội dung phản cảm). Liên hệ đội hỗ trợ theo thông tin bên dưới.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Trợ giúp & Hỗ trợ',
          style: TextStyle(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Câu hỏi thường gặp',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final faq in _faqs) ...[
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.surfaceContainerHighest),
              ),
              child: ExpansionTile(
                shape: const Border(),
                title: Text(
                  faq.question,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedAlignment: Alignment.centerLeft,
                children: [
                  Text(
                    faq.answer,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          Text(
            'Liên hệ hỗ trợ',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: AppConstants.supportEmail,
          ),
          const SizedBox(height: 10),
          _ContactTile(
            icon: Icons.phone_outlined,
            label: 'Tổng đài',
            value: AppConstants.supportPhone,
          ),
        ],
      ),
    );
  }
}

/// Ô liên hệ, bấm để sao chép vào bộ nhớ tạm.
class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () async {
        await Clipboard.setData(ClipboardData(text: value));
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Đã sao chép $label')));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.surfaceContainerHighest),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Icon(icon, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.copy_rounded,
              size: 17,
              color: colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
