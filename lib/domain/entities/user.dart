class UserEntity {
  final String? id;
  final String name;
  final String? avatarPath;
  final int avgMangaReadTime; // in minutes
  final int avgAnimeWatchTime; // in minutes
  final bool filter18Plus;

  UserEntity({
    this.id,
    required this.name,
    this.avatarPath,
    this.avgMangaReadTime = 15,
    this.avgAnimeWatchTime = 24,
    this.filter18Plus = false,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? avatarPath,
    int? avgMangaReadTime,
    int? avgAnimeWatchTime,
    bool? filter18Plus,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      avgMangaReadTime: avgMangaReadTime ?? this.avgMangaReadTime,
      avgAnimeWatchTime: avgAnimeWatchTime ?? this.avgAnimeWatchTime,
      filter18Plus: filter18Plus ?? this.filter18Plus,
    );
  }
}
