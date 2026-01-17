import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      if (data.session?.user != null) {
        _fetchUserData();
      }
      notifyListeners();
    });
    
    // Load user data on init if logged in
    if (currentUser != null) {
      _fetchUserData();
    }
  }
  
  // Fetch user data from Supabase
  Future<void> _fetchUserData() async {
    print('🔵 _fetchUserData: Starting...');
    if (currentUser == null) {
      print('❌ _fetchUserData: No current user');
      return;
    }
    
    try {
      print('🔵 _fetchUserData: Fetching for user ${currentUser!.id}');
      final response = await SupabaseConfig.client
          .from('profiles')
          .select('gemini_api_key, full_name')
          .eq('id', currentUser!.id)
          .single();
      
      print('✅ _fetchUserData: Response received: $response');
      
      if (response['gemini_api_key'] != null) {
        _geminiApiKey = response['gemini_api_key'];
        print('✅ _fetchUserData: API key loaded');
      }
      
      // Name is already in user metadata, but we can sync if needed
      notifyListeners();
    } catch (e) {
      print('❌ _fetchUserData ERROR: $e');
    }
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
  
  // Update User Name
  Future<bool> updateUserName(String newName) async {
    print('🔵 updateUserName: Starting with name: $newName');
    print('🔵 updateUserName: Current user ID: ${currentUser?.id}');
    
    try {
      // Update users table
      print('🔵 updateUserName: Updating users table...');
      await SupabaseConfig.client.from('profiles').update({
        'full_name': newName,
      }).eq('id', currentUser!.id);
      print('✅ updateUserName: Users table updated');
      
      // Update auth metadata
      print('🔵 updateUserName: Updating auth metadata...');
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(
          data: {'full_name': newName}, // Use 'full_name' for consistency with signUp
        ),
      );
      print('✅ updateUserName: Auth metadata updated');
      
      // Reload user data
      print('🔵 updateUserName: Refreshing session...');
      await SupabaseConfig.client.auth.refreshSession();
      print('✅ updateUserName: Session refreshed');
      
      notifyListeners();
      print('✅ updateUserName: SUCCESS');
      return true;
    } catch (e) {
      print('❌ updateUserName ERROR: $e');
      print('❌ Error type: ${e.runtimeType}');
      return false;
    }
  }
  
  // Update User Email
  Future<bool> updateUserEmail(String newEmail) async {
    print('🔵 updateUserEmail: Starting with email: $newEmail');
    print('🔵 updateUserEmail: Current user ID: ${currentUser?.id}');
    
    try {
      print('🔵 updateUserEmail: Updating auth email...');
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(email: newEmail),
      );
      print('✅ updateUserEmail: Email update initiated');
      print('ℹ️  User will receive confirmation email at $newEmail');
      
      notifyListeners();
      print('✅ updateUserEmail: SUCCESS');
      return true;
    } catch (e) {
      print('❌ updateUserEmail ERROR: $e');
      print('❌ Error type: ${e.runtimeType}');
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
  Future<void> setGeminiApiKey(String apiKey) async {
    print('🔵 setGeminiApiKey: Starting...');
    _geminiApiKey = apiKey;
    notifyListeners();
    
    // Persist to Supabase
    if (currentUser != null) {
      try {
        print('🔵 setGeminiApiKey: Saving to Supabase for user ${currentUser!.id}');
        await SupabaseConfig.client.from('profiles').update({
          'gemini_api_key': apiKey,
        }).eq('id', currentUser!.id);
        print('✅ setGeminiApiKey: Saved successfully');
      } catch (e) {
        print('❌ setGeminiApiKey ERROR: $e');
        print('❌ Error type: ${e.runtimeType}');
      }
    } else {
      print('❌ setGeminiApiKey: No current user');
    }
  }
  
  // Upload Profile Photo to Supabase Storage
  Future<bool> uploadProfilePhoto(XFile imageFile) async {
    debugPrint('🔵 uploadProfilePhoto: Starting upload...');
    
    if (currentUser == null) {
      debugPrint('🔴 uploadProfilePhoto: No current user!');
      return false;
    }
    
    debugPrint('🔵 uploadProfilePhoto: User ID = ${currentUser!.id}');
    
    try {
      final fileName = '${currentUser!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      debugPrint('🔵 uploadProfilePhoto: File name = $fileName');
      
      // Read file as bytes (works on web and mobile)
      final bytes = await imageFile.readAsBytes();
      debugPrint('🔵 uploadProfilePhoto: Read ${bytes.length} bytes');
      
      // Upload to Supabase Storage
      debugPrint('🔵 uploadProfilePhoto: Uploading to Supabase...');
      await SupabaseConfig.client.storage
          .from('avatars')
          .uploadBinary(fileName, bytes);
      debugPrint('✅ uploadProfilePhoto: Upload successful!');
      
      // Get public URL
      final avatarUrl = SupabaseConfig.client.storage
          .from('avatars')
          .getPublicUrl(fileName);
      debugPrint('🔵 uploadProfilePhoto: Avatar URL = $avatarUrl');
      
      // Update user metadata
      debugPrint('🔵 uploadProfilePhoto: Updating user metadata...');
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(
          data: {'avatar_url': avatarUrl},
        ),
      );
      debugPrint('✅ uploadProfilePhoto: User metadata updated!');
      
      notifyListeners();
      return true;
    } on StorageException catch (e) {
      debugPrint('🔴 uploadProfilePhoto: StorageException!');
      debugPrint('🔴 Error: ${e.message}');
      debugPrint('🔴 Status Code: ${e.statusCode}');
      return false;
    } catch (e) {
      debugPrint('🔴 uploadProfilePhoto: General Error!');
      debugPrint('🔴 Error: $e');
      debugPrint('🔴 Error type: ${e.runtimeType}');
      return false;
    }
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
