import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:otakulog/features/downloads/models/downloaded_chapter.dart';

class DownloadedChapterStore {
  static const String _manifestFileName = 'downloaded_chapters.json';
  static const String _chaptersDirectoryName = 'chapters';

  Future<Directory> _documentsDir() async {
    return getApplicationDocumentsDirectory();
  }

  Future<File> _manifestFile() async {
    final dir = await _documentsDir();
    return File('${dir.path}/$_manifestFileName');
  }

  Future<Directory> chapterDirectory(String chapterId) async {
    final dir = await _documentsDir();
    final chaptersDir = Directory('${dir.path}/$_chaptersDirectoryName');
    if (!await chaptersDir.exists()) {
      await chaptersDir.create(recursive: true);
    }
    final chapterDir = Directory('${chaptersDir.path}/$chapterId');
    if (!await chapterDir.exists()) {
      await chapterDir.create(recursive: true);
    }
    return chapterDir;
  }

  Future<Directory> _existingChapterDirectory(String chapterId) async {
    final dir = await _documentsDir();
    return Directory('${dir.path}/$_chaptersDirectoryName/$chapterId');
  }

  Future<List<DownloadedChapter>> loadAll() async {
    try {
      final file = await _manifestFile();
      if (!await file.exists()) return const [];
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => DownloadedChapter.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ))
          .toList()
        ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
    } catch (_) {
      return const [];
    }
  }

  Future<DownloadedChapter?> getByChapterId(String chapterId) async {
    final all = await loadAll();
    for (final record in all) {
      if (record.chapterId == chapterId) {
        return record;
      }
    }
    return null;
  }

  Future<void> save(DownloadedChapter record) async {
    final all = await loadAll();
    final next = [
      record,
      ...all.where((item) => item.chapterId != record.chapterId),
    ];
    await _writeAll(next);
  }

  Future<void> delete(String chapterId) async {
    final all = await loadAll();
    final existing = all.where((item) => item.chapterId == chapterId).toList();
    for (final record in existing) {
      for (final path in record.localPaths) {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      }
      final dir = await _existingChapterDirectory(record.chapterId);
      if (await dir.exists()) {
        try {
          await dir.delete(recursive: true);
        } catch (_) {}
      }
    }
    await _writeAll(all.where((item) => item.chapterId != chapterId).toList());
  }

  Future<int> totalBytes() async {
    final all = await loadAll();
    return all.fold<int>(0, (sum, item) => sum + item.totalBytes);
  }

  Future<void> clearAll() async {
    final all = await loadAll();
    for (final item in all) {
      await delete(item.chapterId);
    }
    await _writeAll(const []);
  }

  Future<void> _writeAll(List<DownloadedChapter> records) async {
    final file = await _manifestFile();
    final payload = records.map((item) => item.toJson()).toList();
    await file.writeAsString(jsonEncode(payload), flush: true);
  }
}
