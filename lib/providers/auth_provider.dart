import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Get current user from Supabase
  User? get currentUser => SupabaseConfig.currentUser;
  bool get isAuthenticated => currentUser != null;
  
  String? get userId => currentUser?.id;
  String? get userEmail => currentUser?.email;
  String? get userName => currentUser?.userMetadata?['full_name'] ?? 
                          currentUser?.userMetadata?['name'] ??
                          currentUser?.email?.split('@').first;
  String? get avatarUrl => currentUser?.userMetadata?['avatar_url'];
  
  // Local storage for Gemini API key
  String? _geminiApiKey;
  String? get geminiApiKey => _geminiApiKey;
  
  // Deep link scheme for mobile
  static const String _redirectScheme = 'com.mydompet.app';
  static const String _redirectHost = 'login-callback';
  static String get mobileRedirectUrl => '$_redirectScheme://$_redirectHost';
  
  AuthProvider() {
    // Listen to auth state changes
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }
  
  // Email & Password Login
  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      _isLoading = false;
      notifyListeners();
      
      return response.user != null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Email & Password Register
  Future<bool> signUpWithEmail(String email, String password, String fullName) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      
      _isLoading = false;
      notifyListeners();
      
      return response.user != null;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Google Sign In (using Supabase OAuth)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      if (kIsWeb) {
        // For web, use popup mode
        await SupabaseConfig.client.auth.signInWithOAuth(
          OAuthProvider.google,
          authScreenLaunchMode: LaunchMode.platformDefault,
        );
      } else {
        // For mobile, use deep link redirect
        await SupabaseConfig.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: mobileRedirectUrl,
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Google Sign-In gagal: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Forgot Password
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      await SupabaseConfig.client.auth.resetPasswordForEmail(email);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan. Coba lagi.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Set Gemini API Key
  void setGeminiApiKey(String apiKey) {
    _geminiApiKey = apiKey;
    notifyListeners();
  }
  
  // Logout
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await SupabaseConfig.client.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
    
    _isLoading = false;
    _geminiApiKey = null;
    notifyListeners();
  }
  
  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
