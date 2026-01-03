import 'package:hooks_riverpod/hooks_riverpod.dart';

// Provider to track cart item count
final cartCountProvider = StateProvider<int>((ref) => 0);

// Provider to refresh cart count
final cartRefreshProvider = StateProvider<int>((ref) => 0);
