class UserEntity {
  final String? id;
  final String name;
  final String? avatarPath;
  
  // These are user preferences/defaults
  final int defaultMangaReadTime; 
  final int defaultAnimeWatchTime; 
  final String defaultSearchType; // 'anime' or 'manga'
  final String defaultContentRating; // 'safe' or 'adult'
  
  final bool filter18Plus;

  UserEntity({
    this.id,
    required this.name,
    this.avatarPath,
    this.defaultMangaReadTime = 15,
    this.defaultAnimeWatchTime = 24,
    this.defaultSearchType = 'anime',
    this.defaultContentRating = 'safe',
    this.filter18Plus = false,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? avatarPath,
    int? defaultMangaReadTime,
    int? defaultAnimeWatchTime,
    String? defaultSearchType,
    String? defaultContentRating,
    bool? filter18Plus,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      defaultMangaReadTime: defaultMangaReadTime ?? this.defaultMangaReadTime,
      defaultAnimeWatchTime: defaultAnimeWatchTime ?? this.defaultAnimeWatchTime,
      defaultSearchType: defaultSearchType ?? this.defaultSearchType,
      defaultContentRating: defaultContentRating ?? this.defaultContentRating,
      filter18Plus: filter18Plus ?? this.filter18Plus,
    );
  }
}
