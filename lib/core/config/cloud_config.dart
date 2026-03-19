import 'package:flutter_dotenv/flutter_dotenv.dart';

class CloudConfig {
  final String url;
  final String anonKey;

  const CloudConfig({
    required this.url,
    required this.anonKey,
  });

  bool get isValid => url.isNotEmpty && anonKey.isNotEmpty;

  static CloudConfig fromEnv() {
    final url = dotenv.maybeGet('SUPABASE_URL') ?? '';
    final anonKey = dotenv.maybeGet('SUPABASE_ANON_KEY') ?? '';
    return CloudConfig(url: url, anonKey: anonKey);
  }
}
