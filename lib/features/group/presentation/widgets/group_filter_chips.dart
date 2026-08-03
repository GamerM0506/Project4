import 'package:flutter/material.dart';

import '../../../../core/theme/app_tokens.dart';

/// Dải chip lọc nhóm.
///
/// Dùng [FilterChip] theo `chipTheme` thay vì tự dựng `Container`: trước đây
/// chip ở trang này bo góc 12 và cao 40, còn chip ở trang Đợt quyên góp lại
/// theo theme — hai trang nhìn lệch nhau rõ rệt.
class GroupFilterChips extends StatefulWidget {
  final List<String> filters;
  final ValueChanged<String> onFilterSelected;

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
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        scrollDirection: Axis.horizontal,
        itemCount: widget.filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return Center(
            child: FilterChip(
              label: Text(
                widget.filters[index],
                style: _selectedIndex == index
                    ? TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w700,
                      )
                    : null,
              ),
              selected: _selectedIndex == index,
              showCheckmark: false,
              onSelected: (_) {
                setState(() => _selectedIndex = index);
                widget.onFilterSelected(widget.filters[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
