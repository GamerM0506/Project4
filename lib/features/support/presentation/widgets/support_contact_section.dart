import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';

class SupportContactSection extends StatelessWidget {
  final void Function(String value, String label) onCopy;

  const SupportContactSection({super.key, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ContactCard(
            icon: Icons.email_outlined,
            title: 'Email',
            value: AppConstants.supportEmail,
            onTap: () => onCopy(AppConstants.supportEmail, 'email hỗ trợ'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ContactCard(
            icon: Icons.phone_outlined,
            title: 'Đường dây nóng',
            value: AppConstants.supportPhone,
            onTap: () => onCopy(AppConstants.supportPhone, 'số đường dây nóng'),
          ),
        ),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: colorScheme.primary, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
