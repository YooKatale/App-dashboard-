import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';

const _kBg        = Color(0xFF0A0F14);
const _kCard      = Color(0xFF111820);
const _kBorder    = Color(0xFF1E2D3D);
const _kGreen     = Color(0xFF00C853);
const _kGreenDim  = Color(0xFF1A5C1A);
const _kText      = Color(0xFFE0E6ED);
const _kMuted     = Color(0xFF8A99AA);
const _kBase      = 'https://yookatale-server.onrender.com/api';

class DriverLoginPage extends StatefulWidget {
  const DriverLoginPage({super.key});

  @override
  State<DriverLoginPage> createState() => _DriverLoginPageState();
}

class _DriverLoginPageState extends State<DriverLoginPage> {
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _obscure     = true;
  bool _loading     = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email    = _emailCtrl.text.trim();
    final password = _passCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter email and password.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final res = await http.post(
        Uri.parse('$_kBase/driver/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 20));
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && (body['token'] != null || body['data']?['token'] != null)) {
        final token = body['token']?.toString() ?? body['data']?['token']?.toString() ?? '';
        final userData = body['data'] ?? body['user'] ?? body;
        // Store driver session separately
        await AuthService.saveToken(token);
        await AuthService.saveUserData(userData is Map<String, dynamic>
            ? {...userData, '_isDriver': true}
            : {'_isDriver': true});
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/driver-app');
        }
      } else {
        final msg = body['message']?.toString() ?? body['error']?.toString() ?? 'Login failed.';
        setState(() => _error = msg);
      }
    } catch (e) {
      setState(() => _error = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back to app
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back_ios_new_rounded, color: _kMuted, size: 14),
                    const SizedBox(width: 6),
                    Text('Back to YooKatale',
                        style: const TextStyle(color: _kMuted, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Logo / branding
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kGreen.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.delivery_dining_rounded,
                        color: _kGreen, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('YooKatale',
                          style: TextStyle(color: _kText, fontSize: 18,
                              fontWeight: FontWeight.w800)),
                      Text('DRIVER PORTAL',
                          style: TextStyle(color: _kGreen, fontSize: 11,
                              fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 40),

              const Text('Welcome back',
                  style: TextStyle(color: _kText, fontSize: 26,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Sign in to your driver account',
                  style: TextStyle(color: _kMuted, fontSize: 14)),

              const SizedBox(height: 32),

              // Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _kCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email
                    const Text('Email address',
                        style: TextStyle(color: _kMuted, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _DarkField(
                      controller: _emailCtrl,
                      hint: 'driver@example.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 18),

                    // Password
                    const Text('Password',
                        style: TextStyle(color: _kMuted, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _DarkField(
                      controller: _passCtrl,
                      hint: '••••••••',
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: _kMuted, size: 18,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.redAccent,
                                fontSize: 12)),
                      ),
                    ],

                    const SizedBox(height: 22),

                    // Sign In button
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _loading ? null : _signIn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF1A8E3E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: _loading
                                ? const SizedBox(width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Sign In',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15)),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward_rounded,
                                          color: Colors.white, size: 18),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Apply as rider
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/partner'),
                  child: const Text.rich(TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: _kMuted, fontSize: 13),
                    children: [
                      TextSpan(
                        text: 'Apply as rider',
                        style: TextStyle(
                          color: _kGreen,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: _kGreen,
                        ),
                      ),
                    ],
                  )),
                ),
              ),

              const SizedBox(height: 40),

              // Security footer
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, color: _kMuted, size: 12),
                    const SizedBox(width: 5),
                    const Text('Secured with 256-bit encryption',
                        style: TextStyle(color: _kMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffix;

  const _DarkField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: _kText, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _kMuted, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF0D1620),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(color: _kGreen, width: 1.5),
        ),
      ),
    );
  }
}
