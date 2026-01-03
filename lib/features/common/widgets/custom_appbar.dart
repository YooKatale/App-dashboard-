import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../controller/focus_controller.dart';
import '../notifiers/menu_notifier.dart';

// ignore: non_constant_identifier_names
PreferredSizeWidget? CustomAppBar(BuildContext context) {
  return PreferredSize(
    preferredSize: Size(MediaQuery.of(context).size.width, 70),
    child: AppBar(
      toolbarHeight: 70,
      backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
      title: SearchBar(),
      automaticallyImplyLeading: false,
    ),
  );
}

class SearchBar extends ConsumerWidget {
  SearchBar({super.key});

  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();
  final FocusController focusController = FocusController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isVisible = ref.watch(visibilityProvider);

    return Stack(
      children: [
        Container(
          height: 45,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.search,
                color: Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  focusNode: focusNode,
                  onTap: () {
                    focusController.focusNode = focusNode;
                    focusController.context = context;
                    log('focusNode: ${focusController.focusNode}');
                    if (isVisible) focusController.closeSliderMenu(ref);
                  },
                  textAlignVertical: TextAlignVertical.center,
                  controller: controller,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                  cursorColor: const Color.fromRGBO(24, 95, 45, 1),
                  decoration: const InputDecoration(
                    hintText: 'Search on YooKatale',
                    hintStyle: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
