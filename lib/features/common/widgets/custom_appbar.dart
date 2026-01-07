import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../controller/focus_controller.dart';
import '../notifiers/menu_notifier.dart';
import '../../../widgets/improved_search_bar.dart';
import '../../products/widgets/mobile_products_page.dart';

// ignore: non_constant_identifier_names
PreferredSizeWidget? CustomAppBar(BuildContext context) {
  return PreferredSize(
    preferredSize: Size(MediaQuery.of(context).size.width, 70),
    child: AppBar(
      toolbarHeight: 70,
      backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
      title: const SearchBar(),
      automaticallyImplyLeading: false,
    ),
  );
}

class SearchBar extends ConsumerWidget {
  const SearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isVisible = ref.watch(visibilityProvider);
    final FocusController focusController = FocusController();

    return ImprovedSearchBar(
      hintText: 'Search on YooKatale',
      showNotificationIcon: true,
      onSearch: (query) {
        // Handle search - navigate to products page with search query
        if (isVisible) focusController.closeSliderMenu(ref);
        if (query.trim().isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MobileProductsPage(
                title: 'Search Results',
                category: null,
                searchQuery: query.trim(),
              ),
            ),
          );
        }
      },
    );
  }
}
