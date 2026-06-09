import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for the user's favorite games.
///
/// Favorite game ids live in a `ValueNotifier<Set<int>>` and are persisted to
/// [SharedPreferences]. Because the set is exposed as a [ValueListenable], any
/// widget can wrap itself in a [ValueListenableBuilder] and rebuild itself the
/// moment favorites change — no manual setState/callback plumbing between
/// screens.
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const String _storageKey = 'favorites';

  /// The currently favorited game ids. Listen to this to react to changes.
  final ValueNotifier<Set<int>> favorites = ValueNotifier<Set<int>>({});

  SharedPreferences? _prefs;

  /// Loads the persisted favorites. Call once during app start-up.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs!.getStringList(_storageKey) ?? [];
    favorites.value = stored.map(int.tryParse).whereType<int>().toSet();
  }

  bool isFavorite(int gameId) => favorites.value.contains(gameId);

  /// Adds the game if it isn't a favorite yet, otherwise removes it.
  Future<void> toggle(int gameId) async {
    // Assign a brand-new Set so ValueNotifier sees a different reference and
    // notifies its listeners (mutating the existing set in place would not).
    final updated = Set<int>.from(favorites.value);
    if (!updated.add(gameId)) {
      updated.remove(gameId);
    }
    favorites.value = updated;
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      favorites.value.map((id) => id.toString()).toList(),
    );
  }
}
