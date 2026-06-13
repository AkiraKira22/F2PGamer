import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../theme.dart';
import 'game_card.dart';
import 'game_filter_bar.dart';

/// Shows the games the user has marked as favorite. The grid is wrapped in a
/// [ValueListenableBuilder] on [FavoritesService.favorites], so un-favoriting a
/// game anywhere removes it from this list immediately — no manual refresh.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Game>> _gamesFuture;
  final TextEditingController _searchController = TextEditingController();

  // Active search query plus the sort/filter selections that drive the grid.
  String _searchQuery = '';
  GameSort _sort = GameSort.nameAsc;
  String _category = kAllCategories;

  @override
  void initState() {
    super.initState();
    // The favorites store only ids, so we fetch the catalogue once and filter
    // it by the favorite set.
    _gamesFuture = ApiService.fetchGames();
  }

  Future<void> logout() async {
    // Signing out updates FirebaseAuth's stream, which the root StreamBuilder
    // in app.dart listens to — it swaps back to the LoginScreen automatically.
    await AuthService.instance.signOut();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text(
          ' FAVORITES',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentCyan,
          ),
        ),
        backgroundColor: AppTheme.appBarBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.accentCyan),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: FutureBuilder<List<Game>>(
        future: _gamesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accentCyan),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppTheme.errorRed,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.errorRed),
                    ),
                  ],
                ),
              ),
            );
          }

          final allGames = snapshot.data ?? [];

          // Rebuild the grid whenever the favorite set changes, so removing a
          // favorite (here or on the detail screen) drops it from the list.
          return ValueListenableBuilder<Set<int>>(
            valueListenable: FavoritesService.instance.favorites,
            builder: (context, favorites, _) {
              final favoriteGames = allGames
                  .where((game) => favorites.contains(game.id))
                  .toList();

              if (favoriteGames.isEmpty) {
                return const _EmptyFavorites();
              }

              // Categories come from the favorites themselves so the dropdown
              // only offers genres actually present here.
              final categories = categoriesFrom(favoriteGames);

              // Search runs first (title or genre), then category + sort, so
              // all three stack together — same behaviour as the game grid.
              var matched = favoriteGames;
              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                matched = matched
                    .where(
                      (game) =>
                          game.title.toLowerCase().contains(query) ||
                          game.genre.toLowerCase().contains(query),
                    )
                    .toList();
              }
              final visibleGames = applyGameFilters(
                matched,
                sort: _sort,
                category: _category,
              );

              return Column(
                children: [
                  // SearchBar — filters favorites by title or genre.
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: 'Search favorites by title or genre...',
                      leading: const Icon(Icons.search,
                          color: AppTheme.accentCyan),
                      onChanged: (query) =>
                          setState(() => _searchQuery = query),
                      backgroundColor:
                          WidgetStateProperty.all(AppTheme.cardBg),
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(color: AppTheme.textPrimary),
                      ),
                      hintStyle: WidgetStateProperty.all(
                        const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  GameFilterBar(
                    sort: _sort,
                    category: _category,
                    categories: categories,
                    onSortChanged: (value) => setState(() => _sort = value),
                    onCategoryChanged: (value) =>
                        setState(() => _category = value),
                  ),
                  Expanded(
                    child: visibleGames.isEmpty
                        ? const Center(
                            child: Text(
                              'No favorites match your search or filter.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          )
                        : GridView.count(
                            padding: const EdgeInsets.all(12),
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.75,
                            children: visibleGames
                                .map((game) => GameCard(
                                    key: ValueKey(game.id), game: game))
                                .toList(),
                          ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.favorite_border, color: AppTheme.accentCyan, size: 56),
            SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                color: AppTheme.accentCyan,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the heart on any game to add it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
