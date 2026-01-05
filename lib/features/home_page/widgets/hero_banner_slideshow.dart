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
  List<String> _bannerImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBannerImages();
  }

  Future<void> _loadBannerImages() async {
    // Sync hero images from webapp
    // Webapp hero image: /assets/images/banner.jpg
    // Webapp URL: https://yookatale.app
    final webappBaseUrl = 'https://yookatale.app';
    
    setState(() {
      _bannerImages = [
        '$webappBaseUrl/assets/images/banner.jpg', // Main hero image from webapp
        '$webappBaseUrl/assets/images/new.jpeg', // New banner from webapp
        '$webappBaseUrl/assets/images/b1.jpeg', // Webapp images
        '$webappBaseUrl/assets/images/b2.jpeg',
        '$webappBaseUrl/assets/images/banner2.jpeg',
        '$webappBaseUrl/assets/images/banner3.jpeg',
      ];
      _isLoading = false;
    });
    
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
                  final imageUrl = _bannerImages[index];
                  final isNetworkImage = imageUrl.startsWith('http://') || imageUrl.startsWith('https://');
                  
                  return Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    child: isNetworkImage
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
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
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) {
                              // Try fallback local image
                              if (index < _bannerImages.length - 1) {
                                return Image.asset(
                                  'assets/images/banner.jpg',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
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
                                );
                              }
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
                          )
                        : Image.asset(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
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
