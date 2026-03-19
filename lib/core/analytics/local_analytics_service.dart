import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class AnalyticsSnapshot {
  final Map<String, int> counters;

  const AnalyticsSnapshot({this.counters = const {}});

  int countFor(String eventName) => counters[eventName] ?? 0;

  Map<String, dynamic> toJson() => {
        'counters': counters,
      };

  factory AnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    final rawCounters = (json['counters'] as Map? ?? const <String, dynamic>{})
        .map((key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0));
    return AnalyticsSnapshot(counters: rawCounters);
  }
}

class LocalAnalyticsService {
  static const String _fileName = 'local_analytics.json';

  Future<File> _file() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_fileName');
  }

  Future<AnalyticsSnapshot> load() async {
    try {
      final file = await _file();
      if (!await file.exists()) {
        return const AnalyticsSnapshot();
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return const AnalyticsSnapshot();
      }
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) {
        return const AnalyticsSnapshot();
      }
      return AnalyticsSnapshot.fromJson(json);
    } catch (_) {
      return const AnalyticsSnapshot();
    }
  }

  Future<void> track(String eventName) async {
    final snapshot = await load();
    final nextCounters = <String, int>{
      ...snapshot.counters,
      eventName: snapshot.countFor(eventName) + 1,
    };
    await _save(AnalyticsSnapshot(counters: nextCounters));
  }

  Future<void> reset() async {
    await _save(const AnalyticsSnapshot());
  }

  Future<void> _save(AnalyticsSnapshot snapshot) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(snapshot.toJson()), flush: true);
  }
}
