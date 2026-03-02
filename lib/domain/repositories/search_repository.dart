import 'package:goon_tracker/domain/entities/trackable_content.dart';

abstract class SearchRepository {
  Future<List<TrackableContent>> searchAnime(String query, {bool isAdult = false});
  Future<List<TrackableContent>> searchManga(String query, {bool isAdult = false});
  Future<List<TrackableContent>> getTrendingAnime();
  Future<List<TrackableContent>> getTrendingManga({bool isAdult = false});
}
