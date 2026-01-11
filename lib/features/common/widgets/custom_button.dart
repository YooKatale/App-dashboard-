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
    return SizedBox(
      width: width == 160 ? double.infinity : width, // Use full width if default, otherwise use specified
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minimumSize: Size(width == 160 ? 0 : width, height), // Don't enforce minimum if default width
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
