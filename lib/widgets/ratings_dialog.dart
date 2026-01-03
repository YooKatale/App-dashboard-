import 'package:flutter/material.dart';
import '../services/ratings_service.dart';

class RatingsDialog {
  static Future<void> showPlayStoreRatingDialog(BuildContext context) async {
    final shouldShow = await RatingsService.shouldShowPlayStoreRating();
    if (!shouldShow) return;

    await RatingsService.updateLastPlayStorePrompt();

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Enjoying YooKatale?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Your feedback helps us improve! Would you mind rating us on the Play Store?',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              await RatingsService.markPlayStoreRated();
              await RatingsService.openPlayStore();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Rate Now'),
          ),
        ],
      ),
    );
  }

  static Future<void> showServiceRatingDialog(BuildContext context) async {
    final shouldShow = await RatingsService.shouldShowServiceRating();
    if (!shouldShow) return;

    await RatingsService.updateLastServicePrompt();

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.feedback_outlined, color: Color.fromRGBO(24, 95, 45, 1), size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Rate Our Service',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'How would you rate your experience with YooKatale? Your feedback helps us serve you better!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              await RatingsService.markServiceRated();
              if (context.mounted) {
                Navigator.pop(context);
                // Navigate to service ratings page
                Navigator.pushNamed(context, '/service-ratings');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Rate Service'),
          ),
        ],
      ),
    );
  }
}
