import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

class ProductRatingsWidget extends ConsumerStatefulWidget {
  final String productId;

  const ProductRatingsWidget({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductRatingsWidget> createState() =>
      _ProductRatingsWidgetState();
}

class _ProductRatingsWidgetState extends ConsumerState<ProductRatingsWidget> {
  List<dynamic> _comments = [];
  double _averageRating = 0.0;
  bool _isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final response = await ApiService.fetchProductComments(widget.productId);
      if (response['status'] == 'Success' && response['data'] != null) {
        final data = response['data'];
        List<dynamic> comments = [];
        
        if (data is List) {
          comments = data;
        } else if (data is Map && data.containsKey('comments')) {
          comments = data['comments'] as List;
        }

        // Calculate average rating
        if (comments.isNotEmpty) {
          double totalRating = 0;
          for (var comment in comments) {
            if (comment['rating'] != null) {
              totalRating += (comment['rating'] as num).toDouble();
            }
          }
          _averageRating = totalRating / comments.length;
        }

        setState(() {
          _comments = comments;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userData = await AuthService.getUserData();
      final token = await AuthService.getToken();
      
      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to rate products'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      await ApiService.createProductComment(
        productId: widget.productId,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        userId: userData['_id']?.toString() ?? userData['id']?.toString(),
        userName: '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim(),
        userEmail: userData['email']?.toString(),
        token: token,
      );

      _commentController.clear();
      _selectedRating = 0;
      _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate rating breakdown (like Jumia)
    Map<int, int> ratingBreakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (var comment in _comments) {
      final rating = (comment['rating'] as num?)?.toInt() ?? 0;
      if (rating >= 1 && rating <= 5) {
        ratingBreakdown[rating] = (ratingBreakdown[rating] ?? 0) + 1;
      }
    }
    final maxCount = ratingBreakdown.values.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ratings Header (Jumia Style)
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Raleway',
                ),
              ),
              const SizedBox(height: 20),
              
              // Overall Rating (Jumia Style)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large Rating Number
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_averageRating.toStringAsFixed(1)}/5',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Stars
                      Row(
                        children: List.generate(5, (index) {
                          final rating = _averageRating.round();
                          return Icon(
                            index < rating
                                ? Icons.star
                                : (index < _averageRating ? Icons.star_half : Icons.star_border),
                            color: Colors.amber,
                            size: 24,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_comments.length} ${_comments.length == 1 ? 'rating' : 'ratings'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  
                  // Rating Breakdown (Jumia Style)
                  Expanded(
                    child: Column(
                      children: List.generate(5, (index) {
                        final starCount = 5 - index;
                        final count = ratingBreakdown[starCount] ?? 0;
                        final percentage = maxCount > 0 ? (count / maxCount) : 0.0;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Text(
                                '$starCount ★',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: percentage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.orange[700],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '($count)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const Divider(height: 1),
        
        // Comments from Verified Purchases (Jumia Style)
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comments from Verified Purchases (${_comments.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // Add Rating Section
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate this product',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Star Rating
              Row(
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _selectedRating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () {
                      setState(() => _selectedRating = index + 1);
                    },
                  );
                }),
              ),
              const SizedBox(height: 12),
              
              // Comment Field
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Write your review...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit Review'),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Reviews List
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            : _comments.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No reviews yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to review this product!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _comments.length > 10 ? 10 : _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final rating = (comment['rating'] as num?)?.toInt() ?? 0;
                      final commentText = comment['comment']?.toString() ?? '';
                      final title = comment['title']?.toString() ?? '';
                      final userName = comment['userName']?.toString() ?? 
                                     comment['user']?['firstname']?.toString() ?? 
                                     'Anonymous';
                      String dateStr = '';
                      try {
                        final date = comment['createdAt']?.toString() ?? '';
                        if (date.isNotEmpty && date.length >= 10) {
                          dateStr = date.substring(0, 10);
                        }
                      } catch (e) {
                        dateStr = '';
                      }

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Stars
                            Row(
                              children: List.generate(5, (starIndex) {
                                final isHalf = starIndex < rating && starIndex + 1 > rating;
                                return Icon(
                                  starIndex < rating
                                      ? Icons.star
                                      : (isHalf ? Icons.star_half : Icons.star_border),
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                            const SizedBox(height: 8),
                            
                            // Title
                            if (title.isNotEmpty)
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            
                            // Comment
                            if (commentText.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                commentText,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  height: 1.5,
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 8),
                            
                            // User and Date (Jumia Style)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'by $userName',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (dateStr.isNotEmpty)
                                  Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                            
                            // Verified Purchase Badge (Jumia Style)
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 14,
                                  color: Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Verified Purchase',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        
        // Read More Reviews Button (if more than 10)
        if (_comments.length > 10)
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Center(
              child: TextButton(
                onPressed: () {
                  // Show all reviews in a modal or navigate to full reviews page
                },
                child: Text(
                  'Read More Reviews',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
