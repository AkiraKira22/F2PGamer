import 'package:flutter/material.dart';
import '../data/models.dart';
import '../theme.dart';

/// The ways a list of games can be ordered. Each value carries the label shown
/// in the sort dropdown.
enum GameSort {
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  releaseNewest('Release (Newest)'),
  releaseOldest('Release (Oldest)');

  const GameSort(this.label);
  final String label;
}

/// Sentinel used by the category dropdown to mean "no category filter".
const String kAllCategories = 'All';

/// Applies a category filter and a sort order to [games], returning a new list.
///
/// Shared by the game grid and the favorites screen so both behave identically.
/// [category] of [kAllCategories] (or null) keeps every game.
List<Game> applyGameFilters(
  List<Game> games, {
  required GameSort sort,
  String? category,
}) {
  var result = games;

  if (category != null && category != kAllCategories) {
    result = result.where((g) => g.genre == category).toList();
  } else {
    result = List<Game>.of(result);
  }

  result.sort((a, b) {
    switch (sort) {
      case GameSort.nameAsc:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case GameSort.nameDesc:
        return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      case GameSort.releaseNewest:
        return _releaseValue(b.releaseDate).compareTo(_releaseValue(a.releaseDate));
      case GameSort.releaseOldest:
        return _releaseValue(a.releaseDate).compareTo(_releaseValue(b.releaseDate));
    }
  });

  return result;
}

/// Parses an API release date (e.g. "2021-01-15") for comparison. Unknown or
/// malformed dates sort as the epoch so they land at the "oldest" end.
DateTime _releaseValue(String raw) {
  return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

/// The distinct, sorted list of genres present in [games], with
/// [kAllCategories] prepended so it can back the category dropdown directly.
List<String> categoriesFrom(List<Game> games) {
  final genres = games
      .map((g) => g.genre)
      .where((g) => g.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return [kAllCategories, ...genres];
}

/// A row of controls — a sort dropdown and a category dropdown — that drive
/// [applyGameFilters]. Stateless: the parent owns the selected [sort] and
/// [category] and rebuilds when the callbacks fire.
class GameFilterBar extends StatelessWidget {
  final GameSort sort;
  final String category;
  final List<String> categories;
  final ValueChanged<GameSort> onSortChanged;
  final ValueChanged<String> onCategoryChanged;

  const GameFilterBar({
    super.key,
    required this.sort,
    required this.category,
    required this.categories,
    required this.onSortChanged,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _FilterDropdown<GameSort>(
              icon: Icons.sort,
              value: sort,
              items: GameSort.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onSortChanged(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _FilterDropdown<String>(
              icon: Icons.filter_list,
              value: categories.contains(category) ? category : kAllCategories,
              items: categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (value) {
                if (value != null) onCategoryChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A themed dropdown wrapper so the sort and category controls look identical.
class _FilterDropdown<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentCyan, width: 0.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          icon: Icon(icon, color: AppTheme.accentCyan, size: 18),
          dropdownColor: AppTheme.cardBg,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
