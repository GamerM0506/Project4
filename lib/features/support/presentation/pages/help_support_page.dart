import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/support_content.dart';
import '../../domain/entities/support_category.dart';
import '../widgets/support_contact_section.dart';
import '../widgets/support_faq_section.dart';
import '../widgets/support_hero_banner.dart';
import '../widgets/support_request_form.dart';
import '../widgets/support_resource_section.dart';
import '../widgets/support_section_header.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  void _copyToClipboard(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnackBar(context, 'Đã sao chép $label');
  }

  void _handleSubmit(BuildContext context, {
    required SupportCategory category,
    required String subject,
    required String message,
  }) {
    _showSnackBar(
      context,
      'Yêu cầu hỗ trợ đã được gửi. Chúng tôi sẽ phản hồi qua email trong 24–48 giờ.',
    );
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? colorScheme.error : colorScheme.secondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          'Trợ giúp & Hỗ trợ',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SupportHeroBanner(),
            const SizedBox(height: 28),
            const SupportSectionHeader(title: 'Liên hệ nhanh'),
            SupportContactSection(
              onCopy: (value, label) => _copyToClipboard(context, value, label),
            ),
            const SizedBox(height: 28),
            const SupportSectionHeader(title: 'Câu hỏi thường gặp'),
            SupportFaqSection(items: SupportContent.faqs),
            const SizedBox(height: 28),
            const SupportSectionHeader(title: 'Gửi yêu cầu hỗ trợ'),
            SupportRequestForm(
              onSubmit: ({
                required category,
                required subject,
                required message,
              }) =>
                  _handleSubmit(
                context,
                category: category,
                subject: subject,
                message: message,
              ),
              onValidationError: (message) =>
                  _showSnackBar(context, message, isError: true),
            ),
            const SizedBox(height: 28),
            const SupportSectionHeader(title: 'Tài liệu hữu ích'),
            SupportResourceSection(
              items: SupportContent.resources,
              onItemTap: (resource) =>
                  _showSnackBar(context, '${resource.title} đang được cập nhật'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
