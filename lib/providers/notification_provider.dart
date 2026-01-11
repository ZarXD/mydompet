import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _notificationsKey = 'notifications_enabled';
  
  bool _notificationsEnabled = false;
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get isInitialized => _isInitialized;

  NotificationProvider() {
    _init();
  }

  Future<void> _init() async {
    await _notificationService.init();
    await _loadSettings();
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? false;
      
      // If enabled, ensure permissions are granted and scheduled
      if (_notificationsEnabled) {
        await _notificationService.requestPermissions();
        // Re-schedule to be safe
        await _notificationService.scheduleDailyReminder();
      }
    } catch (e) {
      _notificationsEnabled = false;
    }
  }

  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, value);

      if (value) {
        final granted = await _notificationService.requestPermissions();
        if (granted == true) {
          await _notificationService.scheduleDailyReminder();
        } else {
          // If permission denied, revert toggle
          _notificationsEnabled = false;
          await prefs.setBool(_notificationsKey, false);
          notifyListeners();
        }
      } else {
        await _notificationService.cancelAllNotifications();
      }
    } catch (e) {
      // Ignore errors
    }
  }
}
