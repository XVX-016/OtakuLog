import 'package:dio/dio.dart';
import 'package:goon_tracker/domain/entities/anime.dart';

class AnilistService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://graphql.anilist.co'));

  static const String _mediaFields = r'''
    id
    title { romaji english }
    coverImage { large }
    episodes
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

    final List media = response.data['data']['Page']['media'];
    return media.map((m) => _mapToEntity(m)).toList();
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
    return AnimeEntity(
      id: m['id'].toString(),
      title: m['title']['english'] ?? m['title']['romaji'],
      coverImage: m['coverImage']['large'],
      totalEpisodes: m['episodes'] ?? 0,
      currentEpisode: 0,
      status: AnimeStatus.watching,
      rating: m['averageScore'] != null ? m['averageScore'].toDouble() / 10.0 : null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((m['updatedAt'] ?? 0) * 1000),
    );
  }
}
