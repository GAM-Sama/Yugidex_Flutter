// lib/view_models/card_filters_view_model.dart (or your path)
import 'package:flutter/material.dart';
// Make sure this path is correct and imports the file with the Enums and CardFilters class
import '../models/card_filters.dart';

class CardFiltersViewModel extends ChangeNotifier {
  // Current filter state
  CardFilters _filters = const CardFilters(); // Start empty

  // --- Sorting State ---
  SortBy _sortBy = SortBy.name; // Default sort
  SortDirection _sortDirection = SortDirection.asc; // Default direction

  // --- Public Getters ---
  CardFilters get filters => _filters;
  SortBy get sortBy => _sortBy;
  SortDirection get sortDirection => _sortDirection;

  /// Adds or removes a value from a filter list (like cardTypes, attributes, etc.)
  void toggleArrayFilter(String keyName, String value) {
    // 1. Get the current list (create a mutable copy)
    List<String> currentList;
    switch (keyName) {
      case 'cardTypes':
        currentList = List<String>.from(_filters.cardTypes);
        break;
      case 'attributes':
        currentList = List<String>.from(_filters.attributes);
        break;
      case 'monsterTypes':
        currentList = List<String>.from(_filters.monsterTypes);
        break;
      case 'spellTrapIcons':
        currentList = List<String>.from(_filters.spellTrapIcons);
        break;
      case 'subtypes':
        currentList = List<String>.from(_filters.subtypes);
        break;
      default:
        debugPrint("Error in toggleArrayFilter: Unknown key '$keyName'");
        return; // Do nothing if the key is invalid
    }

    // 2. Create the new list (adding or removing from the copy)
    List<String> newList;
    if (currentList.contains(value)) {
      currentList.remove(value);
      newList = currentList; // Use the modified copy
    } else {
      currentList.add(value);
      newList = currentList; // Use the modified copy
    }

    // 3. Update the _filters state using copyWith
    switch (keyName) {
      case 'cardTypes':
        _filters = _filters.copyWith(cardTypes: newList);
        break;
      case 'attributes':
        _filters = _filters.copyWith(attributes: newList);
        break;
      case 'monsterTypes':
        _filters = _filters.copyWith(monsterTypes: newList);
        break;
      case 'spellTrapIcons':
        _filters = _filters.copyWith(spellTrapIcons: newList);
        break;
      case 'subtypes':
        _filters = _filters.copyWith(subtypes: newList);
        break;
    }

    // 4. Notify listeners (VERY IMPORTANT!)
    notifyListeners();
  }

  /// Updates a simple value (like minAtk, minDef, or search)
  void updateFilter(String keyName, String? value) {
    // Clean the value if it's an empty string
    final String? cleanValue = (value != null && value.isEmpty) ? null : value;

    // Update the _filters state using copyWith
    switch (keyName) {
      case 'search': // If you add search later
        _filters = _filters.copyWith(search: cleanValue ?? '');
        break;
      case 'minAtk':
        // Save as String?. Conversion to int will happen where it's used.
        _filters = _filters.copyWith(minAtk: () => cleanValue);
        break;
      case 'minDef':
        _filters = _filters.copyWith(minDef: () => cleanValue);
        break;
      default:
        debugPrint("Error in updateFilter: Unknown key '$keyName'");
        return; // Do nothing if the key is invalid
    }

    // Notify listeners
    notifyListeners();
  }

  /// Resets all filters to their default values
  void clearAll() {
    // Create a new empty instance for filters
    _filters = const CardFilters();
    // Also reset sorting
    _sortBy = SortBy.name;
    _sortDirection = SortDirection.asc;
    // Notify listeners
    notifyListeners();
  }

  /// Sets the sorting criteria and direction.
  void setSort(SortBy newSortBy) {
    if (_sortBy == newSortBy) {
      // If tapping the same sort, toggle direction
      _sortDirection =
          _sortDirection == SortDirection.asc ? SortDirection.desc : SortDirection.asc;
    } else {
      // If tapping a new sort, set it and default to ascending
      _sortBy = newSortBy;
      _sortDirection = SortDirection.asc;
    }
    notifyListeners(); // Notify UI that sorting has changed
  }
}