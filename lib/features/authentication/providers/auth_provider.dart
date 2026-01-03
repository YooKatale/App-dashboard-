import 'package:hooks_riverpod/hooks_riverpod.dart';

final authStateProvider = StateProvider<AuthState>((ref) {
  return const AuthState.unknown();
});

class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final String? email;
  final String? firstName;
  final String? lastName;

  const AuthState.unknown()
      : isLoggedIn = false,
        userId = null,
        email = null,
        firstName = null,
        lastName = null;

  const AuthState.loggedIn({
    this.userId,
    this.email,
    this.firstName,
    this.lastName,
  }) : isLoggedIn = true;

  const AuthState.loggedOut()
      : isLoggedIn = false,
        userId = null,
        email = null,
        firstName = null,
        lastName = null;
}
