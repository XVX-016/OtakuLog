import 'package:otakulog/domain/entities/anime.dart';
import 'package:otakulog/domain/entities/manga.dart';
import 'package:otakulog/domain/entities/trackable_content.dart';

int? getMaxAllowedProgress(
  TrackableContent content, {
  int? releaseCap,
}) {
  if (content is AnimeEntity) {
    if (content.totalEpisodes > 0) return content.totalEpisodes;
    if (releaseCap != null && releaseCap > 0) return releaseCap;
    return null;
  }

  if (content is MangaEntity) {
    if (content.totalChapters > 0) return content.totalChapters;
    if (releaseCap != null && releaseCap > 0) return releaseCap;
    return null;
  }

  return content.totalProgress > 0 ? content.totalProgress : releaseCap;
}

String progressUnitLabel(TrackableContent content) {
  return content is AnimeEntity ? 'episodes' : 'chapters';
}
