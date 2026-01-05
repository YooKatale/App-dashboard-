import 'package:bcrypt/bcrypt.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:yookatale/backend/secure_random.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthBackend {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Configure Google Sign-In with serverClientId for Android
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: '573491167004-h75897imc0s8g93amcbb37cfqktt1r8f.apps.googleusercontent.com', // Web client ID from google-services.json
  );
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureRandom _secureRandom = SecureRandom();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log user registration event
      _analytics.logEvent(name: 'user_registration', parameters: null);

      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        print('Email/Password Sign-Up Error: $e');
      }
      throw AuthException('Failed to sign up: $e');
    }
  }

  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePhotoURL(photoURL);
        await user.updateDisplayName(displayName);
        await user.reload();

        // Log profile update event
        _analytics.logEvent(name: 'profile_update', parameters: null);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update Profile Error: $e');
      }
      throw AuthException('Failed to update profile: $e');
    }
  }

  Future<void> storeSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      if (kDebugMode) {
        print('Secure Storage Error: $e');
      }
      throw AuthException('Failed to store secure data: $e');
    }
  }

  Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      if (kDebugMode) {
        print('Secure Storage Error: $e');
      }
      throw AuthException('Failed to retrieve secure data: $e');
    }
  }

  Future<String> hashPassword(String password) async {
    try {
      final String salt = _secureRandom.nextString(16);
      return BCrypt.hashpw(password, salt);
    } catch (e) {
      if (kDebugMode) {
        print('Password Hashing Error: $e');
      }
      throw AuthException('Failed to hash password: $e');
    }
  }

  Future<void> logEvent(String eventName,
      [Map<String, dynamic>? eventData]) async {
    try {
      Map<String, Object>? params;
      if (eventData != null) {
        params = <String, Object>{};
        eventData.forEach((key, value) {
          if (value != null) params![key] = value as Object;
        });
      }
      await _analytics.logEvent(
        name: eventName,
        parameters: params,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Logging Error: $e');
      }
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      // Log password reset email sent event
      _analytics.logEvent(name: 'password_reset_email_sent', parameters: null);
    } catch (e) {
      if (kDebugMode) {
        print('Password Reset Error: $e');
      }
      throw AuthException('Failed to send password reset email: $e');
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();

        // Log email verification email sent event
        _analytics.logEvent(
            name: 'email_verification_email_sent', parameters: null);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Email Verification Error: $e');
      }
      throw AuthException('Failed to send email verification: $e');
    }
  }

  Future<void> deleteUserAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();

        // Log account deleted event
        _analytics.logEvent(name: 'account_deleted', parameters: null);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Delete User Account Error: $e');
      }
      throw AuthException('Failed to delete user account: $e');
    }
  }

  Future<void> refreshToken() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.getIdToken(true);

        // Log token refresh event
        _analytics.logEvent(name: 'token_refreshed', parameters: null);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Token Refresh Error: $e');
      }
      throw AuthException('Failed to refresh token: $e');
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      // Sign in with Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Get authorization client for access token
      final GoogleSignInClientAuthorization? clientAuth =
          await googleUser.authorizationClient.authorizationForScopes(
        <String>['email', 'profile', 'openid'],
      );

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: clientAuth?.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      // Log Google sign-in event
      _analytics.logEvent(name: 'google_sign_in', parameters: null);

      return userCredential.user;
    } catch (e) {
      if (kDebugMode) {
        print('Google Sign-In Error: $e');
      }
      throw AuthException('Failed to sign in with Google: $e');
    }
  }

  // Facebook sign-in removed - package causing build issues
  // Future<User?> signInWithFacebook() async {
  //   try {
  //     final LoginResult result = await _facebookSignIn.login();
  //     if (result.status != LoginStatus.success) return null;
  //
  //     final AuthCredential credential =
  //         FacebookAuthProvider.credential(result.accessToken!.token);
  //
  //     final UserCredential userCredential =
  //         await _auth.signInWithCredential(credential);
  //
  //     // Log Facebook sign-in event
  //     _analytics.logEvent(name: 'facebook_sign_in', parameters: null);
  //
  //     return userCredential.user;
  //   } catch (e) {
  //     if (kDebugMode) {
  //       print('Facebook Sign-In Error: $e');
  //     }
  //     throw AuthException('Failed to sign in with Facebook: $e');
  //   }
  // }

  Future<User?> signInWithPhoneNumber(String phoneNumber) async {
    try {
      verificationCompleted(AuthCredential phoneAuthCredential) {
        _auth.signInWithCredential(phoneAuthCredential);
      }

      verificationFailed(FirebaseAuthException authException) {
        if (kDebugMode) {
          print('Phone Verification Error: $authException');
        }
      }

      codeSent(String verificationId, [int? forceResendingToken]) async {
        final String? smsCode = await _secureStorage.read(key: 'smsCode');
        final AuthCredential phoneAuthCredential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode!,
        );
        await _auth.signInWithCredential(phoneAuthCredential);
      }

      codeAutoRetrievalTimeout(String verificationId) {}

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );

      // Log phone number sign-in event
      _analytics.logEvent(name: 'phone_number_sign_in', parameters: null);

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Phone Number Sign-In Error: $e');
      }
      throw AuthException('Failed to sign in with phone number: $e');
    }
  }

  Future<Map<String, dynamic>> authenticateWithFingerprint() async {
    try {
      // Check if device supports biometric authentication
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      if (!isDeviceSupported) {
        return {
          'success': false,
          'error': 'Biometric authentication is not available on this device.',
          'errorType': 'not_supported',
        };
      }

      // Check available biometric types
      final List<BiometricType> availableBiometrics = await _localAuth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return {
          'success': false,
          'error': 'No biometric authentication methods are enrolled. Please set up fingerprint or face ID in device settings.',
          'errorType': 'not_enrolled',
        };
      }

      // Check if biometrics can be checked
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return {
          'success': false,
          'error': 'Biometric authentication is not available. Please enable it in device settings.',
          'errorType': 'not_available',
        };
      }

      // Perform authentication
      final bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to continue',
        biometricOnly: true,
        sensitiveTransaction: true,
      );

      if (isAuthenticated) {
        // Log successful authentication
        _analytics.logEvent(
          name: 'biometric_authentication_success',
          parameters: {
            'biometric_type': availableBiometrics.first.toString(),
          },
        );

        return {
          'success': true,
          'message': 'Authentication successful',
        };
      } else {
        return {
          'success': false,
          'error': 'Authentication failed or was cancelled.',
          'errorType': 'failed',
        };
      }
    } on PlatformException catch (e) {
      String errorMessage = 'Biometric authentication failed.';
      String errorType = 'unknown';

      if (e.code == 'NotAvailable') {
        errorMessage = 'Biometric authentication is not available on this device.';
        errorType = 'not_available';
      } else if (e.code == 'NotEnrolled') {
        errorMessage = 'No biometric authentication methods are enrolled. Please set up fingerprint or face ID in device settings.';
        errorType = 'not_enrolled';
      } else if (e.code == 'LockedOut') {
        errorMessage = 'Biometric authentication is temporarily locked. Please try again later or use your password.';
        errorType = 'locked_out';
      } else if (e.code == 'PermanentlyLockedOut') {
        errorMessage = 'Biometric authentication is permanently locked. Please use your password.';
        errorType = 'permanently_locked_out';
      } else if (e.code == 'UserCancel') {
        errorMessage = 'Authentication was cancelled.';
        errorType = 'cancelled';
      } else {
        errorMessage = 'Biometric authentication error: ${e.message ?? 'Unknown error'}';
      }

      if (kDebugMode) {
        print('Fingerprint authentication error: $e');
      }

      // Log authentication failure
      _analytics.logEvent(
        name: 'biometric_authentication_failed',
        parameters: {
          'error_code': e.code,
          'error_type': errorType,
        },
      );

      return {
        'success': false,
        'error': errorMessage,
        'errorType': errorType,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Fingerprint authentication error: $e');
      }
      return {
        'success': false,
        'error': 'An unexpected error occurred during authentication. Please try again.',
        'errorType': 'unknown',
      };
    }
  }
}
