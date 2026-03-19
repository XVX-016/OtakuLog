import 'package:otakulog/data/remote/api_client.dart';

class AnilistClient {
  final ApiClient _client;

  AnilistClient(this._client);

  static const String _searchQuery = r'''
    query ($search: String, $page: Int, $perPage: Int) {
      Page(page: $page, perPage: $perPage) {
        media(search: $search, type: ANIME, isAdult: false) {
          id
          title {
            romaji
            english
          }
          coverImage {
            large
          }
          episodes
          averageScore
          duration
        }
      }
    }
  ''';

  Future<Map<String, dynamic>> searchAnime(String search, {int page = 1, int perPage = 20}) async {
    final response = await _client.post('', data: {
      'query': _searchQuery,
      'variables': {
        'search': search,
        'page': page,
        'perPage': perPage,
      },
    });
    return response.data;
  }
}
