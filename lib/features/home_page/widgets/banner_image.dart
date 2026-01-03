import 'package:flutter/material.dart';

class BannerImage extends StatelessWidget {
  final String imagePath;
  final double height;

  const BannerImage({
    super.key,
    required this.imagePath,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromRGBO(24, 95, 45, 1),
                  const Color.fromRGBO(40, 120, 60, 1),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
