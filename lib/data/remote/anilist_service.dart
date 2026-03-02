import 'package:dio/dio.dart';
import 'package:goon_tracker/domain/entities/anime.dart';

class AnilistService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://graphql.anilist.co'));

  static const String _mediaFields = r'''
    id
    title { romaji english native }
    coverImage { large }
    episodes
    genres
    description(asHtml: false)
    averageScore
    updatedAt
  ''';

  Future<List<AnimeEntity>> searchAnime(String query, {bool isAdult = false}) async {
    const String graphQLQuery = r'''
      query ($search: String, $isAdult: Boolean) {
        Page(perPage: 20) {
          media(search: $search, type: ANIME, isAdult: $isAdult) {
            ''' + _mediaFields + r'''
          }
        }
      }
    ''';

    final response = await _dio.post('', data: {
      'query': graphQLQuery,
      'variables': {'search': query, 'isAdult': isAdult},
    });

    final List mediaList = response.data['data']['Page']['media'];
    return mediaList.map((m) => _mapToEntity(m)).toList();
  }

  Future<List<AnimeEntity>> fetchTrendingAnime() async {
    const String graphQLQuery = r'''
      query {
        Page(page: 1, perPage: 10) {
          media(type: ANIME, sort: TRENDING_DESC) {
            ''' + _mediaFields + r'''
          }
        }
      }
    ''';

    final response = await _dio.post('', data: {
      'query': graphQLQuery,
    });

    final List mediaList = response.data['data']['Page']['media'];
    return mediaList.map((m) => _mapToEntity(m)).toList();
  }

  Future<AnimeEntity> fetchAnimeDetails(String id) async {
    const String graphQLQuery = r'''
      query ($id: Int) {
        Media(id: $id, type: ANIME) {
          ''' + _mediaFields + r'''
        }
      }
    ''';

    final response = await _dio.post('', data: {
      'query': graphQLQuery,
      'variables': {'id': int.parse(id)},
    });

    return _mapToEntity(response.data['data']['Media']);
  }

  AnimeEntity _mapToEntity(Map<String, dynamic> m) {
    return AnimeMapper.fromJson(m);
  }
}
