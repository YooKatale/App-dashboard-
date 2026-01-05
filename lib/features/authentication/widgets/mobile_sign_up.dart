import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/push_notification_service.dart';
import '../../../app.dart';
import '../../../backend/backend_auth_services.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../authentication/providers/redirect_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'mobile_sign_in.dart';

class MobileSignUpPage extends ConsumerStatefulWidget {
  const MobileSignUpPage({super.key});

  @override
  ConsumerState<MobileSignUpPage> createState() => _MobileSignUpPageState();
}

class _MobileSignUpPageState extends ConsumerState<MobileSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreeTerms = false;
  DateTime? _selectedDate;
  final TextEditingController _dateController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color.fromRGBO(24, 95, 45, 1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the terms and conditions'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final nameParts = _fullNameController.text.trim().split(' ');
      final firstname = nameParts.isNotEmpty ? nameParts[0] : '';
      final lastname = nameParts.length > 1 
          ? nameParts.sublist(1).join(' ') 
          : '';

      final result = await AuthService.register(
        firstname: firstname,
        lastname: lastname,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        dob: _selectedDate != null 
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        notificationPreferences: {
          'email': true,
          'calls': false,
          'whatsapp': false,
        },
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => App()),
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
                
                // Sign Up Heading
                const Text(
                  'Sign Up for free',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(24, 95, 45, 1),
                    fontFamily: 'Raleway',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Full Name Field
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: Colors.black54),
                    hintText: 'Enter your full name',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(
                      Icons.person_outline,
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
                      return 'Full name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
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
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Terms and Conditions - Required checkbox (EXACT WEBAPP LOGIC)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeTerms,
                      onChanged: (value) {
                        setState(() => _agreeTerms = value ?? false);
                      },
                      activeColor: const Color.fromRGBO(24, 95, 45, 1),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/terms');
                                  },
                                  child: const Text(
                                    'terms and conditions',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Color.fromRGBO(24, 95, 45, 1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/privacy');
                                  },
                                  child: const Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Color.fromRGBO(24, 95, 45, 1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Sign Up Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
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
                        : const Text(
                            'Sign up',
                            style: TextStyle(
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
                
                // Google Sign Up Button - COMMENTED OUT FOR FUTURE USE
                /*
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignUp,
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
                          'Sign up with Google',
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
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Do you have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => const MobileSignInPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: Color.fromRGBO(24, 95, 45, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Handle Google Sign Up - Integrated with Backend
  // COMMENTED OUT FOR FUTURE USE
  /*
  Future<void> _handleGoogleSignUp() async {
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
                content: Text('Successfully signed up with Google'),
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
                content: Text('Signed up with Google (backend sync may be delayed): ${backendError.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => App()),
            );
          }
        }
      } else {
        throw Exception('Google sign-up was cancelled or failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign up with Google: ${e.toString().replaceAll('Exception: ', '')}'),
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
}

// Google Logo Painter - Draws the original multicolored Google "G" logo
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
