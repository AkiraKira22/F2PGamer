import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/favorites_service.dart';
import '../theme.dart';
import 'detail_screen.dart';

/// A single game tile used by the grid and the favorites list. Tapping the
/// card opens the [DetailScreen]; the heart overlay on the image toggles the
/// favorite directly. [onReturn] (if given) fires after the detail screen is
/// popped or the heart is toggled, so callers can refresh.
class GameCard extends StatefulWidget {
  final Game game;
  final VoidCallback? onReturn;
  const GameCard({super.key, required this.game, this.onReturn});

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> {
  Future<void> _toggleFavorite() async {
    await FavoritesService.instance.toggle(widget.game.id);
    if (!mounted) return;
    // Rebuild so this card's heart reflects the new state. We read the value
    // straight from the service in build(), so there's nothing to cache.
    setState(() {});
    widget.onReturn?.call();
  }

  Future<void> _openDetail() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailScreen(gameId: widget.game.id),
      ),
    );
    if (!mounted) return;
    // The favorite may have been toggled on the detail screen.
    setState(() {});
    widget.onReturn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    // Read the live favorite state every build, so a card that gets recycled
    // for a different game (e.g. after one is removed) always shows the right
    // heart.
    final isFavorite = FavoritesService.instance.isFavorite(game.id);
    return GestureDetector(
      onTap: _openDetail,
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
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? AppTheme.accentMagenta
                            : Colors.white,
                        size: 20,
                      ),
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
