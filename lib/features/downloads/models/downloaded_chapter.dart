class DownloadedChapter {
  final String chapterId;
  final String mangaId;
  final String? mangaDexId;
  final String? mangaTitle;
  final String? chapterLabel;
  final String? chapterTitle;
  final List<String> localPaths;
  final int totalPages;
  final DateTime downloadedAt;
  final int totalBytes;

  const DownloadedChapter({
    required this.chapterId,
    required this.mangaId,
    this.mangaDexId,
    this.mangaTitle,
    this.chapterLabel,
    this.chapterTitle,
    required this.localPaths,
    required this.totalPages,
    required this.downloadedAt,
    required this.totalBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      'chapterId': chapterId,
      'mangaId': mangaId,
      'mangaDexId': mangaDexId,
      'mangaTitle': mangaTitle,
      'chapterLabel': chapterLabel,
      'chapterTitle': chapterTitle,
      'localPaths': localPaths,
      'totalPages': totalPages,
      'downloadedAt': downloadedAt.toIso8601String(),
      'totalBytes': totalBytes,
    };
  }

  factory DownloadedChapter.fromJson(Map<String, dynamic> json) {
    return DownloadedChapter(
      chapterId: json['chapterId']?.toString() ?? '',
      mangaId: json['mangaId']?.toString() ?? '',
      mangaDexId: json['mangaDexId']?.toString(),
      mangaTitle: json['mangaTitle']?.toString(),
      chapterLabel: json['chapterLabel']?.toString(),
      chapterTitle: json['chapterTitle']?.toString(),
      localPaths: (json['localPaths'] as List? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(),
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
      downloadedAt: DateTime.tryParse(json['downloadedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      totalBytes: (json['totalBytes'] as num?)?.toInt() ?? 0,
    );
  }
}
