import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for the user's favorite games.
///
/// Favorite game ids are kept in an in-memory [Set] and persisted to
/// [SharedPreferences]. Widgets read [favorites] / [isFavorite] and call
/// [toggle], then refresh their own UI with setState.
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  static const String _storageKey = 'favorites';

  final Set<int> _favorites = {};
  SharedPreferences? _prefs;

  /// The currently favorited game ids. Call once during app start-up.
  Set<int> get favorites => _favorites;

  /// Loads the persisted favorites. Call once during app start-up.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs!.getStringList(_storageKey) ?? [];
    _favorites
      ..clear()
      ..addAll(stored.map(int.tryParse).whereType<int>());
  }

  bool isFavorite(int gameId) => _favorites.contains(gameId);

  /// Adds the game if it isn't a favorite yet, otherwise removes it.
  Future<void> toggle(int gameId) async {
    if (!_favorites.add(gameId)) {
      _favorites.remove(gameId);
    }
    await _persist();
  }

  Future<void> _persist() async {
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _favorites.map((id) => id.toString()).toList(),
    );
  }
}
