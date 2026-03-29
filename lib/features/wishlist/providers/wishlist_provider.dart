import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/wishlist_service.dart';

/// Notifier to refresh wishlist (increment to trigger refetch)
final wishlistRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider for wishlist items - syncs with web wishlistSlice (localStorage)
final wishlistProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.watch(wishlistRefreshProvider);
  return WishlistService.loadWishlist();
});
