import 'dart:developer';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class DashboardMenus extends StatelessWidget {
  DashboardMenus({
    super.key,
  });

  final List<String> labels = [
    'Dashboard',
    'Categories',
    'My Cart',
    'Favorites',
    'Orders',
    'Message',
    'E-wallet',
    'Top deals',
    'Settings'
  ];

  final List<IconData> iconData = [
    Icons.window_rounded,
    FontAwesomeIcons.chartPie,
    FontAwesomeIcons.cartShopping,
    FontAwesomeIcons.solidHeart,
    Icons.trolley,
    FontAwesomeIcons.solidCommentDots,
    Icons.account_balance_wallet_outlined,
    CupertinoIcons.cube_fill,
    FontAwesomeIcons.gear,
  ];

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 0.0),
      child: Container(
        height: Get.height,
        // width: Get.width * 0.25,
        width: 250,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          // image: const DecorationImage(
          //   image: AssetImage(
          //     'assets/vegetables.jpeg',
          //   ),
          //   opacity: 0.5,
          //   fit: BoxFit.cover,
          // ),
          border: Border.all(
            color: const Color(0XFFd6eadf),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: Get.height * 0.7,
              child: ListView.builder(
                itemCount: 9,
                itemBuilder: (context, index) {
                  return MenuIconTile(
                    index: index,
                    label: labels[index],
                    icon: iconData[index],
                  );
                },
              ),
            ),
            IconButton(
                onPressed: () {},
                icon: const Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      FontAwesomeIcons.arrowRightFromBracket,
                      color: Colors.red,
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Log Out',
                      style: TextStyle(color: Colors.red, fontSize: 16),
                    )
                  ],
                ))
          ],
        ),
      ),
    );
  }
}

class MenuIconTile extends StatefulWidget {
  const MenuIconTile({
    super.key,
    required this.index,
    required this.label,
    required this.icon,
  });

  final int index;
  final String label;
  final IconData icon;

  @override
  State<MenuIconTile> createState() => _MenuIconTileState();
}

class _MenuIconTileState extends State<MenuIconTile> {
  Color? color = Colors.transparent;
  bool isSelected = false;

  int currentSelectedIndex = 0;
  int? previousSelectedIndex;

  @override
  Widget build(BuildContext context) {
    log('currentIndex: $currentSelectedIndex, previousSelectedIndex $previousSelectedIndex');
    return GestureDetector(
      onTap: () {
        setState(() {
          // previousSelectedIndex = currentSelectedIndex;
          // currentSelectedIndex = widget.index;
          isSelected = !isSelected;
        });

        // log('currentIndex: $currentSelectedIndex, previousSelectedIndex $previousSelectedIndex');
      },
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        height: 60,
        width: Get.width,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade900 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Icon(
              widget.icon,
              color: isSelected ? Colors.white : const Color(0XFF28af62),
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              widget.label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0XFF28af62),
                fontSize: 16,
                fontFamily: 'Cabin',
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
