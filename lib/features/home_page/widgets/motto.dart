
import 'package:flutter/material.dart';
import 'package:yookatale/features/products/widgets/view_products_page.dart';

import '../../common/widgets/custom_button.dart';

class Motto extends StatelessWidget {
  const Motto({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color.fromRGBO(0, 0, 0, 0.1),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          const MottoTexts(leftLabel: 'Campaigning', rightLabel: 'Health'),
          const MottoTexts(
              leftLabel: 'Celebrating', rightLabel: 'togetherness'),
          const MottoTexts(
              leftLabel: 'Living better while', rightLabel: 'saving money'),
          const SizedBox(height: 50),
          CustomButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewProductsPage(),
                  ));
            },
            title: 'View Products',
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class MottoTexts extends StatelessWidget {
  const MottoTexts({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
  });

  final String leftLabel;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          leftLabel,
          style: const TextStyle(fontSize: 22, color: Colors.black),
        ),
        Text(
          ' $rightLabel',
          style: const TextStyle(
            color: Color.fromRGBO(24, 95, 45, 1),
            fontFamily: 'Raleway',
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
