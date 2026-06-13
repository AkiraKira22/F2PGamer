# F2PGamer — A Free-to-Play Game Tracker Built with Flutter

> My Flutter final project: an app that lists free-to-play games. It has a
> dark theme, Firebase + Google login, favorites that stay after you close the
> app (and update across every screen automatically), search, sort and
> category filters, bottom **tab bar** navigation, a Hero animation, and a
> collapsing image header on the detail page. Built with Flutter and Material 3.

*(Replace the lines below with your real links before publishing.)*

- 🎬 **Demo GIF:** _paste your screen-recording GIF here_
- 💻 **GitHub:** _https://github.com/your-username/f2pgamer_
- 📱 **Screenshots:** three screens shown below

---

## 1. What is F2PGamer?

There are already a lot of movie, weather, news, and Pokémon apps, so I made
something different: an app that tracks **free-to-play games**. It loads a live
list of hundreds of games (shooters, MMORPGs, MOBAs, card games, and more). You
can search them, **sort** them by name or release date, **filter** them by
category, look at them in a grid, open one to see its full details, and save the
ones you like. A bottom **tab bar** switches between the game grid and your
favorites. The whole app uses a dark theme.

The data comes from the free [**FreeToGame API**](https://www.freetogame.com/api-doc)
(no API key needed). To use the app, you first log in with **Firebase
Authentication** — either email and password, or your Google account.

---

## 2. Screenshots

> Put your three screenshots here. One for each main screen:

**① Login screen** — email/password and Google, with a glowing logo
`![Login screen](screenshots/login.png)`

**② Game grid + search/sort/filter** — the live list in a 2-column grid, with the
search bar, the sort + category dropdowns, pull-to-refresh, and the bottom tab bar
`![Game grid](screenshots/grid.png)`

**③ Game detail** — a big header image, game info, the description, and a row of
screenshots
`![Game detail](screenshots/detail.png)`

---

## 3. Custom theme

All the colors live in one `AppTheme` class, so the whole app looks the same. I
set the colors once and every screen uses them:

```dart
class AppTheme {
  // Color Palette
  static const Color darkBg        = Color(0xFF0F111A);
  static const Color cardBg        = Color(0xFF1F2335);
  static const Color accentCyan    = Color(0xFF00D9FF);
  static const Color accentMagenta = Color(0xFFFF006E);
  static const Color errorRed      = Color(0xFFFF0055);
  static const Color successGreen  = Color(0xFF00FF41);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        // ...AppBar, Card, Input, Button, Divider & ProgressIndicator themes
      );
}
```

**What this does, line by line:**

- `static const Color ...` — these are my fixed colors. `static` means I can use
  them as `AppTheme.accentCyan` anywhere, without making an object first.
- `ThemeData(...)` — this is the app's style. I pass it to `MaterialApp(theme:
  ...)` once, and all widgets follow it.
- `useMaterial3: true` — turns on the newest Material design look.
- `brightness: Brightness.dark` — tells Flutter this is a dark theme, so default
  text and icons become light.

Cyan is the main color, magenta marks favorites, and red and green are used for
errors and success. So every color has a clear meaning.

---

## 4. The required features, and where they are

### 4.1 Two API calls → grid → detail page

`ApiService` calls two FreeToGame URLs. The first gets the whole list; the second
gets the details of one game.

```dart
class ApiService {
  static const String baseUrl = 'https://www.freetogame.com/api';

