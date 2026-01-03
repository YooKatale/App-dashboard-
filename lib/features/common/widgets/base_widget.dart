import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '/features/company_info/widgets/company_info_page.dart';
import '../notifiers/menu_notifier.dart';
import 'custom_appbar.dart';

class BaseWidget extends ConsumerWidget {
  const BaseWidget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(context),
      body: SingleChildScrollView(
        child: child,
      ),
    );
  }
}
