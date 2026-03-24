class UserEntity {
  final String id;
  final String name;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String defaultSearchType;
  final String defaultContentRating;
  final int defaultAnimeWatchTime;
  final int defaultMangaReadTime;
  final bool filter18Plus;

  String get displayName => name;
  String get defaultSearchMedium => defaultSearchType;
  String get defaultAdultMode {
    switch (defaultContentRating) {
      case 'mixed':
      case 'explicitOnly':
      case 'off':
        return defaultContentRating;
      default:
        return 'off';
    }
  }
  int get avgChapterMinutes => defaultMangaReadTime;
  bool get blurCoverInPublic => filter18Plus;

  UserEntity({
    required this.id,
    required this.name,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
    this.defaultSearchType = 'anime',
    this.defaultContentRating = 'off',
    this.defaultAnimeWatchTime = 24,
    this.defaultMangaReadTime = 15,
    this.filter18Plus = false,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? avatarPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? defaultSearchType,
    String? defaultContentRating,
    int? defaultAnimeWatchTime,
    int? defaultMangaReadTime,
    bool? filter18Plus,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultSearchType: defaultSearchType ?? this.defaultSearchType,
      defaultContentRating: defaultContentRating ?? this.defaultContentRating,
      defaultAnimeWatchTime: defaultAnimeWatchTime ?? this.defaultAnimeWatchTime,
      defaultMangaReadTime: defaultMangaReadTime ?? this.defaultMangaReadTime,
      filter18Plus: filter18Plus ?? this.filter18Plus,
    );
  }
}
