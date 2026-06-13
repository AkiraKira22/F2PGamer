import 'package:flutter/material.dart';
import '../data/api_service.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../theme.dart';
import 'game_card.dart';
import 'game_filter_bar.dart';

class GameGridScreen extends StatefulWidget {
  const GameGridScreen({super.key});

  @override
  State<GameGridScreen> createState() => _GameGridScreenState();
}

class _GameGridScreenState extends State<GameGridScreen> {
  late Future<List<Game>> _gamesFuture;
  List<Game> _allGames = [];
  List<Game> _filteredGames = [];
  List<String> _categories = [kAllCategories];
  final TextEditingController _searchController = TextEditingController();

  // Active search query plus the sort/filter selections that drive the grid.
  String _searchQuery = '';
  GameSort _sort = GameSort.nameAsc;
  String _category = kAllCategories;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _gamesFuture = _fetchGames();
  }

  Future<List<Game>> _fetchGames() async {
    final games = await ApiService.fetchGames();
    setState(() {
      _allGames = games;
      _categories = categoriesFrom(games);
      _applyFilters();
    });
    return games;
  }

  Future<void> logout() async {
    // Signing out updates FirebaseAuth's stream, which the root StreamBuilder
    // in app.dart listens to — it swaps back to the LoginScreen automatically.
    await AuthService.instance.signOut();
  }

  void _filterSearch(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  /// Recomputes [_filteredGames] from the current search text, category, and
  /// sort. Search runs first, then [applyGameFilters] handles category + sort.
  /// Call inside a [setState].
  void _applyFilters() {
    var games = _allGames;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      games = games
          .where(
            (game) =>
                game.title.toLowerCase().contains(query) ||
                game.genre.toLowerCase().contains(query),
          )
          .toList();
    }
    _filteredGames =
        applyGameFilters(games, sort: _sort, category: _category);
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
          'F2PGAMER',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.accentCyan,
          ),
        ),
        backgroundColor: AppTheme.appBarBg,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: AppTheme.errorRed),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Column(
        children: [
          // SearchBar (Requirement 06)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search games by title or genre...',
              leading: const Icon(Icons.search, color: AppTheme.accentCyan),
              onChanged: _filterSearch,
              backgroundColor: WidgetStateProperty.all(AppTheme.cardBg),
              textStyle: WidgetStateProperty.all(
                const TextStyle(color: AppTheme.textPrimary),
              ),
              hintStyle: WidgetStateProperty.all(
                const TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
          // Sort + category controls (shared with the favorites screen).
          GameFilterBar(
            sort: _sort,
            category: _category,
            categories: _categories,
            onSortChanged: (value) => setState(() {
              _sort = value;
              _applyFilters();
            }),
            onCategoryChanged: (value) => setState(() {
              _category = value;
              _applyFilters();
            }),
          ),
          Expanded(
            child: FutureBuilder<List<Game>>(
              future: _gamesFuture,
              builder: (context, snapshot) {
                // Requirement 03: Loading State (LinearProgressIndicator)
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LinearProgressIndicator(color: AppTheme.accentCyan),
                          SizedBox(height: 16),
                          Text(
                            'Loading game archives...',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Requirement 04: Error Handling State
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
                          const Text(
                            'GRID SYSTEM ERROR',
                            style: TextStyle(
                              color: AppTheme.accentCyan,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _loadData();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Requirement 05: Pull-To-Refresh Implementation
                return RefreshIndicator(
                  onRefresh: () async {
                    // Await the actual fetch so the refresh spinner stays
                    // until fresh data is loaded.
                    await _fetchGames();
                  },
                  color: AppTheme.accentCyan,
                  backgroundColor: AppTheme.cardBg,
                  child: GridView.count(
                    padding: const EdgeInsets.all(12),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                    children: _filteredGames
                        .map((game) =>
                            GameCard(key: ValueKey(game.id), game: game))
                        .toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
