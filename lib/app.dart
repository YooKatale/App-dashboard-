// ignore_for_file: unused_local_variable

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/authentication/providers/auth_provider.dart';
import 'features/common/controller/utility_method.dart';
import 'features/common/responsive.dart';
import 'features/common/widgets/base_widget.dart';
import 'features/common/notifiers/menu_notifier.dart';
import 'features/desktop_view/widgets/main_area.dart';
import 'features/desktop_view/widgets/dashboard_menus.dart';
import 'features/desktop_view/widgets/desktop_appbar.dart';
import 'features/home_page/widgets/home_page.dart';
import 'features/cart/widgets/cart_page.dart';
import 'features/subscription/widgets/mobile_subscription_page.dart';
import 'features/schedule/widgets/schedule_page.dart';
import 'features/schedule/widgets/meal_calendar_page.dart';
import 'features/checkout/widgets/checkout_page.dart';
import 'features/payment/widgets/flutter_wave.dart';
import 'features/onboarding/widgets/welcome_screen.dart';
import 'features/account/widgets/mobile_account_page.dart';
import 'features/account/widgets/service_ratings_page.dart';
import 'features/authentication/widgets/mobile_sign_in.dart';
import 'features/authentication/widgets/multi_page_signup.dart';
import 'features/categories/widgets/mobile_categories_page.dart';
import 'features/products/widgets/product_detail_page.dart';
import 'features/common/models/products_model.dart';
import 'features/common/widgets/bottom_navigation_bar.dart';
import 'features/common/widgets/splash_screen.dart';
import 'features/settings/widgets/settings_page.dart';
import 'features/wishlist/widgets/wishlist_page.dart';
import 'features/help/widgets/help_support_page.dart';
import 'services/auth_service.dart';
import 'services/ratings_service.dart';
import 'services/push_notification_service.dart';
import 'widgets/ratings_dialog.dart';
import 'package:firebase_core/firebase_core.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  String? initialRoute;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Initialize Firebase
    try {
      await Firebase.initializeApp();
      // Initialize push notifications
      await PushNotificationService.initialize();
    } catch (e) {
      // Firebase might not be configured, continue anyway
    }
    
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    
    // Check if user is already logged in (like webapp checks localStorage)
    // This MUST happen on app startup to initialize auth state
    final userData = await AuthService.getUserData();
    final token = await AuthService.getToken();
    
    // If we have both user data and token, user is logged in
    if (userData != null && token != null) {
      final userId = userData['_id']?.toString() ?? userData['id']?.toString();
      if (userId != null) {
        // Initialize auth state (like webapp initializes Redux state from localStorage)
        // This is critical - must be done before any page loads
        ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
          userId: userId,
          email: userData['email']?.toString(),
          firstName: userData['firstname']?.toString(),
          lastName: userData['lastname']?.toString(),
        );
      }
    } else {
      // Ensure auth state is logged out if no data
      ref.read(authStateProvider.notifier).state = const AuthState.loggedOut();
    }
    
    // Increment app open count for ratings
    await RatingsService.incrementAppOpenCount();
    
    setState(() {
      initialRoute = hasSeenOnboarding ? '/home' : '/';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      );
    }

    var isLoggedIn = ref.watch(authStateProvider).isLoggedIn;
    log('isLoggedIn $isLoggedIn');
    log('uid: ${userCredential?.user?.uid}');
    
    return MaterialApp(
      title: 'YooKatale',
      debugShowCheckedModeBanner: false,
      navigatorKey: MyApp.navigatorKey,
      theme: ThemeData(
        // fontFamily: 'Cabin',
        fontFamily: 'Raleway',
        textTheme: const TextTheme(
          titleLarge: TextStyle(
              fontSize: 22, color: Colors.white, fontWeight: FontWeight.normal),
          bodyLarge: TextStyle(
              fontSize: 16, color: Colors.white, fontWeight: FontWeight.normal),
          bodySmall: TextStyle(
              fontSize: 12, color: Colors.white, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(
              fontSize: 14, color: Colors.white, fontWeight: FontWeight.normal),
        ),
        primaryColor: const Color.fromRGBO(
            24, 95, 45, 1), // Set the color as primary color
        colorScheme: ColorScheme.fromSeed(
          surface: const Color.fromRGBO(0, 0, 0, 0.5),
          seedColor: const Color.fromARGB(99, 3, 39, 14),
          // outline: Color.fromARGB(255, 35, 57, 75),
          outline: const Color.fromARGB(255, 36, 46, 65),
        ),
        useMaterial3: true,
      ),
      initialRoute: initialRoute ?? '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/home': (context) => App(),
        '/cart': (context) => const CartPage(),
        '/account': (context) => const MobileAccountPage(),
        '/subscription': (context) => const MobileSubscriptionPage(),
        '/schedule': (context) => const SchedulePage(),
        '/meal-calendar': (context) => const MealCalendarPage(),
        '/checkout': (context) => const CheckoutPage(),
        '/categories': (context) => const MobileCategoriesPage(),
        '/settings': (context) => const SettingsPage(),
        '/service-ratings': (context) => const ServiceRatingsPage(),
        '/signin': (context) => MobileSignInPage(),
        '/wishlist': (context) => const WishlistPage(),
        '/help': (context) => const HelpSupportPage(),
      },
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/payment/') == true) {
          final orderId = settings.name?.split('/').last;
          final args = settings.arguments as Map<String, dynamic>?;
          final amount = args?['amount'] as double? ?? 0.0;
          return MaterialPageRoute(
            builder: (context) => FlutterWavePayment(
              orderId: orderId ?? '',
              amount: amount,
            ),
          );
        } else if (settings.name?.startsWith('/product-detail/') == true) {
          final productId = settings.name?.split('/').last;
          return MaterialPageRoute(
            builder: (context) => ProductDetailPage(
              productId: productId!,
              product: PopularDetails(
                id: int.tryParse(productId) ?? 0,
                title: '',
                price: '0',
                image: '',
                per: null,
              ),
            ),
          );
        }
        return null;
      },
    );
  }
}

// ignore: must_be_immutable
class App extends ConsumerStatefulWidget {
  App({super.key, this.uid});
  String? uid;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  final ScrollController scrollController = ScrollController();
  bool showFooter = false;
  Offset? tapPosition;
  bool keyboardIsVisible = false;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(scrollListener);
  }

  @override
  void dispose() {
    scrollController.removeListener(scrollListener);
    super.dispose();
  }

  void scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      setState(() {
        showFooter = true;
      });
    } else {
      setState(() {
        showFooter = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var isVisible = ref.watch(visibilityProvider);
    log('UserId:  ${widget.uid}');

    return GestureDetector(
      onTap: () {},
      onTapDown: (details) {
        tapPosition = details.globalPosition;
      },
      child: Scaffold(
        body: Responsive(
          mobile:
              // DesktopView(),
              BaseWidget(
            child: HomePage(),
            // child: SignUpPage(),
          ),
          tablet: const DesktopView(),
          desktop: const DesktopView(),
        ),
        bottomNavigationBar: Responsive(
          mobile: const MobileBottomNavigationBar(currentIndex: 0),
          tablet: const SizedBox.shrink(),
          desktop: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class DesktopView extends ConsumerWidget {
  const DesktopView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: DesktopAppBar(context, false),
      body: Container(
        color: Colors.white,
        child: Row(
          children: [
            DashboardMenus(),
            const Expanded(child: MainArea()),
          ],
        ),
      ),
    );
  }
}
