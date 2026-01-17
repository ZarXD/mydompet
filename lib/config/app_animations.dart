class AppAnimations {
  // Animation durations
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  
  // Global toggle (can be disabled on low-end devices)
  static const bool enableAnimations = true;
  
  // Curve preferences
  static const animationCurve = Curves.easeOutCubic;
  
  // Delays
  static const Duration staggerDelay = Duration(milliseconds: 50);
  static const Duration pageTransition = Duration(milliseconds: 250);
}
