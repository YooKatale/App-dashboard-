import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../services/auth_service.dart';
import '../../../services/push_notification_service.dart';
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
  final LocalAuthentication _localAuth = LocalAuthentication();

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
      final token = await AuthService.getToken();
      
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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

  Future<void> _handleFingerprintAuth() async {
    try {
      final bool canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      
      if (!canAuthenticate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric authentication not available'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to sign in',
      );

      if (didAuthenticate && mounted) {
        // Get saved credentials and login
        final userData = await AuthService.getUserData();
        if (userData != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => App()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication failed: $e'),
            backgroundColor: Colors.red,
          ),
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
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // TODO: Navigate to forgot password screen
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
                
                if (!_isPhoneLogin) ...[
                  const SizedBox(height: 16),
                  
                  // Terms Checkbox (for phone login)
                  Row(
                    children: [
                      Checkbox(
                        value: false,
                        onChanged: (value) {},
                        activeColor: const Color.fromRGBO(24, 95, 45, 1),
                      ),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                            children: [
                              TextSpan(text: 'By clicking on Continue you are agreeing to our '),
                              TextSpan(
                                text: 'terms of use',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google Login
                    InkWell(
                      onTap: () {
                        // TODO: Implement Google login
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/google_logo.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to modern Google "G" icon
                            return Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4285F4), // Blue
                                    Color(0xFF34A853), // Green
                                    Color(0xFFFBBC05), // Yellow
                                    Color(0xFFEA4335), // Red
                                  ],
                                  stops: [0.0, 0.33, 0.66, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Fingerprint Authentication
                if (!_isPhoneLogin)
                  SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _handleFingerprintAuth,
                      icon: const Icon(
                        Icons.fingerprint,
                        color: Color.fromRGBO(24, 95, 45, 1),
                      ),
                      label: const Text(
                        'Authenticate with Fingerprint',
                        style: TextStyle(
                          color: Color.fromRGBO(24, 95, 45, 1),
                          fontFamily: 'Raleway',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color.fromRGBO(24, 95, 45, 1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
