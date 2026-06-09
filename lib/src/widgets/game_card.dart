import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/favorites_service.dart';
import '../theme.dart';
import 'detail_screen.dart';

/// A single game tile used by the grid and the favorites list. Tapping the
/// card opens the [DetailScreen]; the heart overlay on the image toggles the
/// favorite directly.
///
/// The card is stateless: the heart listens to [FavoritesService.favorites]
/// through a [ValueListenableBuilder], so it (and every other screen showing
/// this game) updates itself whenever the favorite is toggled anywhere.
class GameCard extends StatelessWidget {
  final Game game;
  const GameCard({super.key, required this.game});

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(gameId: game.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Card(
        // antiAlias clips the child column to the rounded card shape, so the
        // image's top corners are rounded without a ClipRRect.
        clipBehavior: Clip.antiAlias,
        color: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.accentCyan, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + favorite overlay.
            Stack(
              children: [
                // Hero Animation (Requirement 09)
                Hero(
                  tag: 'game-thumb-${game.id}',
                  child: Image.network(
                    game.thumbnail,
                    fit: BoxFit.cover,
                    height: 130,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 130,
                        color: AppTheme.darkBg,
                        child: const Icon(Icons.image_not_supported,
                            color: AppTheme.accentCyan),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => FavoritesService.instance.toggle(game.id),
                    // Only this heart rebuilds when favorites change.
                    child: ValueListenableBuilder<Set<int>>(
                      valueListenable: FavoritesService.instance.favorites,
                      builder: (context, favorites, _) {
                        final isFavorite = favorites.contains(game.id);
                        return Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorite
                                ? AppTheme.accentMagenta
                                : Colors.white,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                game.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.accentCyan, width: 0.5),
                ),
                child: Text(
                  game.genre,
                  style: const TextStyle(
                    color: AppTheme.accentCyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: Text(
                game.platform,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
