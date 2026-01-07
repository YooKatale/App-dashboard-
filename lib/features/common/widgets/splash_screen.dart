import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../onboarding/widgets/welcome_screen.dart';
import '../../../app.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate immediately after a short delay (no animations)
    Future.delayed(const Duration(milliseconds: 2500), () {
      _navigateToNext();
    });
  }

  Future<void> _navigateToNext() async {
    if (!mounted) return;
    
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    
    if (mounted) {
      if (hasSeenOnboarding) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => App()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          
          // Original YooKatale Logo - centered and well positioned
          Center(
            child: Image.asset(
              'assets/logo1.webp',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.shopping_cart,
                  size: 120,
                  color: Color.fromRGBO(24, 95, 45, 1),
                );
              },
            ),
          ),
          
          const Spacer(flex: 2),
          
          // Original Fruits Image - use original image path
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/categories/fruits.jpeg'),
                  fit: BoxFit.cover,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
