import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yookatale/features/common/widgets/base_widget.dart';

import '../../desktop_view/popular_products.dart';
import '../../desktop_view/widgets/categories_page.dart';
import '../../desktop_view/widgets/discount_page.dart';

class ViewProductsPage extends ConsumerWidget {
  const ViewProductsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BaseWidget(
        child: SingleChildScrollView(
      child: Container(
        height: Get.height * 0.7,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Text(
              //   'Apply Filters',
              //   style: TextStyle(
              //     fontFamily: 'Cabin',
              //     color: Colors.black,
              //     fontSize: 20,
              //     fontWeight: FontWeight.w900,
              //   ),
              // ),
              // SizedBox(
              //   height: 10,
              //   width: 15,
              // ),
              // FilterTitle(
              //   title: 'By price',
              // ),
              // SizedBox(
              //   height: 10,
              //   width: 5,
              // ),
              // Center(
              //   child: PriceFilter(),
              // ),
              Column(
                children: [
                  CategoriesPage(),
                  PopularProducts(),
                  DiscountsPage(),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class PriceFilter extends StatefulWidget {
  const PriceFilter({
    super.key,
  });

  @override
  State<PriceFilter> createState() => _PriceFilterState();
}

class _PriceFilterState extends State<PriceFilter> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {},
          child: SizedBox(
            height: 20,
            child: Row(
              children: [
                Checkbox(
                  value: false,
                  onChanged: (value) {},
                  visualDensity: VisualDensity.compact,
                ),
                const FaIcon(
                  FontAwesomeIcons.arrowDown,
                  size: 18,
                  color: Colors.black,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Lowest',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {},
          child: SizedBox(
            height: 20,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Checkbox(
                  value: false,
                  onChanged: (value) {},
                  visualDensity: VisualDensity.compact,
                ),
                const FaIcon(
                  FontAwesomeIcons.arrowUp,
                  size: 20,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Hightest',
                  style: TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class FilterTitle extends StatelessWidget {
  const FilterTitle({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$title:',
      style: const TextStyle(
        color: Colors.black,
        fontFamily: 'Cabin',
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
