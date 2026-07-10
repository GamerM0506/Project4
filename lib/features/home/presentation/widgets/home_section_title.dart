import 'package:flutter/material.dart';

class HomeSectionTitle extends StatelessWidget {
  final String title;
  final String action;
  final VoidCallback? onActionTap;

  const HomeSectionTitle({
    super.key,
    required this.title,
    required this.action,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            action,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
