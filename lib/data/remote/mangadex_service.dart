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

  Future<MangaEntity> fetchMangaDetails(String id) async {
    final response = await _dio.get('/manga/$id', queryParameters: {
      'includes[]': ['cover_art', 'author', 'artist'],
    });
    return _mapToEntity(response.data['data']);
  }

  MangaEntity _mapToEntity(Map<String, dynamic> m) {
    final attrs = m['attributes'];
    final relationships = m['relationships'] as List;
    
    String coverFileName = '';
    final coverRel = relationships.firstWhere((r) => r['type'] == 'cover_art', orElse: () => null);
    if (coverRel != null && coverRel['attributes'] != null) {
       coverFileName = coverRel['attributes']['fileName'] ?? '';
    }

    final coverUrl = coverFileName.isNotEmpty 
      ? 'https://uploads.mangadex.org/covers/${m['id']}/$coverFileName'
      : '';

    final genres = (attrs['tags'] as List? ?? [])
        .map((tag) => tag['attributes']['name']['en'] as String)
        .toList();

    return MangaEntity(
      id: m['id'],
      title: attrs['title']['en'] ?? attrs['title'].values.first ?? 'Unknown',
      coverImage: coverUrl,
      totalChapters: attrs['lastChapter'] != null ? int.tryParse(attrs['lastChapter']) ?? 0 : 0,
      currentChapter: 0,
      status: MangaStatus.reading,
      rating: null,
      genres: genres,
      description: attrs['description']['en'],
      isAdult: attrs['contentRating'] == 'erotica' || attrs['contentRating'] == 'pornographic',
      createdAt: DateTime.parse(attrs['createdAt']),
      updatedAt: DateTime.parse(attrs['updatedAt']),
    );
  }
}
