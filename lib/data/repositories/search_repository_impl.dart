import 'package:goon_tracker/data/remote/anilist_service.dart';
import 'package:goon_tracker/data/remote/mangadex_service.dart';
import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final AnilistService anilistService;
  final MangadexService mangadexService;

  SearchRepositoryImpl({
    required this.anilistService,
    required this.mangadexService,
  });

  @override
  Future<List<TrackableContent>> searchAnime(String query, {bool isAdult = false}) async {
    return await anilistService.searchAnime(query, isAdult: isAdult);
  }

  @override
  Future<List<TrackableContent>> searchManga(String query, {bool isAdult = false}) async {
    return await mangadexService.searchManga(query, isAdult);
  }
}
