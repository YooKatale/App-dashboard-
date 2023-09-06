import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'discount_card.dart';
import 'last_order_card.dart';
import 'popular_header_page.dart';

class DiscountsPage extends ConsumerWidget {
  const DiscountsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const PopularHeaders(
          headerTitle: 'Discount Market',
          headerLabel: 'Last Order',
          color: Colors.black,
        ),
        SizedBox(
          // width: Get.width,
          height: 245,
          // margin: const EdgeInsets.only(top: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 18.0),
                      child: Text(
                        'View More',
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Cabin',
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        DiscountCard(),
                        DiscountCard(),
                        DiscountCard(),
                        DiscountCard(),
                      ],
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 24),
                  child: const LastOrdersCard(),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
