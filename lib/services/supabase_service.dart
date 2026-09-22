import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://hmltwrravmipwrlmjtcf.supabase.co';
  static const String supabasePublishableKey = 'sb_publishable_Cs378UcZ_Id37ZR2Y2D-Aw_BeGNY_eQ';

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isInitialized {
    try {
      return Supabase.instance.client.auth.currentSession != null || true;
    } catch (_) {
      return false;
    }
  }

  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabasePublishableKey,
        debug: kDebugMode,
      );
    } catch (e) {
      debugPrint("Supabase initialization error: $e");
    }
  }

  // Sign Up with Email & Password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (name != null && name.isNotEmpty) 'name': name,
      },
    );
  }

  // Sign In with Email & Password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign In with Google OAuth
  static Future<bool> signInWithGoogle({String? redirectTo}) async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
    );
  }

  // Sign Out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Fetch User Profile from 'profiles' table
  static Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("Error fetching profile from Supabase: $e");
      return null;
    }
  }

  // Upsert / Update User Profile in 'profiles' table
  static Future<bool> saveProfile(String userId, Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      payload['id'] = userId;
      payload['updated_at'] = DateTime.now().toUtc().toIso8601String();

      await client.from('profiles').upsert(payload);
      return true;
    } catch (e) {
      debugPrint("Error updating profile in Supabase: $e");
      return false;
    }
  }
}
