import 'package:dio/dio.dart';
import 'package:goon_tracker/domain/entities/manga.dart';

class MangadexService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'https://api.mangadex.org'));

  Future<List<MangaEntity>> searchManga(String query, bool isAdult) async {
    final Map<String, dynamic> queryParams = {
      'title': query,
      'limit': 20,
      'includes[]': ['cover_art'],
    };

    if (isAdult) {
      queryParams['contentRating[]'] = ['safe', 'suggestive', 'erotica', 'pornographic'];
    } else {
      queryParams['contentRating[]'] = ['safe', 'suggestive'];
    }

    final response = await _dio.get('/manga', queryParameters: queryParams);
    final List data = response.data['data'];
    
    return data.map((m) => _mapToEntity(m)).toList();
  }

  Future<MangaEntity> fetchMangaDetails(String id) async {
    final response = await _dio.get('/manga/$id', queryParameters: {
      'includes[]': ['cover_art'],
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

    // fallback for cover image if details not available in search
    final coverUrl = coverFileName.isNotEmpty 
      ? 'https://uploads.mangadex.org/covers/${m['id']}/$coverFileName'
      : '';

    return MangaEntity(
      id: m['id'],
      title: attrs['title']['en'] ?? attrs['title']['ja'] ?? 'Unknown',
      coverImage: coverUrl,
      totalChapters: attrs['lastChapter'] != null ? int.tryParse(attrs['lastChapter']) ?? 0 : 0,
      currentChapter: 0,
      status: MangaStatus.reading,
      rating: null,
      isAdult: attrs['contentRating'] == 'erotica' || attrs['contentRating'] == 'pornographic',
      createdAt: DateTime.parse(attrs['createdAt']),
      updatedAt: DateTime.parse(attrs['updatedAt']),
    );
  }
}
