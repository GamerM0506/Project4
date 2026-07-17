import 'package:flutter/material.dart';

class MarketplaceFilterChips extends StatefulWidget {
  final List<String> filters;
  final Function(String) onFilterSelected;

  const MarketplaceFilterChips({
    super.key,
    required this.filters,
    required this.onFilterSelected,
  });

  @override
  State<MarketplaceFilterChips> createState() => _MarketplaceFilterChipsState();
}

class _MarketplaceFilterChipsState extends State<MarketplaceFilterChips> {
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
            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            selectedColor: colorScheme.primary,
            labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide.none, // Mockup doesn't show borders, just filled colors
            ),
          );
        },
      ),
    );
  }
}