  // API 1 — the full list, shown in the grid
  static Future<List<Game>> fetchGames() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/games'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Game.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load games. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // API 2 — full details for one game, shown on the detail page
  static Future<GameDetail> fetchGameDetail(int gameId) async {
    final response = await http.get(Uri.parse('$baseUrl/game?id=$gameId'));
    if (response.statusCode == 200) {
      return GameDetail.fromJson(json.decode(response.body));
    }
    throw Exception('Failed to load details. Status: ${response.statusCode}');
  }
}
```

**What this does, step by step:**

- `await http.get(...)` — sends a request to the internet and waits for the
  answer. `await` means "pause here until the answer comes back".
- `response.statusCode == 200` — `200` means "OK". If it is anything else, the
  request failed, so I `throw` an error.
- `json.decode(response.body)` — the answer is text in JSON format. This turns
  that text into a Dart `List` (for the list call) or `Map` (for one game).
- `data.map((json) => Game.fromJson(json)).toList()` — goes through each item in
  the list and turns it into a `Game` object, then collects them into a `List`.
- `try / catch` — if anything fails (no internet, bad data), I catch it and
  throw a clear "Network error" message. The screen shows this message later.

The list is shown with `GridView.count`. When you tap a `GameCard`, the app
opens a `DetailScreen` for that game.

### 4.2 Turning JSON into my own classes

The JSON from the internet is just text. I turn it into real Dart objects with a
`fromJson` "factory". This is the `Game` class used in the list:

```dart
class Game {
  final int id;
  final String title;
  final String thumbnail;
  final String genre;
  final String platform;
  final String releaseDate;   // powers "sort by release date"
  // ...

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      genre: json['genre'] ?? '',
      platform: json['platform'] ?? '',
      releaseDate: json['release_date'] ?? '',
    );
  }
}
```

**What this does:**

- `factory Game.fromJson(Map<String, dynamic> json)` — a special builder. You
  give it the JSON map, and it gives you back a `Game`.
- `json['title']` — reads the value with the key `"title"` from the JSON.
- `?? 0` and `?? ''` — "if this is missing (null), use this default instead". So
  a missing field never crashes the app; it just becomes `0` or an empty text.

Now the rest of the app works with clean `Game` objects (like `game.title`)
instead of raw JSON. The detail page does the same with a bigger `GameDetail`
class.

### 4.3 Loading, error, and pull-to-refresh — one `FutureBuilder`

One `FutureBuilder<List<Game>>` handles all three cases: still loading, failed,
or done.

```dart
FutureBuilder<List<Game>>(
  future: _gamesFuture,
  builder: (context, snapshot) {
    // 1. Still loading
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const LinearProgressIndicator(color: AppTheme.accentCyan);
    }
    // 2. Failed
    if (snapshot.hasError) {
      return Column(children: [
        const Icon(Icons.error_outline, color: AppTheme.errorRed),
        Text('${snapshot.error}'),
        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
      ]);
    }
    // 3. Done — show the grid, and allow pull-to-refresh
    return RefreshIndicator(
      onRefresh: () async => _fetchGames(),
      child: GridView.count(
        crossAxisCount: 2,
        children: _filteredGames
            .map((game) => GameCard(key: ValueKey(game.id), game: game))
            .toList(),
      ),
    );
  },
)
```

**What this does:**

- `FutureBuilder` watches `_gamesFuture` (the network call) and rebuilds the
  screen when its state changes.
- `snapshot.connectionState == ConnectionState.waiting` — the answer has not
  come yet, so I show a `LinearProgressIndicator` (the loading bar).
- `snapshot.hasError` — the call failed. I show the error text and a **Retry**
  button. The button calls `_loadData` to try again.
- `RefreshIndicator` — lets the user pull the list down to reload it. The
  `onRefresh` runs the fetch again.
- `key: ValueKey(game.id)` — gives each card a stable id, so when the list
  changes, Flutter keeps each card matched to the right game.

### 4.4 Search

A Material 3 `SearchBar` filters the list that is already loaded. It matches by
**title or genre**, so it does not call the network again:

```dart
void _filterSearch(String query) {
  setState(() {
    if (query.isEmpty) {
      _filteredGames = _allGames;
    } else {
      _filteredGames = _allGames.where((game) =>
          game.title.toLowerCase().contains(query.toLowerCase()) ||
          game.genre.toLowerCase().contains(query.toLowerCase())).toList();
    }
  });
}
```

**What this does:**

- `_allGames` is the full list; `_filteredGames` is what the grid shows.
- `setState(() {...})` — tells Flutter "the data changed, rebuild the screen".
- If the box is empty, I show everything again.
- `.where((game) => ...)` — keeps only the games that match.
- `.toLowerCase().contains(...)` — makes the search ignore upper/lower case, so
  "DOTA" and "dota" both match.

The **favorites screen** has its own copy of this same search bar (and its own
logout button in the app bar), so you can search *within* your favorites by title
or genre exactly like on the main grid.

### 4.4.1 Sort and filter (shared by both screens)

On top of search, you can **sort** the games (by name A–Z / Z–A, or by release
date newest / oldest) and **filter** them to a single **category**. The same
controls and logic are reused on both the game grid *and* the favorites screen,
so they behave identically. Everything lives in one file,
`widgets/game_filter_bar.dart`:

```dart
enum GameSort {
  nameAsc('Name (A-Z)'),
  nameDesc('Name (Z-A)'),
  releaseNewest('Release (Newest)'),
  releaseOldest('Release (Oldest)');
  const GameSort(this.label);
  final String label;
}

