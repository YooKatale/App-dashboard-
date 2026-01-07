import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../common/models/products_model.dart';

class MobileProductCard extends StatelessWidget {
  final PopularDetails product;
  final VoidCallback? onTap;
  final bool showAddButton;

  const MobileProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.showAddButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = product.image.startsWith('http://') || 
                          product.image.startsWith('https://');
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image - Fixed aspect ratio
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: isNetworkImage
                      ? CachedNetworkImage(
                          imageUrl: product.image,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color.fromRGBO(24, 95, 45, 1),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        )
                      : Image.asset(
                          product.image.startsWith('assets/')
                              ? product.image
                              : 'assets/${product.image}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        ),
                ),
              ),
              
              // Product Info - Fixed height container to prevent overflow
              Container(
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(
                  minHeight: 80,
                  maxHeight: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Title - Fixed height
                    SizedBox(
                      height: 26,
                      child: Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'Raleway',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 3),
                    
                    // Price and Unit
                    SizedBox(
                      height: 15,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: Text(
                              'UGX ${product.price}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color.fromRGBO(24, 95, 45, 1),
                                fontFamily: 'Raleway',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.per != null && product.per!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Text(
                                '/${product.per}',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (showAddButton) ...[
                      const Spacer(),
                      
                      // Add to Cart Button - Fixed at bottom
                      SizedBox(
                        width: double.infinity,
                        height: 26,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (onTap != null) onTap!();
                          },
                          icon: const Icon(
                            Icons.shopping_cart_outlined,
                            size: 11,
                          ),
                          label: const Text(
                            'Add',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Raleway',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
