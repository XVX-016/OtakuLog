import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:goon_tracker/app/app.dart';
import 'package:goon_tracker/data/local/isar_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.init();
  
  runApp(
    const ProviderScope(
      child: GoonTrackerApp(),
    ),
  );
}