// One pure function does the filtering + sorting; both screens call it.
List<Game> applyGameFilters(List<Game> games,
    {required GameSort sort, String? category}) {
  var result = games;
  if (category != null && category != kAllCategories) {
    result = result.where((g) => g.genre == category).toList();
  } else {
    result = List<Game>.of(result);   // copy, so we never sort the original
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
```

**What this does:**

- `enum GameSort` — the four sort options. Each value carries the `label` that
  is shown in the dropdown, so the menu and the logic never drift apart.
- `applyGameFilters(...)` is a **pure function**: same input → same output, no
  hidden state. That is exactly why both screens can share it.
- `.where((g) => g.genre == category)` — keeps only the chosen category.
  `kAllCategories` (the string `'All'`) means "don't filter".
- `List<Game>.of(result)` — I copy the list before sorting, so I never reorder
  the original `_allGames` in place.
- `result.sort((a, b) => ...)` — Dart's sort. Returning a negative / zero /
  positive number tells it whether `a` goes before, equal to, or after `b`.
- `_releaseValue(raw)` wraps `DateTime.tryParse(raw)` and falls back to the epoch
  for missing dates, so a blank release date can't crash the sort — it just
  sorts as the oldest.

The categories aren't hard-coded; I build them from whatever games are loaded:

```dart
List<String> categoriesFrom(List<Game> games) {
  final genres = games.map((g) => g.genre).where((g) => g.isNotEmpty)
      .toSet().toList()..sort();
  return [kAllCategories, ...genres];   // 'All' first, then every real genre
}
```

`.toSet()` removes duplicates and `..sort()` puts them in order, so the dropdown
shows each genre once, alphabetically, with **All** on top.

The UI is a small `GameFilterBar` widget (two themed dropdowns). The screen owns
the chosen `sort` and `category` and rebuilds when they change:

```dart
GameFilterBar(
  sort: _sort,
  category: _category,
  categories: _categories,
  onSortChanged: (value) => setState(() { _sort = value; _applyFilters(); }),
  onCategoryChanged: (value) => setState(() { _category = value; _applyFilters(); }),
)
```

On the grid, `_applyFilters()` runs search **first**, then hands the result to
`applyGameFilters` for the category + sort — so search, filter, and sort all
stack together. The favorites screen does the **same** three steps (its own
search box → `applyGameFilters`) on the favorite games, and builds its category
list from just the favorites.

### 4.5 Register / login, and error messages

All the login code is in one `AuthService` class that uses **Firebase Auth**. It
has **two** ways to sign in: email/password (you can also create a new account),
and Google.

The top of the app is a `StreamBuilder`. It watches the login state and decides
which screen to show. This is the only place that does the routing:

```dart
home: StreamBuilder<User?>(
  stream: AuthService.instance.authStateChanges,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const _SplashScreen();
    }
    if (snapshot.hasData) {
      return const HomeShell();      // logged in → tab bar (grid + favorites)
    }
    return const LoginScreen();      // logged out
  },
),
```

**What this does:**

- `authStateChanges` is a **stream** — it sends a new value every time the user
  logs in or out.
- `StreamBuilder` listens to that stream and rebuilds by itself.
- `snapshot.hasData` is true when a user is logged in → show the `HomeShell`
  (the tab bar that holds the game grid and the favorites screen — see 4.10).
- If there is no user → show the login screen.
- So I never write "go to the home page" by hand. Logging in or out changes the
  screen automatically.

When login fails, I turn the Firebase error into a simple message and show it
with **`showSnackBar`** (a small bar at the bottom of the screen):

```dart
Future<void> _runAuth(Future<Object?> Function() action) async {
  setState(() => _isLoading = true);
  try {
    await action(); // sign in or register
  } on AuthException catch (e) {
    if (!e.cancelled) _showErrorSnackBar(e.message);
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

void _showErrorSnackBar(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppTheme.errorRed),
  );
}
```

**What this does:**

- `_isLoading` shows a spinner on the button while the login runs.
- `on AuthException catch (e)` — catches a login error. `AuthService` already
  changed Firebase's codes (like `wrong-password`) into a friendly message.
- `if (!e.cancelled)` — if the user just closed the Google popup, that is not a
  real error, so I stay quiet.
- `ScaffoldMessenger.of(context).showSnackBar(...)` — shows the red message bar.

### 4.6 Saving data (favorites) + automatic UI updates

`FavoritesService` keeps the favorite game ids and saves them with
**`SharedPreferences`**, so they stay after you close the app. The ids live in a
**`ValueNotifier<Set<int>>`**, which is a small box that *tells anyone who is
listening* whenever its value changes:

```dart
// A box that holds the favorite ids AND notifies listeners when they change.
final ValueNotifier<Set<int>> favorites = ValueNotifier<Set<int>>({});

