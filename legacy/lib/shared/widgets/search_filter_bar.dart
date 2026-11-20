import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_typography.dart';

/// Reusable search and filter bar adhering to DESIGN.md.
class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.filterOptions = const [],
    this.selectedFilter,
    this.onFilterSelected,
  });

  final String searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final List<String> filterOptions;
  final String? selectedFilter;
  final ValueChanged<String>? onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceSecondary : AppColors.lightSurfacePrimary;
    final border = isDark ? AppColors.borderSubtle : AppColors.lightBorderSubtle;
    final textMuted = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: searchController,
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: searchHint,
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.standard,
              vertical: AppSpacing.compact,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.input),
              borderSide: BorderSide(color: border),
            ),
          ),
        ),
        if (filterOptions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.compact),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filterOptions.map((filter) {
                final isSelected = filter == selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.compact),
                  child: FilterChip(
                    label: Text(
                      filter.toUpperCase(),
                      style: AppTypography.technical(
                        color: isSelected ? Colors.white : textMuted,
                      ).copyWith(fontSize: 11),
                    ),
                    selected: isSelected,
                    onSelected: (_) => onFilterSelected?.call(filter),
                    backgroundColor: surface,
                    selectedColor: AppColors.primaryAccent,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryAccent : border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}
