import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../services/favorites_service.dart';
import '../theme.dart';
import 'game_card.dart';

/// Shows the games the user has marked as favorite. Returning from a game's
/// detail screen (where a favorite may have been toggled) refreshes the list
/// via setState.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Game>> _gamesFuture;

  @override
  void initState() {
    super.initState();
    // The favorites store only ids, so we fetch the catalogue once and filter
    // it by the favorite set.
    _gamesFuture = ApiService.fetchGames();
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
          final favorites = FavoritesService.instance.favorites;
          final favoriteGames = allGames
              .where((game) => favorites.contains(game.id))
              .toList();

          if (favoriteGames.isEmpty) {
            return const _EmptyFavorites();
          }

          return GridView.count(
            padding: const EdgeInsets.all(12),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
            children: favoriteGames
                .map(
                  (game) => GameCard(
                    key: ValueKey(game.id),
                    game: game,
                    onReturn: () => setState(() {}),
                  ),
                )
                .toList(),
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