Future<void> toggle(int gameId) async {
  // Build a NEW set so the ValueNotifier sees a different value and notifies.
  final updated = Set<int>.from(favorites.value);
  if (!updated.add(gameId)) {  // add returns false if it was already there
    updated.remove(gameId);    // so this is the "remove" case
  }
  favorites.value = updated;   // this line wakes up every listener
  await _persist();
}

Future<void> _persist() async {
  await _prefs.setStringList(
    'favorites', favorites.value.map((id) => id.toString()).toList());
}
```

**What this does:**

- `Set<int>` holds the ids of favorite games. A `Set` never keeps duplicates.
- `updated.add(gameId)` — `add` returns `true` if the id was new, or `false`
  if it was already a favorite. So one line both adds and removes: if it was
  already there, I remove it. This is the toggle.
- `favorites.value = updated` — I assign a **brand-new** set. A `ValueNotifier`
  only fires when the value *reference* changes, so building a fresh set (rather
  than editing the old one in place) is what makes the screens update.
- `setStringList('favorites', ...)` — saves the ids on the phone. `SharedPreferences`
  only saves text, so I turn each id into a string first. On the next app start,
  `init()` reads this list back, so favorites are remembered.

Because the favorites live in a `ValueNotifier`, every heart icon wraps itself in
a **`ValueListenableBuilder`**. When the favorite is toggled *anywhere* — on a
card, or on the detail page — every listening widget rebuilds itself. I never
pass callbacks between screens or call `setState` by hand to keep them in sync:

```dart
ValueListenableBuilder<Set<int>>(
  valueListenable: FavoritesService.instance.favorites,
  builder: (context, favorites, _) {
    final isFavorite = favorites.contains(game.id);
    return Icon(isFavorite ? Icons.favorite : Icons.favorite_border);
  },
);
```

**What this does:**

- `valueListenable:` — points at the favorites box to watch.
- `builder:` — runs again every time that box changes, with the latest set, and
  rebuilds just the icon (not the whole screen).
- The favorites screen uses the same trick around its whole grid, so removing a
  favorite makes that game disappear from the list immediately.

### 4.7 Animation

When you tap a card, a **Hero** animation makes the small image grow and fly into
the detail screen's header. The trick is simple: both images use the **same
tag**, so Flutter knows they are the same picture and animates between them.

On the card (small image):

```dart
Hero(
  tag: 'game-thumb-${game.id}',
  child: Image.network(game.thumbnail, height: 130, fit: BoxFit.cover),
);
```

On the detail page the big image sits inside the collapsing header (see 4.9),
but it still uses the **same tag**:

```dart
Hero(
  tag: 'game-thumb-${detail.id}',   // same tag as the card
  child: Image.network(detail.thumbnail, fit: BoxFit.cover),
);
```

**What this does:**

- `tag: 'game-thumb-${game.id}'` — a unique name made from the game's id. The
  card and the detail page use the same name for the same game.
- Because the tags match, Flutter plays a smooth grow-and-move animation when you
  open and close the detail page. I did not have to write the animation myself.

### 4.9 A collapsing header (`SliverAppBar` + `CustomScrollView`)

The detail page header isn't a fixed image any more. It's a **`SliverAppBar`**
inside a **`CustomScrollView`**, so as you scroll the big Hero image shrinks and
folds up into the top bar, leaving just the back arrow and the favorite heart:

```dart
CustomScrollView(
  slivers: [
    SliverAppBar(
      expandedHeight: 280,
      pinned: true,                       // the bar stays on screen when collapsed
      actions: [ /* favorite heart */ ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'game-thumb-${detail.id}',
          child: Image.network(detail.thumbnail, fit: BoxFit.cover),
        ),
      ),
    ),
    SliverToBoxAdapter(child: /* title, info, description, screenshots */),
  ],
)
```

**What this does:**

- A normal `ListView` can't make the app bar grow and shrink; a `CustomScrollView`
  can, because it scrolls a list of **slivers** (scrollable sections) together.
- `SliverAppBar(expandedHeight: 280)` — how tall the header is when fully open.
- `pinned: true` — keep a thin bar (with the back button and heart) on screen
  after the image has scrolled away.
- `FlexibleSpaceBar(background: ...)` — the part that collapses; I put the Hero
  image here so it both animates *into* the page and shrinks *as* you scroll.
- `SliverToBoxAdapter` — wraps my ordinary `Column` of text so a normal widget
  can sit inside the sliver list below the header.

### 4.10 Bottom tab bar navigation

After logging in you land on a `HomeShell` — a `Scaffold` with a bottom
**`TabBar`** that switches between the **Games** grid and your **Favorites**.
Before, favorites opened as a separate pushed page; now both are top-level tabs:

```dart
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),   // no accidental swipe-to-switch
          children: [GameGridScreen(), FavoritesScreen()],
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
```

**What this does:**

- `DefaultTabController(length: 2)` — creates and shares the controller that
  keeps the `TabBar` and the `TabBarView` on the same tab. No manual controller
  to set up or dispose.
- `TabBarView` — the body. It shows `GameGridScreen` or `FavoritesScreen`
  depending on the selected tab, and keeps each one's state alive.
- `physics: NeverScrollableScrollPhysics()` — turns *off* swipe-to-change-tab, so
  swiping inside the grid (or pull-to-refresh) never accidentally flips the tab.
  You switch tabs by tapping the bar.
- `bottomNavigationBar: ... TabBar(...)` — puts the tab bar at the bottom of the
  screen, styled in the app's cyan, with an icon + label per tab.

Each tab keeps its **own** `Scaffold` and app bar, so the grid still has its
search box, sort/filter row, and logout button, and the favorites screen keeps
its own title and controls.

### 4.8 Requirements checklist

| # | Requirement | Where it is |
|---|---|---|
| 1 | Call web APIs (JSON) → grid/list → detail; 2 or more calls | `api_service.dart` (`/games`, `/game?id=`); grid in `game_grid_screen.dart`, a row of screenshots in `detail_screen.dart` |
| 2 | Turn JSON into my own classes | `Game.fromJson`, `GameDetail.fromJson` in `models.dart` |
| 3 | Loading indicator | `LinearProgressIndicator` (grid), `CircularProgressIndicator` (detail/favorites/splash) |
| 4 | Show an error when loading fails | error views with **Retry** / **Go Back** in grid, detail, favorites |
| 5 | Pull-to-refresh | `RefreshIndicator` in `game_grid_screen.dart` |
| 6 | Search | Material 3 `SearchBar` (matches title or genre) plus **sort** (name / release date) and **category filter** — all on **both** the game grid and the favorites screen (`game_filter_bar.dart`) |
| 7 | Register / login with an API | Firebase Auth: email/password **+ register**, and Google Sign-In |
| 8 | Dialog or snackbar when login fails | `showSnackBar` with a clear message |
| 9 | Save data | `SharedPreferences` favorites in `favorites_service.dart` |
| 10 | Animation | `Hero` animation (grid → detail) |
| 11 | One technique not taught in class | see Section 5 (seven of them) |

---

## 5. Things that were not taught in class (bonus)

I had to learn these parts on my own. I only needed one for the requirement, but
I used eight:

1. **Firebase Authentication** — real login in the cloud (email/password),
   not a fake local login.
2. **Google Sign-In (v7 API)** — login with Google using the `google_sign_in`
   package, plus a popup on web (handled with a `kIsWeb` check).
3. **`StreamBuilder` as a login gate** — the screen changes by itself based on
   `authStateChanges()`, so I never call navigation by hand after login/logout.
4. **`SharedPreferences`** — saving favorites on the device, using one shared
   service class.
5. **`Hero` animation** — the shared image animation between two screens.
6. **`ValueNotifier` + `ValueListenableBuilder`** — a tiny state-management
   pattern. The favorites live in one notifier, and every heart icon listens to
   it, so toggling a favorite anywhere updates every screen automatically — no
   manual `setState` or callbacks passed between screens.
7. **`SliverAppBar` + `CustomScrollView`** — the collapsing image header on the
   detail page that folds into the top bar as you scroll.
8. **`TabBar` + `TabBarView` (`DefaultTabController`)** — the bottom tab bar that
   switches between the game grid and the favorites screen.

---

## 6. Project structure

```
lib/
├─ main.dart                     # start Firebase, load favorites, run the app
└─ src/
   ├─ app.dart                   # StreamBuilder login gate (splash / login / home)
   ├─ theme.dart                 # AppTheme — the colors
   ├─ data/
   │  ├─ api_service.dart        # two FreeToGame calls
   │  └─ models.dart             # Game, GameDetail (my own classes)
   ├─ services/
   │  ├─ auth_service.dart       # Firebase + Google sign-in
   │  └─ favorites_service.dart  # saving favorites with SharedPreferences
   └─ widgets/
      ├─ login_screen.dart
      ├─ home_shell.dart         # bottom TabBar: Games grid + Favorites
      ├─ game_grid_screen.dart   # grid + search + sort/filter + pull-to-refresh
      ├─ game_filter_bar.dart    # shared sort + category controls and logic
      ├─ game_card.dart          # Hero image + favorite button
      ├─ detail_screen.dart      # details + screenshots
      └─ favorites_screen.dart   # favorites grid + the same search/sort/filter + logout
```

---

## 7. What I learned

The biggest lesson: **one place to hold the state makes everything simpler.**
Once the `StreamBuilder` knew "who is logged in" and the `FutureBuilder` knew
"is the data loading, failed, or ready", I stopped writing manual navigation and
loading flags. The screen just follows the state. Setting up real Firebase login
(SHA-1 keys, OAuth client ids, the new v7 `google_sign_in`) took some work, but
it is the part that makes this feel like a real app and not just a class
exercise.

---

## 8. Try it yourself

```bash
git clone https://github.com/your-username/f2pgamer
cd f2pgamer
flutter pub get
flutter run
```

Firebase is already set up for Android through
`android/app/google-services.json`, so you do not need to do anything extra to
run it. (If you want to use your *own* Firebase project, run
`flutterfire configure` — see `FIREBASE_SETUP.md`.)

Thanks for reading! ⚡

*Built with Flutter for the 1142 Flutter final project.*
```
