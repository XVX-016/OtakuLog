import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient? _client;

  AuthService({SupabaseClient? client}) : _client = client;

  bool get isAvailable => _client != null;

  User? getCurrentUser() => _client?.auth.currentUser;

  Session? getCurrentSession() => _client?.auth.currentSession;

  Stream<AuthState> authStateChanges() {
    final client = _client;
    if (client == null) {
      return const Stream<AuthState>.empty();
    }
    return client.auth.onAuthStateChange;
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    return client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final client = _requireClient();
    return client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    final client = _requireClient();
    await client.auth.signOut();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Cloud is not configured for this build.');
    }
    return client;
  }
}
