import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Fallback values if .env fails to load
  static const String _fallbackUrl = 'SUPAURL';
  static const String _fallbackKey = 'SUPAKEY';
  
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? _fallbackUrl;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? _fallbackKey;
  
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      debugPrint('Warning: Could not load .env file, using fallback values');
    }
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
  
  static SupabaseClient get client => Supabase.instance.client;
  
  static User? get currentUser => client.auth.currentUser;
  
  static bool get isAuthenticated => currentUser != null;
  
  static Session? get currentSession => client.auth.currentSession;
}
