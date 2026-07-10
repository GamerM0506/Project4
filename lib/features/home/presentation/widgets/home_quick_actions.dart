import 'package:flutter/material.dart';

class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(context, Icons.storefront_outlined, 'Marketplace'),
        _buildActionItem(context, Icons.group_outlined, 'Find Groups'),
        _buildActionItem(context, Icons.my_location_outlined, 'My Tracking'),
        _buildActionItem(context, Icons.emoji_events_outlined, 'Leaderboard'),
      ],
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.surfaceContainerHighest),
            ),
            child: Icon(icon, color: colorScheme.secondary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
