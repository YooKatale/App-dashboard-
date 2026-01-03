import 'package:hooks_riverpod/hooks_riverpod.dart';

// Provider to store the route user was trying to access before login
final redirectRouteProvider = StateProvider<String?>((ref) => null);
