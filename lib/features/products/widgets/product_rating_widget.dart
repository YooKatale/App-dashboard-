import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../services/api_service.dart';
import 'dart:developer';

class ProductRatingWidget extends ConsumerStatefulWidget {
  final String productId;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? authToken;

  const ProductRatingWidget({
    super.key,
    required this.productId,
    this.userId,
    this.userName,
    this.userEmail,
    this.authToken,
  });

  @override
  ConsumerState<ProductRatingWidget> createState() => _ProductRatingWidgetState();
}

class _ProductRatingWidgetState extends ConsumerState<ProductRatingWidget> {
  List<Map<String, dynamic>> _comments = [];
  double _averageRating = 0.0;
  int _totalRatings = 0;
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Form controllers
  final TextEditingController _commentController = TextEditingController();
  int _selectedRating = 0;
  int _hoveredRating = 0;

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
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ApiService.fetchProductComments(widget.productId);
      
      if (response['status'] == 'Success' && response['data'] != null) {
        setState(() {
          _comments = List<Map<String, dynamic>>.from(response['data']['comments'] ?? []);
          _averageRating = double.tryParse(response['data']['averageRating']?.toString() ?? '0') ?? 0.0;
          _totalRatings = response['data']['totalRatings'] ?? 0;
        });
      }
    } catch (e) {
      log('Error loading comments: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading comments: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a comment')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ApiService.createProductComment(
        productId: widget.productId,
        rating: _selectedRating,
        comment: _commentController.text.trim(),
        userId: widget.userId,
        userName: widget.userName,
        userEmail: widget.userEmail,
        token: widget.authToken,
      );

      // Reset form
      _commentController.clear();
      _selectedRating = 0;
      _hoveredRating = 0;

      // Reload comments
      await _loadComments();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating and comment submitted successfully!')),
        );
      }
    } catch (e) {
      log('Error submitting comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildStarRating({required int rating, bool interactive = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        final isFilled = starNumber <= (interactive ? (_hoveredRating > 0 ? _hoveredRating : _selectedRating) : rating);
        
        return GestureDetector(
          onTap: interactive ? () {
            setState(() {
              _selectedRating = starNumber;
            });
          } : null,
          child: MouseRegion(
            onEnter: interactive ? (_) {
              setState(() {
                _hoveredRating = starNumber;
              });
            } : null,
            onExit: interactive ? (_) {
              setState(() {
                _hoveredRating = 0;
              });
            } : null,
            child: Icon(
              isFilled ? Icons.star : Icons.star_border,
              color: isFilled ? Colors.amber : Colors.grey,
              size: 24,
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Average Rating Display
        if (_totalRatings > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  _averageRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStarRating(rating: _averageRating.round()),
                    const SizedBox(height: 4),
                    Text(
                      'Based on $_totalRatings ${_totalRatings == 1 ? 'rating' : 'ratings'}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Rating Form (if user is logged in)
        if (widget.userId != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Write a Review',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Rating Stars
                  const Text('Your Rating'),
                  const SizedBox(height: 8),
                  _buildStarRating(rating: 0, interactive: true),
                  if (_selectedRating > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('You rated $_selectedRating ${_selectedRating == 1 ? 'star' : 'stars'}'),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Comment Text Field
                  TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      labelText: 'Your Comment',
                      hintText: 'Share your thoughts about this product...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    maxLength: 1000,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Submit Button
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Review'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Please sign in to leave a rating and review',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Comments List
        const Text(
          'Customer Reviews',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_comments.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No reviews yet. Be the first to review this product!',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              final rating = comment['rating'] ?? 0;
              final commentText = comment['comment'] ?? '';
              final userName = comment['userName'] ?? 
                              comment['user']?['firstname'] ?? 
                              'Anonymous';
              final createdAt = comment['createdAt'] ?? comment['date'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(userName[0].toUpperCase()),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildStarRating(rating: rating),
                              ],
                            ),
                          ),
                          if (createdAt.isNotEmpty)
                            Text(
                              _formatDate(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(commentText),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

