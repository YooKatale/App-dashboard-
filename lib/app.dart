// ignore_for_file: unused_local_variable

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'features/authentication/providers/auth_provider.dart';
import 'features/common/controller/utility_method.dart';
import 'features/common/responsive.dart';
import 'features/common/widgets/base_widget.dart';
import 'features/common/notifiers/menu_notifier.dart';
import 'features/desktop_view/widgets/main_area.dart';
import 'features/desktop_view/widgets/dashboard_menus.dart';
import 'features/desktop_view/widgets/desktop_appbar.dart';
import 'features/home_page/widgets/home_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isLoggedIn = ref.watch(authStateProvider).isLoggedIn;
    log('isLoggedIn $isLoggedIn');
    log('uid: ${userCredential?.user?.uid}');
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
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
          background: const Color.fromRGBO(0, 0, 0, 0.5),
          seedColor: const Color.fromARGB(99, 3, 39, 14),
          // outline: Color.fromARGB(255, 35, 57, 75),
          outline: const Color.fromARGB(255, 36, 46, 65),
        ),
        useMaterial3: true,
      ),
      home:
          // isLoggedIn ? App(uid: userCredential!.user!.uid) : const LoginPage(),
          App(),
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
          ),
          tablet: const DesktopView(),
          desktop: const DesktopView(),
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
