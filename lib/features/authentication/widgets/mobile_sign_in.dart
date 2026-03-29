import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../backend/backend_auth_services.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/push_notification_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/notification_polling_service.dart';
import '../../../services/error_handler_service.dart';
import '../../../app.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../authentication/providers/redirect_provider.dart';
// extractProfilePicUrl is defined in auth_provider.dart
import 'mobile_sign_up.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

class MobileSignInPage extends ConsumerStatefulWidget {
  const MobileSignInPage({super.key});

  @override
  ConsumerState<MobileSignInPage> createState() => _MobileSignInPageState();
}

class _MobileSignInPageState extends ConsumerState<MobileSignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _isPhoneLogin = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _checkForOAuthToken();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// After Google OAuth redirect, the URL may contain a token param.
  Future<void> _checkForOAuthToken() async {
    try {
      final uri = Uri.base;
      final token = uri.queryParameters['token'] ??
          uri.queryParameters['access_token'] ??
          uri.queryParameters['jwt'];
      if (token == null || token.isEmpty) return;

      setState(() => _isGoogleLoading = true);

      await AuthService.saveToken(token);

      // Fetch user profile using /api/auth/me
      try {
        final response = await http.get(
          Uri.parse('${AuthService.baseUrl}/auth/me'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          Map<String, dynamic>? userData;
          if (data is Map<String, dynamic>) {
            userData = data['user'] as Map<String, dynamic>? ?? data;
          }
          if (userData != null && userData.isNotEmpty) {
            await AuthService.saveUserData(userData);
            final userId =
                userData['_id']?.toString() ?? userData['id']?.toString();
            if (userId != null) {
              ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
                userId: userId,
                email: userData['email']?.toString(),
                firstName: userData['firstname']?.toString(),
                lastName: userData['lastname']?.toString(),
                profilePicUrl: extractProfilePicUrl(userData),
              );
            }
          }
        }
      } catch (e) {
        if (kDebugMode) print('Auth/me fetch error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully signed in with Google'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        final redirectRoute = ref.read(redirectRouteProvider);
        ref.read(redirectRouteProvider.notifier).state = null;
        Navigator.of(context).pushReplacementNamed(redirectRoute ?? '/home');
      }
    } catch (e) {
      if (kDebugMode) print('OAuth token check error: $e');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ── Email login ──────────────────────────────────────────────
  Future<void> _handleEmailLogin() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      String userName = _extractUserName(response);
      await Future.delayed(const Duration(milliseconds: 500));

      final userData = await AuthService.getUserData();
      if (userData != null && userData.isNotEmpty) {
        final userId =
            userData['_id']?.toString() ?? userData['id']?.toString();
        if (userId != null) {
          ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
            userId: userId,
            email: userData['email']?.toString(),
            firstName: userData['firstname']?.toString(),
            lastName: userData['lastname']?.toString(),
            profilePicUrl: extractProfilePicUrl(userData),
          );
          _initNotifications();
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, $userName!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        await _navigateAfterAuth();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context,
            message: ErrorHandlerService.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _extractUserName(Map<String, dynamic> response) {
    if (response['lastname'] != null) return response['lastname'].toString();
    if (response['firstname'] != null) return response['firstname'].toString();
    if (response['user'] is Map) {
      final u = response['user'] as Map<String, dynamic>;
      return u['lastname']?.toString() ??
          u['firstname']?.toString() ??
          u['email']?.toString() ??
          'User';
    }
    if (response['data'] is Map) {
      final d = response['data'] as Map<String, dynamic>;
      if (d['user'] is Map) {
        final u = d['user'] as Map<String, dynamic>;
        return u['lastname']?.toString() ??
            u['firstname']?.toString() ??
            'User';
      }
      return d['lastname']?.toString() ?? d['firstname']?.toString() ?? 'User';
    }
    return 'User';
  }

  Future<void> _initNotifications() async {
    try {
      await PushNotificationService.initialize();
      await NotificationService.initialize();
      NotificationPollingService.startPolling();
    } catch (_) {}
  }

  Future<void> _navigateAfterAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingPaymentUrl = prefs.getString('pending_payment_url');
    if (pendingPaymentUrl != null && mounted) {
      await prefs.remove('pending_payment_url');
      final uri = Uri.parse(pendingPaymentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        Navigator.of(context).pushReplacementNamed('/subscription');
      }
    } else if (mounted) {
      final redirectRoute = ref.read(redirectRouteProvider);
      ref.read(redirectRouteProvider.notifier).state = null;
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context)
            .pushReplacementNamed(redirectRoute ?? '/home');
      }
    }
  }

  // ── Phone login ──────────────────────────────────────────────
  Future<void> _handlePhoneLogin() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please enter your mobile number'),
          backgroundColor: Colors.red));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await AuthService.loginWithPhone(phone: _phoneController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('OTP sent to your phone'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context,
            message: ErrorHandlerService.getErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Google sign-in ───────────────────────────────────────────
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    if (kIsWeb) {
      await _handleWebGoogleSignIn();
    } else {
      await _handleMobileGoogleSignIn();
    }
  }

  /// Web: Redirect to backend OAuth (same flow as the webapp)
  Future<void> _handleWebGoogleSignIn() async {
    try {
      const apiOrigin = 'https://yookatale-server.onrender.com';
      final currentUrl = Uri.base.toString();
      final params = {
        'redirect': '/',
        'mode': 'signin',
        'return_token': '1',
        'callback_url': currentUrl,
      };
      final oauthUrl = Uri.parse('$apiOrigin/api/auth/google')
          .replace(queryParameters: params);

      if (kIsWeb) {
        // On web, use window.location.href equivalent via url_launcher
        final launched = await launchUrl(
          oauthUrl,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_self',
        );
        if (!launched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not open Google sign-in'),
            backgroundColor: Colors.red,
          ));
          setState(() => _isGoogleLoading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Google sign-in error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ));
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  /// Mobile: Use Firebase Google Sign-In
  Future<void> _handleMobileGoogleSignIn() async {
    try {
      final authBackend = AuthBackend();
      final user = await authBackend.signInWithGoogle();

      if (user != null && mounted) {
        final displayName = user.displayName ?? '';
        final nameParts = displayName.split(' ');
        final firstname = nameParts.isNotEmpty ? nameParts[0] : '';
        final lastname =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        final idToken = await user.getIdToken();
        if (idToken == null) throw Exception('Failed to get auth token');

        try {
          final backendResponse = await ApiService.googleAuth(
            idToken: idToken,
            email: user.email ?? '',
            firstName: firstname,
            lastName: lastname,
            photoUrl: user.photoURL ?? '',
          );

          if (backendResponse['token'] != null) {
            await AuthService.saveToken(backendResponse['token'] as String);
          }

          Map<String, dynamic> userData;
          if (backendResponse['_id'] != null) {
            userData = {
              '_id': backendResponse['_id'],
              'id': backendResponse['_id'],
              'email': backendResponse['email'] ?? user.email ?? '',
              'firstname': backendResponse['firstname'] ?? firstname,
              'lastname': backendResponse['lastname'] ?? lastname,
              'phone': backendResponse['phone'] ?? '',
              'avatar': backendResponse['avatar'] ?? user.photoURL,
            };
          } else {
            userData = {
              'id': user.uid,
              '_id': user.uid,
              'email': user.email ?? '',
              'firstname': firstname,
              'lastname': lastname,
              'phone': user.phoneNumber ?? '',
              'photoUrl': user.photoURL ?? '',
            };
          }
          await AuthService.saveUserData(userData);

          final userId =
              userData['_id']?.toString() ?? userData['id']?.toString();
          if (userId != null) {
            ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
              userId: userId,
              email: userData['email']?.toString(),
              firstName: userData['firstname']?.toString(),
              lastName: userData['lastname']?.toString(),
              profilePicUrl: extractProfilePicUrl(userData),
            );
          }
          _initNotifications();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Successfully signed in with Google'),
              backgroundColor: Colors.green,
            ));
            await _navigateAfterAuth();
          }
        } catch (backendError) {
          // Fallback: save Firebase data
          final userData = {
            'id': user.uid,
            '_id': user.uid,
            'email': user.email ?? '',
            'firstname': firstname,
            'lastname': lastname,
            'phone': user.phoneNumber ?? '',
            'photoUrl': user.photoURL ?? '',
          };
          await AuthService.saveToken(idToken);
          await AuthService.saveUserData(userData);

          final userId =
              userData['_id']?.toString() ?? userData['id']?.toString();
          if (userId != null) {
            ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
              userId: userId,
              email: userData['email']?.toString(),
              firstName: userData['firstname']?.toString(),
              lastName: userData['lastname']?.toString(),
              profilePicUrl: extractProfilePicUrl(userData),
            );
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Signed in (backend sync delayed): ${backendError.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.orange,
            ));
            Navigator.of(context)
                .pushReplacement(MaterialPageRoute(builder: (_) => App()));
          }
        }
      } else {
        if (kDebugMode) print('Google sign-in cancelled by user');
      }
    } catch (e) {
      final errorStr = e.toString();
      // Suppress cancellation errors - these are normal user actions
      if (errorStr.contains('canceled') || errorStr.contains('cancelled') || errorStr.contains('sign_in_canceled')) {
        if (kDebugMode) print('Google sign-in cancelled by user: $e');
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Failed: ${errorStr.replaceAll('Exception: ', '').replaceAll('AuthException: ', '')}'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isWide = w > 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: isWide ? w * 0.2 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),

                  // Logo
                  Center(
                    child: Image.asset(
                      'assets/logo1.webp',
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(Icons.shopping_cart,
                            size: 56, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                      fontFamily: 'Raleway',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to continue shopping',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Google button
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: (_isGoogleLoading || _isLoading)
                          ? null
                          : _handleGoogleSignIn,
                      icon: _isGoogleLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata,
                              size: 26, color: Color(0xFF4285F4)),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF3C4043),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Divider
                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or sign in with email',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ]),
                  const SizedBox(height: 20),

                  // Email/Phone toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => setState(() => _isPhoneLogin = false),
                        child: Text(
                          'Email',
                          style: TextStyle(
                            color: !_isPhoneLogin ? _green : Colors.grey,
                            fontWeight: !_isPhoneLogin
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Text('|'),
                      TextButton(
                        onPressed: () => setState(() => _isPhoneLogin = true),
                        child: Text(
                          'Phone',
                          style: TextStyle(
                            color: _isPhoneLogin ? _green : Colors.grey,
                            fontWeight: _isPhoneLogin
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (!_isPhoneLogin) ...[
                    _StyledField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'Enter your email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _StyledField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Enter your password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () async {
                          try {
                            final uri = Uri.parse(
                                'https://www.yookatale.app/signin?forgot=true');
                            await launchUrl(uri,
                                mode: LaunchMode.externalApplication);
                          } catch (_) {}
                        },
                        style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36)),
                        child: const Text('Forgot password?',
                            style: TextStyle(
                                color: _green,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ] else ...[
                    _StyledField(
                      controller: _phoneController,
                      label: 'Mobile Number',
                      hint: 'Enter your mobile number',
                      keyboardType: TextInputType.phone,
                      prefixWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 16),
                        child: const Text('+256',
                            style: TextStyle(
                                color: _green,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('We will send you a verification code',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Sign-in button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading || _isGoogleLoading
                          ? null
                          : (_isPhoneLogin
                              ? _handlePhoneLogin
                              : _handleEmailLogin),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: _green.withAlpha(150),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(
                                      Colors.white)))
                          : Text(_isPhoneLogin ? 'Send Code' : 'Sign In',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sign-up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?",
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14)),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MobileSignUpPage())),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(left: 4)),
                        child: const Text('Sign Up',
                            style: TextStyle(
                                color: _green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ],
                  ),

                  // Browse as guest
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => App())),
                      child: Text('Browse as guest',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                              decoration: TextDecoration.underline)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ── Styled text field ──────────────────────────────────────────
class _StyledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData? icon;
  final Widget? prefixWidget;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _StyledField({
    required this.controller,
    required this.label,
    required this.hint,
    this.icon,
    this.prefixWidget,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: prefixWidget ??
            (icon != null ? Icon(icon, color: _green, size: 20) : null),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _green, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5)),
      ),
      validator: validator,
    );
  }
}

