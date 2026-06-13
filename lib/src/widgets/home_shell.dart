import 'package:flutter/material.dart';
import '../theme.dart';
import 'game_grid_screen.dart';
import 'favorites_screen.dart';

/// The logged-in home. A bottom [TabBar] switches between the game grid and the
/// favorites list; each tab keeps its own app bar (so the grid's search,
/// sort/filter, and logout, and the favorites' own controls, stay put).
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        // The two tabs hold their own Scaffolds; swiping is disabled so the
        // grid can still be scrolled/pulled without accidentally changing tab.
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            GameGridScreen(),
            FavoritesScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          color: AppTheme.appBarBg,
          child: const TabBar(
            indicatorColor: AppTheme.accentCyan,
            labelColor: AppTheme.accentCyan,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(icon: Icon(Icons.grid_view), text: 'Games'),
              Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
            ],
          ),
        ),
      ),
    );
  }
}
