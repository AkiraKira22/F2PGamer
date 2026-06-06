// Main List Model (API 1)
class Game {
  final int id;
  final String title;
  final String thumbnail;
  final String shortDescription;
  final String genre;
  final String platform;

  Game({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.shortDescription,
    required this.genre,
    required this.platform,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      shortDescription: json['short_description'] ?? '',
      genre: json['genre'] ?? '',
      platform: json['platform'] ?? '',
    );
  }
}

// Deep Detail Model (API 2)
class GameDetail {
  final int id;
  final String title;
  final String thumbnail;
  final String description;
  final String status;
  final String developer;
  final String publisher;
  final String releaseDate;
  final String gameUrl;
  final List<String> screenshots;

  GameDetail({
    required this.id,
    required this.title,
    required this.thumbnail,
    required this.description,
    required this.status,
    required this.developer,
    required this.publisher,
    required this.releaseDate,
    required this.gameUrl,
    required this.screenshots,
  });

  factory GameDetail.fromJson(Map<String, dynamic> json) {
    var screenshotList = json['screenshots'] as List? ?? [];
    List<String> imgUrls = screenshotList
        .map((item) => item['image'].toString())
        .toList()
        .cast<String>();

    return GameDetail(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      developer: json['developer'] ?? '',
      publisher: json['publisher'] ?? '',
      releaseDate: json['release_date'] ?? '',
      gameUrl: json['game_url'] ?? '',
      screenshots: imgUrls,
    );
  }
}
