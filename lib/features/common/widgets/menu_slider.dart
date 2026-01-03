import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yookatale/features/authentication/widgets/login.dart';

import '../controller/quick_order_controller.dart';
import '../notifiers/menu_notifier.dart';
import 'custom_button.dart';

class SliderMenu extends ConsumerWidget {
  SliderMenu({
    super.key,
  });

  final List<String> links = const ['Contact', 'About', 'News Blog', 'Careers'];
  final QuickOrderController orderController = QuickOrderController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var width = MediaQuery.of(context).size.width * 0.8;

    return Positioned(
      top: 30,
      bottom: 0,
      right: 0,
      child: ClipRect(
        clipper: LeftClipper(width),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 0, 0, 0.9),
                backgroundBlendMode: BlendMode.multiply),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: IconButton(
                    onPressed: () {
                      ref
                          .read(visibilityProvider.notifier)
                          .toggleVisibility(value: false);
                    },
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  height: 300,
                  margin: const EdgeInsets.only(top: 32),
                  child: ListView.builder(
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      return MenuLinks(
                        label: links[index],
                      );
                    },
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 56),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CustomButton(
                    onPressed: () {
                      orderController.quickOrder();
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: 20,
                      color: Colors.white,
                    ),
                    title: 'Quick Order',
                  ),
                ),
                const SizedBox(height: 50),
                Container(
                  margin: const EdgeInsets.only(left: 56),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: CustomButton(
                    width: 130,
                    onPressed: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const LoginPage()));
                      ref
                          .read(visibilityProvider.notifier)
                          .toggleVisibility(value: false);
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.arrowRightToBracket,
                      size: 20,
                      color: Colors.white,
                    ),
                    title: 'Sign In',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MenuLinks extends StatelessWidget {
  const MenuLinks({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 56),
      height: 50,
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}

class LeftClipper extends CustomClipper<Rect> {
  final double width;

  LeftClipper(this.width);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, width, size.height);
  }

  @override
  bool shouldReclip(LeftClipper oldClipper) => oldClipper.width != width;
}
