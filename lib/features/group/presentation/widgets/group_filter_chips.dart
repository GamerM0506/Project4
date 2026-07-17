import 'package:flutter/material.dart';

class GroupFilterChips extends StatefulWidget {
  final List<String> filters;
  final Function(String) onFilterSelected;

  const GroupFilterChips({
    super.key,
    required this.filters,
    required this.onFilterSelected,
  });

  @override
  State<GroupFilterChips> createState() => _GroupFilterChipsState();
}

class _GroupFilterChipsState extends State<GroupFilterChips> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: widget.filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = _selectedIndex == index;
          
          return ChoiceChip(
            label: Text(widget.filters[index]),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedIndex = index);
                widget.onFilterSelected(widget.filters[index]);
              }
            },
            showCheckmark: false,
            backgroundColor: colorScheme.surface,
            selectedColor: colorScheme.primary,
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: isSelected ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          );
        },
      ),
    );
  }
}
