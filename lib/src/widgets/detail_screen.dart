import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../services/favorites_service.dart';
import '../theme.dart';

class DetailScreen extends StatefulWidget {
  final int gameId;
  const DetailScreen({super.key, required this.gameId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  // Created once. Building the future in initState (instead of inline in
  // build) means the favorite-toggle rebuilds don't re-fire the network call.
  late final Future<GameDetail> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ApiService.fetchGameDetail(widget.gameId);
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.instance.toggle(widget.gameId);
    if (!mounted) return;

    final isFavorite = FavoritesService.instance.isFavorite(widget.gameId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFavorite
              ? 'Game added to favorites!'
              : 'Game removed from favorites',
        ),
        backgroundColor:
            isFavorite ? AppTheme.successGreen : AppTheme.accentCyan,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      body: FutureBuilder<GameDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          // Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _statusScaffold(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(color: AppTheme.accentCyan),
                  SizedBox(height: 16),
                  Text(
                    'Loading game detail...',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          // Error State
          if (snapshot.hasError) {
            return _statusScaffold(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorRed,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error parsing detail',
                    style: TextStyle(
                      color: AppTheme.accentCyan,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.errorRed),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final detail = snapshot.data!;

          // CustomScrollView lets the Hero header collapse into the app bar as
          // the user scrolls (a SliverAppBar with a FlexibleSpaceBar), while
          // the rest of the page scrolls as normal slivers below it.
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppTheme.appBarBg,
                iconTheme: const IconThemeData(color: AppTheme.accentCyan),
                actions: [
                  // The heart rebuilds itself when the favorite changes.
                  ValueListenableBuilder<Set<int>>(
                    valueListenable: FavoritesService.instance.favorites,
                    builder: (context, favorites, _) {
                      final isFavorite = favorites.contains(detail.id);
                      return IconButton(
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite
                              ? AppTheme.accentMagenta
                              : AppTheme.accentCyan,
                          size: 28,
                        ),
                        onPressed: _toggleFavorite,
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  // Hero image header (Requirement 09). A normal Image still
                  // animates between the grid and this screen.
                  background: Hero(
                    tag: 'game-thumb-${detail.id}',
                    child: Image.network(
                      detail.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.cardBg,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: AppTheme.accentCyan,
                            size: 48,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.person,
                            color: AppTheme.accentCyan,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Developer: ${detail.developer}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: AppTheme.accentCyan,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Released: ${detail.releaseDate}',
                            style:
                                const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.info,
                            color: AppTheme.accentCyan,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Status: ${detail.status}',
                            style:
                                const TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppTheme.accentCyan, height: 24),
                      const Text(
                        'About the Game',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppTheme.accentCyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        detail.description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.4,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Publisher Info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          border: Border.all(
                            color: AppTheme.accentCyan,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Publisher',
                              style: TextStyle(
                                color: AppTheme.accentCyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              detail.publisher,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Screenshots Section
                      if (detail.screenshots.isNotEmpty) ...[
                        const Text(
                          'Screenshots',
                          style: TextStyle(
                            color: AppTheme.accentCyan,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: detail.screenshots.length,
                            itemBuilder: (context, idx) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                // Card with antiAlias rounds the image corners
                                // without a ClipRRect.
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  margin: EdgeInsets.zero,
                                  child: Image.network(
                                    detail.screenshots[idx],
                                    fit: BoxFit.cover,
                                    width: 200,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return Container(
                                        width: 200,
                                        color: AppTheme.cardBg,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: AppTheme.accentCyan,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Loading and error states still need a back button (there's no AppBar of
  /// their own), so they reuse a minimal scrollable shell with a pinned
  /// SliverAppBar that just carries the back arrow.
  Widget _statusScaffold({required Widget child}) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar(
          pinned: true,
          backgroundColor: AppTheme.appBarBg,
          elevation: 0,
          iconTheme: IconThemeData(color: AppTheme.accentCyan),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: child),
        ),
      ],
    );
  }
}
