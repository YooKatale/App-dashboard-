import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'dart:async';

class CustomButton extends ConsumerWidget {
  const CustomButton({
    super.key,
    this.onPressed,
    required this.title,
    this.width = 160,
    this.height = 40,
    this.icon,
    this.color = const Color.fromRGBO(24, 95, 45, 1),
  });

  final FutureOr<void> Function()? onPressed;
  final String title;
  final double height;
  final double width;
  final Widget? icon;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        fixedSize: Size(width, 40),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onPressed: onPressed != null
          ? () {
              final res = onPressed!();
              if (res is Future) {
                // ignore: unawaited_futures
                res;
              }
            }
          : null,
      child: Row(
        mainAxisAlignment: icon != null
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.center,
        children: [
          icon ?? const SizedBox.shrink(),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
