import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../backend/backend_auth_services.dart';
import '../../../services/auth_service.dart';
import '../../../services/push_notification_service.dart';
import '../../../services/error_handler_service.dart';
import '../../../app.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../authentication/providers/redirect_provider.dart';
import 'mobile_sign_up.dart';

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
  bool _isPhoneLogin = false;
  bool _biometricAvailable = false; // Check if device supports biometrics
  
  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }
  
  Future<void> _checkBiometricAvailability() async {
    try {
      final authBackend = AuthBackend();
      final isSupported = await authBackend.isBiometricSupported();
      if (mounted) {
        setState(() {
          _biometricAvailable = isSupported;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _biometricAvailable = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Extract user name from response (like webapp: res?.lastname || res?.firstname || 'User')
      String? userName;
      if (response['lastname'] != null) {
        userName = response['lastname'].toString();
      } else if (response['firstname'] != null) {
        userName = response['firstname'].toString();
      } else if (response['user'] != null && response['user'] is Map) {
        final user = response['user'] as Map<String, dynamic>;
        userName = user['lastname']?.toString() ?? 
                  user['firstname']?.toString() ?? 
                  user['email']?.toString();
      } else if (response['data'] != null && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        if (data['user'] != null && data['user'] is Map) {
          final user = data['user'] as Map<String, dynamic>;
          userName = user['lastname']?.toString() ?? 
                    user['firstname']?.toString() ?? 
                    user['email']?.toString();
        } else {
          userName = data['lastname']?.toString() ?? 
                    data['firstname']?.toString() ?? 
                    data['email']?.toString();
        }
      }
      
      if (userName == null || userName.isEmpty) {
        userName = 'User';
      }
      
      // AuthService.login already saved the entire response (like webapp: dispatch(setCredentials({ ...res })))
      // Wait for data to be fully persisted
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get user data from storage (like webapp: useSelector((state) => state.auth).userInfo)
      // The webapp checks: if (!userInfo || userInfo == {} || userInfo == "") or userInfo?._id
      final userData = await AuthService.getUserData();
      
      // Check if we have valid user data (like webapp checks userInfo?._id)
      if (userData != null && userData.isNotEmpty) {
        // Check if it has _id or id (like webapp checks userInfo?._id)
        final userId = userData['_id']?.toString() ?? 
                      userData['id']?.toString();
        
        if (userId != null) {
          // Update auth state provider (like webapp updates Redux state)
          ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
            userId: userId,
            email: userData['email']?.toString(),
            firstName: userData['firstname']?.toString(),
            lastName: userData['lastname']?.toString(),
          );
          
          // Initialize push notifications after login (like webapp)
          try {
            await PushNotificationService.initialize();
          } catch (e) {
            // Non-blocking - notifications will work even if init fails
          }
        }
      }

      if (mounted) {
        // Show success message (like webapp shows toast: "Successfully logged in as ${res?.lastname || res?.firstname || 'User'}")
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully logged in as $userName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Check for pending payment URL first
        final prefs = await SharedPreferences.getInstance();
        final pendingPaymentUrl = prefs.getString('pending_payment_url');
        
        if (pendingPaymentUrl != null && mounted) {
          // Clear the pending payment URL
          await prefs.remove('pending_payment_url');
          
          // Redirect to payment URL
          final uri = Uri.parse(pendingPaymentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            // Still navigate to home as fallback
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          } else {
            // Fallback to subscription page
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/subscription');
            }
          }
        } else {
          // Get redirect route or default to home
          final redirectRoute = ref.read(redirectRouteProvider);
          final targetRoute = redirectRoute ?? '/home';
          
          // Clear redirect route
          ref.read(redirectRouteProvider.notifier).state = null;
          
          // Small delay to show success message
          await Future.delayed(const Duration(milliseconds: 800));
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(targetRoute);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Use ErrorHandlerService to show user-friendly error message
        final errorMessage = ErrorHandlerService.getErrorMessage(e);
        ErrorHandlerService.showErrorSnackBar(
          context,
          message: errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handlePhoneLogin() async {
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your mobile number'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Send OTP
      await AuthService.loginWithPhone(phone: _phoneController.text.trim());
      
      if (mounted) {
        // Navigate to OTP verification screen
        // For now, show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your phone'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Use ErrorHandlerService to show user-friendly error message
        final errorMessage = ErrorHandlerService.getErrorMessage(e);
        ErrorHandlerService.showErrorSnackBar(
          context,
          message: errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFingerprintAuth() async {
    try {
      setState(() => _isLoading = true);
      
      final authBackend = AuthBackend();
      final result = await authBackend.authenticateWithFingerprint();

      if (!mounted) return;

      if (result['success'] == true) {
        // Get saved credentials and login
        final userData = await AuthService.getUserData();
        final token = await AuthService.getToken();
        
        if (!mounted) return;
        
        if (userData != null && userData.isNotEmpty && token != null) {
          // Update auth state provider (same as email login)
          final userId = userData['_id']?.toString() ?? userData['id']?.toString();
          
          if (userId != null) {
            ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
              userId: userId,
              email: userData['email']?.toString(),
              firstName: userData['firstname']?.toString(),
              lastName: userData['lastname']?.toString(),
            );
            
            // Initialize push notifications after login
            try {
              await PushNotificationService.initialize();
            } catch (e) {
              // Non-blocking - notifications will work even if init fails
            }
            
            // Get user name for welcome message
            final userName = userData['lastname']?.toString() ?? 
                           userData['firstname']?.toString() ?? 
                           userData['email']?.toString() ?? 
                           'User';
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, $userName!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              
              // Get redirect route or default to home
              final redirectRoute = ref.read(redirectRouteProvider);
              final targetRoute = redirectRoute ?? '/home';
              
              // Clear redirect route
              ref.read(redirectRouteProvider.notifier).state = null;
              
              // Navigate to app
              Navigator.of(context).pushReplacementNamed(targetRoute);
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invalid saved credentials. Please sign in manually.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No saved credentials found. Please sign in manually first.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Show user-friendly error message
        final errorMessage = result['error'] ?? 'Authentication failed. Please try again.';
        final errorType = result['errorType'] ?? 'unknown';

        // Show appropriate dialog for different error types
        if (errorType == 'not_enrolled' || errorType == 'not_available' || errorType == 'not_supported') {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.orange, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Biometric Setup Required',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'To use biometric authentication:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Go to your device Settings\n2. Set up Fingerprint or Face ID\n3. Return to the app and try again',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          // Show professional error message
          if (errorType == 'cancelled') {
            // User cancelled - don't show error, just return
            return;
          } else if (errorType == 'locked_out' || errorType == 'permanently_locked_out') {
            // Show dialog for locked out errors
            if (!mounted) return;
            ErrorHandlerService.showErrorDialog(
              context,
              title: 'Biometric Authentication Locked',
              message: errorMessage,
              showSupportOptions: false,
            );
          } else {
            // Show snackbar for other errors
            if (!mounted) return;
            ErrorHandlerService.showErrorSnackBar(
              context,
              message: errorMessage,
              duration: const Duration(seconds: 5),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // Use ErrorHandlerService to show user-friendly error message
        final errorMessage = ErrorHandlerService.getErrorMessage(e);
        ErrorHandlerService.showErrorSnackBar(
          context,
          message: errorMessage,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // Logo - Large and prominent
                Center(
                  child: Image.asset(
                    'assets/logo1.webp',
                    width: 180,
                    height: 180,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(24, 95, 45, 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.shopping_cart,
                          size: 100,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
                
                // Sign In Heading
                const Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(24, 95, 45, 1),
                    fontFamily: 'Raleway',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Toggle between Email and Phone
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _isPhoneLogin = false),
                      child: Text(
                        'Email',
                        style: TextStyle(
                          color: !_isPhoneLogin 
                              ? const Color.fromRGBO(24, 95, 45, 1)
                              : Colors.grey,
                          fontWeight: !_isPhoneLogin ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    const Text('|'),
                    TextButton(
                      onPressed: () => setState(() => _isPhoneLogin = true),
                      child: Text(
                        'Phone',
                        style: TextStyle(
                          color: _isPhoneLogin 
                              ? const Color.fromRGBO(24, 95, 45, 1)
                              : Colors.grey,
                          fontWeight: _isPhoneLogin ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Email/Password Fields or Phone Field
                if (!_isPhoneLogin) ...[
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.black54),
                      hintText: 'Enter your email',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: Color.fromRGBO(24, 95, 45, 1),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(24, 95, 45, 1),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.black54),
                      hintText: 'Enter your password',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Icon(
                        Icons.lock_outline,
                        color: Color.fromRGBO(24, 95, 45, 1),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color.fromRGBO(24, 95, 45, 1),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(24, 95, 45, 1),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  
                  // Forgot Password - Redirect to webapp
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        // Redirect to webapp forgot password page
                        try {
                          const forgotPasswordUrl = 'https://www.yookatale.app/signin?forgot=true';
                          final uri = Uri.parse(forgotPasswordUrl);
                          
                          final launched = await launchUrl(
                            uri,
                            mode: LaunchMode.externalApplication,
                          );
                          
                          if (!launched) {
                            await launchUrl(uri, mode: LaunchMode.platformDefault);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not open forgot password page. Please visit: https://www.yookatale.app/signin'),
                                duration: const Duration(seconds: 5),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      labelStyle: const TextStyle(color: Colors.black54),
                      hintText: 'Enter your Mobile No',
                      hintStyle: const TextStyle(color: Colors.grey),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Text(
                          '+256',
                          style: TextStyle(
                            color: Color.fromRGBO(24, 95, 45, 1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color.fromRGBO(24, 95, 45, 1),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'We will send you a verification code',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Login Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading 
                        ? null 
                        : (_isPhoneLogin ? _handlePhoneLogin : _handleEmailLogin),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isPhoneLogin ? 'Continue' : 'Login',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Raleway',
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Or With Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or With',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Social Login Buttons
                // Google Sign In Button - COMMENTED OUT FOR FUTURE USE
                /*
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F1F1F),
                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Original Google "G" Logo
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: _buildGoogleLogo(),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Sign in with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1F1F1F),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                */
                
                // Fingerprint Authentication - Show if device supports biometrics and not phone login
                if (!_isPhoneLogin && _biometricAvailable)
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleFingerprintAuth,
                      icon: const Icon(
                        Icons.fingerprint,
                        color: Color.fromRGBO(24, 95, 45, 1),
                        size: 24,
                      ),
                      label: const Text(
                        'Sign in with Fingerprint',
                        style: TextStyle(
                          color: Color.fromRGBO(24, 95, 45, 1),
                          fontFamily: 'Raleway',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color.fromRGBO(24, 95, 45, 1),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 24),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const MobileSignUpPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: Color.fromRGBO(24, 95, 45, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Skip Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (context) => App()),
                      );
                    },
                    child: const Text(
                      'Skip >',
                      style: TextStyle(
                        color: Color.fromRGBO(24, 95, 45, 1),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Handle Google Sign In - Integrated with Backend
// COMMENTED OUT FOR FUTURE USE
/*
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final authBackend = AuthBackend();
      final user = await authBackend.signInWithGoogle();
      
      if (user != null && mounted) {
        // Get user data from Firebase
        final displayName = user.displayName ?? '';
        final nameParts = displayName.split(' ');
        final firstname = nameParts.isNotEmpty ? nameParts[0] : '';
        final lastname = nameParts.length > 1 
            ? nameParts.sublist(1).join(' ')
            : '';

        // Get Firebase ID token for backend authentication
        final idToken = await user.getIdToken();
        
        if (idToken == null) {
          throw Exception('Failed to get authentication token');
        }

        // Register/Login with backend using Google auth
        try {
          final backendResponse = await ApiService.googleAuth(
            idToken: idToken,
            email: user.email ?? '',
            firstName: firstname,
            lastName: lastname,
            photoUrl: user.photoURL ?? '',
          );

          // Save backend token and user data
          if (backendResponse['token'] != null) {
            await AuthService.saveToken(backendResponse['token'] as String);
          }

          // Get user data from backend response (preferred) or use Firebase data
          Map<String, dynamic> userData;
          if (backendResponse['user'] != null && backendResponse['user'] is Map) {
            userData = backendResponse['user'] as Map<String, dynamic>;
            if (backendResponse['token'] != null) {
              userData['token'] = backendResponse['token'];
            }
          } else {
            // Fallback to Firebase user data
            userData = {
              'id': user.uid,
              '_id': user.uid,
              'email': user.email ?? '',
              'firstname': firstname,
              'lastname': lastname,
              'phone': user.phoneNumber ?? '',
              'photoUrl': user.photoURL ?? '',
            };
            if (backendResponse['token'] != null) {
              userData['token'] = backendResponse['token'];
            }
          }

          await AuthService.saveUserData(userData);

          // Update auth state
          final userId = userData['_id']?.toString() ?? userData['id']?.toString();
          if (userId != null) {
            ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
              userId: userId,
              email: userData['email']?.toString(),
              firstName: userData['firstname']?.toString(),
              lastName: userData['lastname']?.toString(),
            );
          }

          // Initialize push notifications
          try {
            await PushNotificationService.initialize();
          } catch (e) {
            // Non-blocking
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Successfully signed in with Google'),
                backgroundColor: Colors.green,
              ),
            );

            // Check for pending payment URL
            final prefs = await SharedPreferences.getInstance();
            final pendingPaymentUrl = prefs.getString('pending_payment_url');
            
            if (pendingPaymentUrl != null && mounted) {
              await prefs.remove('pending_payment_url');
              final uri = Uri.parse(pendingPaymentUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                Navigator.of(context).pushReplacementNamed('/home');
              } else {
                Navigator.of(context).pushReplacementNamed('/subscription');
              }
            } else {
              // Get redirect route or default to home
              final redirectRoute = ref.read(redirectRouteProvider);
              final targetRoute = redirectRoute ?? '/home';
              ref.read(redirectRouteProvider.notifier).state = null;
              
              await Future.delayed(const Duration(milliseconds: 800));
              if (mounted) {
                Navigator.of(context).pushReplacementNamed(targetRoute);
              }
            }
          }
        } catch (backendError) {
          // If backend auth fails, still save Firebase data as fallback
          final userData = {
            'id': user.uid,
            '_id': user.uid,
            'email': user.email ?? '',
            'firstname': firstname,
            'lastname': lastname,
            'phone': user.phoneNumber ?? '',
            'photoUrl': user.photoURL ?? '',
          };
          if (idToken != null) {
            await AuthService.saveToken(idToken);
            userData['token'] = idToken;
          }
          await AuthService.saveUserData(userData);

          // Update auth state
          final userId = userData['_id']?.toString() ?? userData['id']?.toString();
          if (userId != null) {
            ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
              userId: userId,
              email: userData['email']?.toString(),
              firstName: userData['firstname']?.toString(),
              lastName: userData['lastname']?.toString(),
            );
          }

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Signed in with Google (backend sync may be delayed): ${backendError.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => App()),
            );
          }
        }
      } else {
        throw Exception('Google sign-in was cancelled or failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign in with Google: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  */

  // Build Google Logo - Original Google G Logo
  // COMMENTED OUT FOR FUTURE USE
  /*
  Widget _buildGoogleLogo() {
    return CustomPaint(
      size: const Size(20, 20),
      painter: GoogleLogoPainter(),
    );
  }
  */

// Google Logo Painter - Draws the original multicolored Google "G" logo
// COMMENTED OUT FOR FUTURE USE
/*
class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Original Google G logo colors and structure
    // Blue section (top-left quadrant)
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width * 0.5, size.height * 0.5),
      paint,
    );
    
    // Green section (bottom-left quadrant)
    paint.color = const Color(0xFF34A853);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.5, size.width * 0.5, size.height * 0.5),
      paint,
    );
    
    // Yellow section (top-right quadrant)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, 0, size.width * 0.5, size.height * 0.5),
      paint,
    );
    
    // Red section (bottom-right quadrant)
    paint.color = const Color(0xFFEA4335);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.5, size.width * 0.5, size.height * 0.5),
      paint,
    );
    
    // Draw the white "G" shape - more accurate to original
    final gPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Draw the G shape using a more accurate path
    final path = Path()
      // Top horizontal line
      ..moveTo(size.width * 0.35, size.height * 0.25)
      ..lineTo(size.width * 0.65, size.height * 0.25)
      // Right vertical line (top part)
      ..lineTo(size.width * 0.65, size.height * 0.45)
      // Horizontal line going left (middle)
      ..lineTo(size.width * 0.5, size.height * 0.45)
      // Vertical line going down (middle)
      ..lineTo(size.width * 0.5, size.height * 0.6)
      // Horizontal line going right (bottom)
      ..lineTo(size.width * 0.65, size.height * 0.6)
      // Right vertical line (bottom part)
      ..lineTo(size.width * 0.65, size.height * 0.75)
      // Bottom horizontal line
      ..lineTo(size.width * 0.35, size.height * 0.75)
      // Left vertical line
      ..lineTo(size.width * 0.35, size.height * 0.25)
      ..close();
    
    canvas.drawPath(path, gPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
*/