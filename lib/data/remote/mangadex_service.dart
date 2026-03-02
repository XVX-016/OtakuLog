import 'package:dio/dio.dart';
import 'package:goon_tracker/domain/entities/manga.dart';

class MangadexService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.mangadex.org'));

  Future<List<MangaEntity>> searchManga(String query, bool isAdult) async {
    if (query.isEmpty) {
      return fetchTrendingManga(isAdult);
    }

    final Map<String, dynamic> queryParams = {
      'title': query,
      'limit': 20,
      'includes[]': ['cover_art', 'author', 'artist'],
    };

    _addContentRating(queryParams, isAdult);

    final response = await _dio.get('/manga', queryParameters: queryParams);
    final List data = response.data['data'];
    
    return data.map((m) => _mapToEntity(m)).toList();
  }

  Future<List<MangaEntity>> fetchTrendingManga(bool isAdult) async {
    final Map<String, dynamic> queryParams = {
      'limit': 20,
      'includes[]': ['cover_art', 'author', 'artist'],
      'order[followedCount]': 'desc',
      'order[rating]': 'desc',
      'availableTranslatedLanguage[]': ['en'],
    };

    _addContentRating(queryParams, isAdult);

    final response = await _dio.get('/manga', queryParameters: queryParams);
    final List data = response.data['data'];
    
    return data.map((m) => _mapToEntity(m)).toList();
  }

  void _addContentRating(Map<String, dynamic> params, bool isAdult) {
    if (isAdult) {
      params['contentRating[]'] = ['safe', 'suggestive', 'erotica', 'pornographic'];
    } else {
      params['contentRating[]'] = ['safe', 'suggestive'];
    }
  }

  Future<int> fetchChapterCount(String mangaId) async {
    if (_chapterCountCache.containsKey(mangaId)) {
      return _chapterCountCache[mangaId]!;
    }
    try {
      final response = await _dio.get('/manga/$mangaId/feed', queryParameters: {
        'limit': 1,
        'offset': 0,
      });
      final total = response.data['total'] ?? 0;
      _chapterCountCache[mangaId] = total;
      return total;
    } catch (e) {
      return 0;
    }
  }

  Future<MangaEntity> fetchMangaDetails(String id) async {
    final response = await _dio.get('/manga/$id', queryParameters: {
      'includes[]': ['cover_art', 'author', 'artist'],
    });
    return _mapToEntity(response.data['data']);
  }

  MangaEntity _mapToEntity(Map<String, dynamic> m) {
    return MangaMapper.fromJson(m);
  }
}
