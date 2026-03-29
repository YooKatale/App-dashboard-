import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../backend/backend_auth_services.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/push_notification_service.dart';
import '../../../app.dart';
import '../providers/auth_provider.dart';
import '../providers/redirect_provider.dart';
import 'mobile_sign_in.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

class MobileSignUpPage extends ConsumerStatefulWidget {
  const MobileSignUpPage({super.key});

  @override
  ConsumerState<MobileSignUpPage> createState() => _MobileSignUpPageState();
}

class _MobileSignUpPageState extends ConsumerState<MobileSignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _selectedDate;
  String? _gender;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _agreeTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _green),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _handleSignUp() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please agree to the terms and conditions'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phone = _phoneController.text.trim();
      await AuthService.register(
        firstname: _firstNameController.text.trim(),
        lastname: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: phone.isEmpty ? null : phone,
        gender: _gender,
        dob: _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        vegan: false,
        notificationPreferences: {
          'email': true,
          'calls': false,
          'whatsapp': false,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Account created! Please login to continue.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MobileSignInPage()),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() => _isGoogleLoading = true);

    if (kIsWeb) {
      await _handleWebGoogleSignUp();
    } else {
      await _handleMobileGoogleSignUp();
    }
  }

  Future<void> _handleWebGoogleSignUp() async {
    try {
      const apiOrigin = 'https://yookatale-server.onrender.com';
      final params = {
        'redirect': '/',
        'mode': 'signup',
        'return_token': '1',
      };
      final oauthUrl = Uri.parse('$apiOrigin/api/auth/google')
          .replace(queryParameters: params);

      await launchUrl(
        oauthUrl,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_self',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Google sign-up error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ));
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  Future<void> _handleMobileGoogleSignUp() async {
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
            );
          }
          try {
            await PushNotificationService.initialize();
          } catch (_) {}

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Successfully signed up with Google'),
              backgroundColor: Colors.green,
            ));
            ref.read(redirectRouteProvider.notifier).state = null;
            Navigator.of(context).pushReplacementNamed('/home');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Google sign-up error: $e'),
              backgroundColor: Colors.red,
            ));
          }
        }
      } else {
        throw Exception('Google sign-in was cancelled');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Failed: ${e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '')}'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

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
                      width: 100,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.shopping_cart,
                            size: 50, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Create Account',
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
                    'Sign up for free to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Google button
                  _GoogleSignUpButton(
                    isLoading: _isGoogleLoading,
                    onPressed: (_isGoogleLoading || _isLoading)
                        ? null
                        : _handleGoogleSignUp,
                  ),
                  const SizedBox(height: 20),

                  Row(children: [
                    Expanded(child: Divider(color: Colors.grey[300])),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or sign up with email',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300])),
                  ]),
                  const SizedBox(height: 20),

                  // Name row
                  Row(children: [
                    Expanded(
                      child: _buildField(
                        controller: _firstNameController,
                        label: 'First Name *',
                        hint: 'First name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildField(
                        controller: _lastNameController,
                        label: 'Last Name *',
                        hint: 'Last name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _emailController,
                    label: 'Email *',
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

                  _buildField(
                    controller: _phoneController,
                    label: 'Phone (Optional)',
                    hint: 'Include country code',
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
                  const SizedBox(height: 14),

                  // DOB and Gender row
                  Row(children: [
                    Expanded(
                      child: _buildField(
                        controller: _dateController,
                        label: 'Date of Birth',
                        hint: 'Select date',
                        icon: Icons.calendar_today_outlined,
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _gender,
                        style: const TextStyle(
                            color: Color(0xFF1A1A1A), fontSize: 15),
                        decoration: InputDecoration(
                          labelText: 'Gender',
                          labelStyle:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                          prefixIcon:
                              const Icon(Icons.person, color: _green, size: 20),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: _green, width: 1.5)),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(
                              value: 'female', child: Text('Female')),
                        ],
                        onChanged: (v) => setState(() => _gender = v),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Enter your address',
                    icon: Icons.location_on_outlined,
                  ),
                  const SizedBox(height: 14),

                  _buildField(
                    controller: _passwordController,
                    label: 'Password *',
                    hint: 'Min. 6 characters',
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
                      if (v.length < 6) return 'Min. 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Terms checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _agreeTerms,
                          onChanged: (v) =>
                              setState(() => _agreeTerms = v ?? false),
                          activeColor: _green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 13),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/terms'),
                                    child: const Text('Terms',
                                        style: TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            color: _green,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                WidgetSpan(
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, '/privacy'),
                                    child: const Text('Privacy Policy',
                                        style: TextStyle(
                                            decoration:
                                                TextDecoration.underline,
                                            color: _green,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13)),
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

                  // Sign-up button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading || _isGoogleLoading ? null : _handleSignUp,
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
                          : const Text('Create Account',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3)),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Login link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account?',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14)),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                                builder: (_) => const MobileSignInPage())),
                        style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(left: 4)),
                        child: const Text('Log In',
                            style: TextStyle(
                                color: _green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    Widget? prefixWidget,
    Widget? suffixIcon,
    bool obscureText = false,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      readOnly: readOnly,
      keyboardType: keyboardType,
      onTap: onTap,
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

// ── Google Sign-Up Button ──────────────────────────────────────
class _GoogleSignUpButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;
  const _GoogleSignUpButton({required this.isLoading, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF3C4043),
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation(Color(0xFF4285F4))))
            : const Icon(Icons.g_mobiledata, size: 26, color: Color(0xFF4285F4)),
        label: const Text('Continue with Google',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3C4043))),
      ),
    );
  }
}
