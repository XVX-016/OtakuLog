import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class MangaReleaseCapCacheService {
  static const String _fileName = 'manga_release_caps.json';

  Future<File> _cacheFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<Map<String, int>> _readAll() async {
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return const {};
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return decoded.map<String, int>((key, value) {
        return MapEntry(key.toString(), (value as num?)?.toInt() ?? 0);
      });
    } catch (_) {
      return const {};
    }
  }

  Future<int?> loadFirst(Iterable<String> keys) async {
    final cache = await _readAll();
    for (final key in keys) {
      final value = cache[key];
      if (value != null && value > 0) {
        return value;
      }
    }
    return null;
  }

  Future<void> saveForKeys(Iterable<String> keys, int cap) async {
    if (cap <= 0) return;
    final cache = await _readAll();
    for (final key in keys.where((item) => item.trim().isNotEmpty)) {
      cache[key] = cap;
    }

    final file = await _cacheFile();
    await file.writeAsString(jsonEncode(cache), flush: true);
  }
}
