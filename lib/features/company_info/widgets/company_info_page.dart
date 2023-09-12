
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'info_pages.dart';
import 'products_link_page.dart';
import 'social_section_page.dart';
import 'info_section.dart';
import 'subscription_section_page.dart';

class CompanyInfoPage extends ConsumerWidget {
  const CompanyInfoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color.fromRGBO(0, 0, 0, 0.95),
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(0, 0, 0, 0.1),
          ),
        ),
      ),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const InfoSection(),
            const SizedBox(height: 40),
            const SocialSection(),
            const SizedBox(height: 50),
            const SubscribeSection(),
            const SizedBox(height: 50),
            InfoPages(),
            const SizedBox(height: 50),
            ProductsLinkPage(),
            // const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
