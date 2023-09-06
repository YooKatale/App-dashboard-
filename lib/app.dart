import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'features/common/responsive.dart';
import 'features/common/widgets/base_widget.dart';
import 'features/common/notifiers/menu_notifier.dart';
import 'features/desktop_view/widgets/main_area.dart';
import 'features/desktop_view/widgets/dashboard_menus.dart';
import 'features/desktop_view/widgets/desktop_appbar.dart';
import 'features/home_page/widgets/home_page.dart';

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
    ;
  }
}
