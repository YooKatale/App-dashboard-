import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../popular_products.dart';
import 'categories_page.dart';
import 'discount_page.dart';

class MainArea extends ConsumerWidget {
  const MainArea({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Container(
        color: const Color(0Xffefefef),
        width: Get.width * 0.75,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: const Column(
          children: [
            CategoriesPage(),
            PopularProducts(),
            DiscountsPage(),
          ],
        ),
      ),
    );
  }
}
