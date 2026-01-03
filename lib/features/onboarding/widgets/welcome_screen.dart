import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../authentication/widgets/mobile_sign_in.dart';
import '../../authentication/providers/auth_provider.dart';
import '../../../app.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // PERSISTENT SIGN-IN: Check if already logged in on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndNavigate();
    });
  }
  
  Future<void> _checkAuthAndNavigate() async {
    final authState = ref.read(authStateProvider);
    // If already logged in, go directly to home
    if (authState.isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => App()),
        );
      }
    }
  }
  
  Future<void> _navigateToSignIn() async {
    // PERSISTENT SIGN-IN: Check if already logged in before navigating
    final authState = ref.read(authStateProvider);
    if (authState.isLoggedIn) {
      // Already logged in, go to home
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => App()),
        );
      }
      return;
    }
    
    // Mark that user has seen onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    
    // Navigate to sign in page (only if not logged in)
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MobileSignInPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top spacing
            const SizedBox(height: 40),
            
            // Logo and Branding Section
            Column(
              children: [
                // Actual Yookatale Logo from assets - well positioned
                Image.asset(
                  'assets/logo1.webp',
                  width: 180,
                  height: 180,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                
                // Welcome Message
                const Text(
                  'Welcome to Yookatale',
                  style: TextStyle(
                    fontSize: 20,
                    color: Color.fromRGBO(24, 95, 45, 1), // Green
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            
                // Get Started Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _navigateToSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(24, 95, 45, 1), // Green
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Raleway',
                    ),
                  ),
                ),
              ),
            ),
            
            // Fresh Produce Image at Bottom
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/vegetables.jpeg'),
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
