import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/notification_service.dart';

/// Provider for notification count
final notificationCountProvider = StateNotifierProvider<NotificationCountNotifier, int>((ref) {
  return NotificationCountNotifier();
});

class NotificationCountNotifier extends StateNotifier<int> {
  NotificationCountNotifier() : super(0) {
    _loadCount();
    _startPeriodicCheck();
  }

  Future<void> _loadCount() async {
    final count = await NotificationService.getUnreadCount();
    state = count;
  }

  void _startPeriodicCheck() {
    Future.delayed(const Duration(seconds: 30), () {
      _loadCount();
      _startPeriodicCheck();
    });
  }

  Future<void> refresh() async {
    await _loadCount();
  }
}
