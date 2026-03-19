import 'package:goon_tracker/domain/entities/trackable_content.dart';
import 'package:goon_tracker/features/search/models/search_filters.dart';

class SearchResultItem {
  final String id;
  final TrackableContent content;
  final SearchMedium medium;
  final List<String> tags;
  final String? description;
  final double? score;
  final bool isAdult;
  final String? statusLabel;
  final List<String> creatorNames;
  final int? totalCount;
  final bool inLibrary;

  const SearchResultItem({
    required this.id,
    required this.content,
    required this.medium,
    this.tags = const [],
    this.description,
    this.score,
    this.isAdult = false,
    this.statusLabel,
    this.creatorNames = const [],
    this.totalCount,
    this.inLibrary = false,
  });

  SearchResultItem copyWith({
    TrackableContent? content,
    SearchMedium? medium,
    List<String>? tags,
    String? description,
    double? score,
    bool? isAdult,
    String? statusLabel,
    List<String>? creatorNames,
    int? totalCount,
    bool? inLibrary,
  }) {
    return SearchResultItem(
      id: id,
      content: content ?? this.content,
      medium: medium ?? this.medium,
      tags: tags ?? this.tags,
      description: description ?? this.description,
      score: score ?? this.score,
      isAdult: isAdult ?? this.isAdult,
      statusLabel: statusLabel ?? this.statusLabel,
      creatorNames: creatorNames ?? this.creatorNames,
      totalCount: totalCount ?? this.totalCount,
      inLibrary: inLibrary ?? this.inLibrary,
    );
  }
}
