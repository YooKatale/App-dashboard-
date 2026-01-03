import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RatingsService {
  static const String _playStoreRatedKey = 'playstore_rated';
  static const String _serviceRatedKey = 'service_rated';
  static const String _lastPlayStorePromptKey = 'last_playstore_prompt';
  static const String _lastServicePromptKey = 'last_service_prompt';
  static const String _appOpenCountKey = 'app_open_count';
  static const String _interactionCountKey = 'interaction_count';

  // Check if user should see Play Store rating prompt
  static Future<bool> shouldShowPlayStoreRating() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Don't show if already rated
    if (prefs.getBool(_playStoreRatedKey) == true) {
      return false;
    }

    // Get app open count
    final openCount = prefs.getInt(_appOpenCountKey) ?? 0;
    
    // Show after 5 app opens
    if (openCount >= 5) {
      final lastPrompt = prefs.getInt(_lastPlayStorePromptKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Don't show more than once per week
      if (now - lastPrompt > 7 * 24 * 60 * 60 * 1000) {
        return true;
      }
    }
    
    return false;
  }

  // Check if user should see service rating prompt
  static Future<bool> shouldShowServiceRating() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Don't show if already rated
    if (prefs.getBool(_serviceRatedKey) == true) {
      return false;
    }

    // Get interaction count (orders, purchases, etc.)
    final interactionCount = prefs.getInt(_interactionCountKey) ?? 0;
    
    // Show after 3 interactions
    if (interactionCount >= 3) {
      final lastPrompt = prefs.getInt(_lastServicePromptKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Don't show more than once per 2 weeks
      if (now - lastPrompt > 14 * 24 * 60 * 60 * 1000) {
        return true;
      }
    }
    
    return false;
  }

  // Mark Play Store as rated
  static Future<void> markPlayStoreRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_playStoreRatedKey, true);
  }

  // Mark service as rated
  static Future<void> markServiceRated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_serviceRatedKey, true);
  }

  // Increment app open count
  static Future<void> incrementAppOpenCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_appOpenCountKey) ?? 0) + 1;
    await prefs.setInt(_appOpenCountKey, count);
  }

  // Increment interaction count
  static Future<void> incrementInteractionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_interactionCountKey) ?? 0) + 1;
    await prefs.setInt(_interactionCountKey, count);
  }

  // Update last prompt time
  static Future<void> updateLastPlayStorePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPlayStorePromptKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> updateLastServicePrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastServicePromptKey, DateTime.now().millisecondsSinceEpoch);
  }

  // Open Play Store
  static Future<void> openPlayStore() async {
    const url = 'https://play.google.com/store/apps/details?id=com.yookatale.app';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
