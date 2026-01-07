import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../notifiers/product_notifier.dart';
import 'products.dart';
import 'hero_banner_slideshow.dart';
import 'banner_image.dart';
import 'categories_section.dart';
import '../../../widgets/ratings_dialog.dart';
import '../../../services/ratings_service.dart';
import '../../../services/api_service.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController scrollController = ScrollController();
  bool _hasShownRatings = false;

  @override
  void initState() {
    super.initState();
    // Show ratings popups after a delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_hasShownRatings) {
        _checkAndShowRatings();
      }
    });
  }

  Future<void> _checkAndShowRatings() async {
    if (!mounted) return;
    
    // Check for Play Store rating
    final shouldShowPlayStore = await RatingsService.shouldShowPlayStoreRating();
    if (shouldShowPlayStore && mounted) {
      await RatingsDialog.showPlayStoreRatingDialog(context);
      _hasShownRatings = true;
      return;
    }

    // Check for service rating
    final shouldShowService = await RatingsService.shouldShowServiceRating();
    if (shouldShowService && mounted) {
      await RatingsDialog.showServiceRatingDialog(context);
      _hasShownRatings = true;
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var latestProducts = ref.watch(productsProvider);
    var popularProducts = ref.watch(popularProductsProvider);
    var fruitProducts = ref.watch(fruitProvider);
    return SizedBox(
      child: SingleChildScrollView(
        controller: scrollController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // Hero Banner Slideshow
            const HeroBannerSlideshow(),
            
            // Categories Section
            const CategoriesSection(),
            
            // Latest Products Section
            ProductsPage(
              productProvider: latestProducts,
              title: 'Latest Products',
            ),
            
            // Banner 1
            const BannerImage(
              imageUrl: 'https://yookatale.app/assets/images/b1.jpeg',
            ),
            
            // Most Popular Products Section
            ProductsPage(
              productProvider: popularProducts,
              title: 'Most Popular',
            ),
            
            // Banner 2
            const BannerImage(
              imageUrl: 'https://yookatale.app/assets/images/b2.jpeg',
            ),
            
            // Fruits Products Section
            ProductsPage(
              productProvider: fruitProducts,
              title: 'Fruits Products',
            ),
            
            // Banner 3
            const BannerImage(
              imageUrl: 'https://yookatale.app/assets/images/banner2.jpeg',
            ),
          ],
        ),
      ),
    );
  }
}
