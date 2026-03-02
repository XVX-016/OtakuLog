import 'package:goon_tracker/data/remote/api_client.dart';

class MangadexClient {
  final ApiClient _client;

  MangadexClient(this._client);

  Future<Map<String, dynamic>> searchManga(String title, {int limit = 20}) async {
    final response = await _client.get('/manga', queryParameters: {
      'title': title,
      'limit': limit,
      'includes[]': ['cover_art'],
      'contentRating[]': ['safe', 'suggestive'],
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMangaAggregate(String mangaId) async {
    final response = await _client.get('/manga/$mangaId/aggregate');
    return response.data;
  }
}
