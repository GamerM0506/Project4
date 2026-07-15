import 'package:flutter/material.dart';

import '../../../user/presentation/widgets/soft_dropdown_field.dart';
import '../../../user/presentation/widgets/soft_input_field.dart';
import '../../domain/entities/support_category.dart';
import 'support_card.dart';

typedef SupportRequestCallback = void Function({
  required SupportCategory category,
  required String subject,
  required String message,
});

class SupportRequestForm extends StatefulWidget {
  final SupportRequestCallback onSubmit;
  final void Function(String message) onValidationError;

  const SupportRequestForm({
    super.key,
    required this.onSubmit,
    required this.onValidationError,
  });

  @override
  State<SupportRequestForm> createState() => _SupportRequestFormState();
}

class _SupportRequestFormState extends State<SupportRequestForm> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  SupportCategory _category = SupportCategory.account;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      widget.onValidationError('Vui lòng điền đầy đủ tiêu đề và nội dung');
      return;
    }

    widget.onSubmit(
      category: _category,
      subject: subject,
      message: message,
    );

    _subjectController.clear();
    _messageController.clear();
    setState(() => _category = SupportCategory.account);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SupportCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SoftDropdownField(
            label: 'Danh mục',
            value: _category.label,
            items: SupportCategory.values
                .map(
                  (category) => DropdownMenuItem(
                    value: category.label,
                    child: Text(category.label),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _category = SupportCategory.values.firstWhere(
                  (category) => category.label == value,
                );
              });
            },
          ),
          const SizedBox(height: 16),
          SoftInputField(
            controller: _subjectController,
            label: 'Tiêu đề vấn đề',
          ),
          const SizedBox(height: 16),
          SoftInputField(
            controller: _messageController,
            label: 'Mô tả chi tiết vấn đề',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _handleSubmit,
              icon: const Icon(Icons.send_outlined, size: 20),
              label: const Text('Gửi yêu cầu'),
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
