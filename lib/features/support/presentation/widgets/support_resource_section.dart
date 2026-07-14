import 'package:flutter/material.dart';

import '../../domain/entities/support_resource_entity.dart';
import 'support_card.dart';

class SupportResourceSection extends StatelessWidget {
  final List<SupportResourceEntity> items;
  final ValueChanged<SupportResourceEntity> onItemTap;

  const SupportResourceSection({
    super.key,
    required this.items,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SupportCard(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  items[i].icon,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              title: Text(
                items[i].title,
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
              trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              onTap: () => onItemTap(items[i]),
            ),
            if (i < items.length - 1)
              Divider(height: 1, color: colorScheme.surfaceContainerHighest),
          ],
        ],
      ),
    );
  }
}
