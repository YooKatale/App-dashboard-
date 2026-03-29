import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../common/models/products_model.dart';
import '../../cart/widgets/add_to_cart_button.dart';
import '../../wishlist/providers/wishlist_provider.dart';
import '../../../services/wishlist_service.dart';

const _kPrimary = Color(0xFF0B2416);
const _kAccent  = Color(0xFF2ECC71);

class MobileProductCard extends ConsumerStatefulWidget {
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
  ConsumerState<MobileProductCard> createState() => _MobileProductCardState();
}

class _MobileProductCardState extends ConsumerState<MobileProductCard> {
  bool _inWishlist = false;

  @override
  void initState() {
    super.initState();
    _checkWishlist();
  }

  Future<void> _checkWishlist() async {
    final id = widget.product.actualId ?? widget.product.id.toString();
    if (id.isEmpty) return;
    final inList = await WishlistService.isInWishlist(id);
    if (mounted) setState(() => _inWishlist = inList);
  }

  Future<void> _toggleWishlist() async {
    final id = widget.product.actualId ?? widget.product.id.toString();
    if (id.isEmpty) return;
    final productMap = {
      'name': widget.product.title,
      'price': widget.product.price,
      'images': [widget.product.image],
      '_id': id,
    };
    await WishlistService.toggleWishlist(id, productMap);
    ref.read(wishlistRefreshProvider.notifier).state++;
    if (mounted) setState(() => _inWishlist = !_inWishlist);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final isNetworkImage = product.image.startsWith('http://') ||
        product.image.startsWith('https://');

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  // Gradient background + image
                  Container(
                    height: 115,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_kPrimary.withOpacity(0.08), _kAccent.withOpacity(0.06)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: isNetworkImage
                        ? CachedNetworkImage(
                            imageUrl: product.image,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 115,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[100],
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const _PlaceholderIcon(),
                          )
                        : Image.asset(
                            product.image.startsWith('assets/') ? product.image : 'assets/${product.image}',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 115,
                            errorBuilder: (_, __, ___) => const _PlaceholderIcon(),
                          ),
                  ),

                  // "Fresh" badge top-left
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Fresh',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),

                  // Wishlist heart top-right
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: _toggleWishlist,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                        ),
                        child: Icon(
                          _inWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 15,
                          color: _inWishlist ? Colors.red : Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                      fontFamily: 'Raleway',
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Star rating + sold count
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF39C12), size: 12),
                      const SizedBox(width: 2),
                      const Text('4.5', style: TextStyle(fontSize: 10, color: Color(0xFFF39C12), fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Text('· 120 sold', style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Price row + add button
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'UGX ${product.price}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _kPrimary,
                                fontFamily: 'Raleway',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (product.per != null && product.per!.isNotEmpty)
                              Text(
                                '/${product.per}',
                                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                      if (widget.showAddButton)
                        AddToCartButton(
                          productId: product.actualId ?? product.id.toString(),
                          productName: product.title,
                          quantity: 1,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _kPrimary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      child: const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 36)),
    );
  }
}
