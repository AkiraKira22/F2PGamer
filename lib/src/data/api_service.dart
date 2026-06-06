import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

class ApiService {
  static const String baseUrl = 'https://www.freetogame.com/api';

  // API 1: Fetch all games for the GridView
  static Future<List<Game>> fetchGames() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/games'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Game.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load games. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // API 2: Fetch detailed info for a single game
  static Future<GameDetail> fetchGameDetail(int gameId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl/game?id=$gameId'));

      if (response.statusCode == 200) {
        return GameDetail.fromJson(json.decode(response.body));
      } else {
        throw Exception(
            'Failed to load game details. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
