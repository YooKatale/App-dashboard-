import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HeroBannerSlideshow extends StatefulWidget {
  const HeroBannerSlideshow({super.key});

  @override
  State<HeroBannerSlideshow> createState() => _HeroBannerSlideshowState();
}

class _HeroBannerSlideshowState extends State<HeroBannerSlideshow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<String> _bannerImages;

  @override
  void initState() {
    super.initState();
    // Banner images from webapp
    _bannerImages = [
      'assets/images/banner.jpg',
      'assets/images/b1.jpeg',
      'assets/images/b2.jpeg',
      'assets/images/banner2.jpeg',
      'assets/images/banner3.jpeg',
    ];
    
    // Auto-scroll slideshow
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _currentPage < _bannerImages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else if (mounted) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
      if (mounted) {
        _startAutoScroll();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Happy New Year Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple[400]!,
                Colors.purple[600]!,
              ],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.celebration, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Happy New Year | Shop Now!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Raleway',
                ),
              ),
            ],
          ),
        ),
        
        // Slideshow Hero Banner
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _bannerImages.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: Image.asset(
                      _bannerImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback gradient
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
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
                },
              ),
              
              // Page indicators
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _bannerImages.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
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
