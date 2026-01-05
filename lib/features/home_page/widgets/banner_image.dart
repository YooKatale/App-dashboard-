import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BannerImage extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final double height;

  const BannerImage({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.height = 180,
  }) : assert(imagePath != null || imageUrl != null, 'Either imagePath or imageUrl must be provided');

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = imageUrl != null || (imagePath != null && (imagePath!.startsWith('http://') || imagePath!.startsWith('https://')));
    final imageSource = imageUrl ?? imagePath!;
    
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isNetworkImage
            ? CachedNetworkImage(
                imageUrl: imageSource,
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
                placeholder: (context, url) => Container(
                  height: height,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromRGBO(24, 95, 45, 1),
                        const Color.fromRGBO(40, 120, 60, 1),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) {
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
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              )
            : Image.asset(
                imageSource,
                fit: BoxFit.cover,
                width: double.infinity,
                height: height,
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
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
