// lib/shared/widgets/collection_toolbar.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart'; // Using Lucide for consistency
import '../../core/theme/app_theme.dart'; // Make sure this path is correct
import 'package:yugioh_scanner/models/card_filters.dart'; // Import Enums SortBy and SortDirection

class CollectionToolbar extends StatelessWidget {
  final TextEditingController searchController;
  // No longer strictly needed if controller handles it, but good for consistency
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSortPressed;
  final VoidCallback onFilterPressed;
  final bool showBackButton;
  // final bool hasActiveFilters; // Removed
  final int activeFilterCount; // Added count
  final SortBy sortBy; // Added
  final SortDirection sortDirection; // Added

  const CollectionToolbar({
    super.key,
    required this.searchController,
    required this.searchText, // Added
    required this.onSearchChanged,
    required this.onSortPressed,
    required this.onFilterPressed,
    this.showBackButton = true,
    // required this.hasActiveFilters, // Removed
    required this.activeFilterCount, // Added
    required this.sortBy, // Added
    required this.sortDirection, // Added
  });

  // Helper to get the text label for the sort button
  String _getSortLabel(SortBy sortBy) {
    switch (sortBy) {
      case SortBy.name: return 'Nombre';
      case SortBy.atk: return 'Ataque';
      case SortBy.def: return 'Defensa';
      case SortBy.level: return 'Nivel';
      case SortBy.cardType: return 'Tipo';
      default: return 'Nombre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Update controller text if searchText differs (e.g., if filters are cleared)
    // This ensures consistency if the ViewModel updates the search string directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
       if (searchController.text != searchText) {
         searchController.text = searchText;
         // Move cursor to the end
         searchController.selection = TextSelection.fromPosition(
           TextPosition(offset: searchController.text.length),
         );
       }
     });

    return Container(
      // Use theme color for consistency
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm), // Adjusted padding
      child: Row(
        children: [
          // Optional back button
          if (showBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              color: AppColors.textSecondary, // Use theme color
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Volver',
              splashRadius: 20,
              constraints: const BoxConstraints(), // Keep it compact
              padding: const EdgeInsets.only(right: AppSpacing.sm), // Add some spacing
            ),

          // Search bar
          Expanded(
            child: SizedBox(
              height: 40, // Keep height consistent
              child: TextField(
                controller: searchController,
                // Apply theme styles
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar cartas...',
                  hintStyle: theme.inputDecorationTheme.hintStyle,
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textSecondary), // Lucide icon
                  // Use theme borders and colors
                  filled: true,
                  fillColor: AppColors.background, // Darker background for contrast
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: AppSpacing.sm), // Adjust padding
                  border: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(AppSpacing.lg), // Rounded corners
                     borderSide: const BorderSide(color: AppColors.border),
                  ),
                   enabledBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(AppSpacing.lg),
                     borderSide: const BorderSide(color: AppColors.border),
                  ),
                   focusedBorder: OutlineInputBorder(
                     borderRadius: BorderRadius.circular(AppSpacing.lg),
                     borderSide: const BorderSide(color: AppColors.primary, width: 1.5), // Highlight on focus
                  ),
                ),
                onChanged: onSearchChanged,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm), // Spacing between search and buttons

          // Sort Button
          Tooltip(
            message: 'Ordenar por: ${_getSortLabel(sortBy)} (${sortDirection == SortDirection.asc ? 'Ascendente' : 'Descendente'})',
            child: TextButton.icon(
              style: TextButton.styleFrom(
                 foregroundColor: AppColors.textSecondary, // Use secondary text color
                 padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              ),
              icon: Icon(
                sortDirection == SortDirection.asc ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                size: 16,
                color: AppColors.primary, // Highlight icon color
              ),
              label: Text(
                _getSortLabel(sortBy),
                style: theme.textTheme.bodySmall, // Smaller text for sort label
              ),
              onPressed: onSortPressed,
            ),
          ),

          // Filter Button with Badge
          Tooltip(
            message: 'Filtros (${activeFilterCount > 0 ? '$activeFilterCount activos' : 'Ninguno'})',
            child: Stack( // Use Stack for badge positioning
              clipBehavior: Clip.none, // Allow badge to overflow slightly
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.filter),
                  color: activeFilterCount > 0 ? AppColors.primary : AppColors.textSecondary, // Highlight if active
                  iconSize: 20, // Slightly smaller icon
                  onPressed: onFilterPressed,
                  splashRadius: 20,
                   constraints: const BoxConstraints(),
                   padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                ),
                if (activeFilterCount > 0)
                  Positioned(
                    top: -4,
                    right: -2,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.error, // Use error color for badge background
                      child: Text(
                        activeFilterCount.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textPrimary, // White text
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}