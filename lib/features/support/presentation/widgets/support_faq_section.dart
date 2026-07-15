import 'package:flutter/material.dart';

import '../../domain/entities/faq_entity.dart';
import 'faq_tile.dart';
import 'support_card.dart';

class SupportFaqSection extends StatefulWidget {
  final List<FaqEntity> items;

  const SupportFaqSection({super.key, required this.items});

  @override
  State<SupportFaqSection> createState() => _SupportFaqSectionState();
}

class _SupportFaqSectionState extends State<SupportFaqSection> {
  int? _expandedIndex;

  void _toggle(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SupportCard(
      child: Column(
        children: [
          for (var i = 0; i < widget.items.length; i++) ...[
            FaqTile(
              item: widget.items[i],
              isExpanded: _expandedIndex == i,
              onTap: () => _toggle(i),
            ),
            if (i < widget.items.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: colorScheme.surfaceContainerHighest,
              ),
          ],
        ],
      ),
    );
  }
}
