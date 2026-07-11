import 'package:flutter/material.dart';

class GenderRadioOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderRadioOption({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? colorScheme.secondary : colorScheme.outline,
                width: 2,
              ),
              color: colorScheme.surface,
            ),
            child: isSelected 
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ) 
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: isSelected ? colorScheme.secondary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
