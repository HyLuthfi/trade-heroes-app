import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://hmltwrravmipwrlmjtcf.supabase.co';
  static const String supabasePublishableKey = 'sb_publishable_Cs378UcZ_Id37ZR2Y2D-Aw_BeGNY_eQ';

  static SupabaseClient get client => Supabase.instance.client;

  static bool get isInitialized {
    try {
      final _ = Supabase.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  static User? get currentUser {
    if (!isInitialized) return null;
    try {
      return client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

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

  // Upload user avatar image to Supabase Storage 'avatars' bucket
  static Future<String?> uploadAvatar({
    required String userId,
    required Uint8List bytes,
    required String fileExt,
  }) async {
    try {
      final fileName = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      await client.storage.from('avatars').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );
      final publicUrl = client.storage.from('avatars').getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading avatar to Supabase Storage: $e");
      return null;
    }
  }

  // Fetch All Profiles (Admin Console)
  static Future<List<Map<String, dynamic>>> fetchAllProfiles() async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching all profiles: $e");
      return [];
    }
  }

  // Admin Update User Profile
  static Future<bool> adminUpdateProfile(String targetUserId, Map<String, dynamic> updates) async {
    try {
      final payload = Map<String, dynamic>.from(updates);
      payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
      await client.from('profiles').update(payload).eq('id', targetUserId);
      return true;
    } catch (e) {
      debugPrint("Error in adminUpdateProfile: $e");
      return false;
    }
  }
}
