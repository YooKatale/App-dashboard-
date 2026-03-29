import 'package:hooks_riverpod/hooks_riverpod.dart';

final authStateProvider = StateProvider<AuthState>((ref) {
  return const AuthState.unknown();
});

/// Helper to extract a profile pic URL from any user data map,
/// checking all keys used by the webapp.
String? extractProfilePicUrl(Map<String, dynamic>? userData) {
  if (userData == null) return null;
  final raw = userData['avatar']?.toString()
      ?? userData['profilePic']?.toString()
      ?? userData['profile_pic']?.toString()
      ?? userData['profileImage']?.toString()
      ?? userData['picture']?.toString()
      ?? userData['photoURL']?.toString()
      ?? userData['photoUrl']?.toString();
  if (raw == null || raw.trim().isEmpty) return null;
  if (raw.startsWith('http://') || raw.startsWith('https://') || raw.startsWith('data:')) return raw;
  return 'https://yookatale-server.onrender.com/$raw';
}

class AuthState {
  final bool isLoggedIn;
  final String? userId;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? profilePicUrl;

  const AuthState.unknown()
      : isLoggedIn = false,
        userId = null,
        email = null,
        firstName = null,
        lastName = null,
        profilePicUrl = null;

  const AuthState.loggedIn({
    this.userId,
    this.email,
    this.firstName,
    this.lastName,
    this.profilePicUrl,
  }) : isLoggedIn = true;

  const AuthState.loggedOut()
      : isLoggedIn = false,
        userId = null,
        email = null,
        firstName = null,
        lastName = null,
        profilePicUrl = null;
}
