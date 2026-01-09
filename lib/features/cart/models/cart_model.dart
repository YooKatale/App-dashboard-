class CartItem {
  final String cartId;
  final String productId;
  final String name;
  final String image;
  final String price;
  final int quantity;
  final String? unit;

  CartItem({
    required this.cartId,
    required this.productId,
    required this.name,
    required this.image,
    required this.price,
    required this.quantity,
    this.unit,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['cartId']?.toString() ?? json['_id']?.toString() ?? '',
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Product',
      image: _getImageUrl(json),
      price: json['price']?.toString() ?? '0',
      quantity: _parseQuantity(json['quantity']),
      unit: json['unit']?.toString(),
    );
  }

  static int _parseQuantity(dynamic quantity) {
    // EXACT WEBAPP LOGIC: Always ensure quantity is at least 1
    // Webapp adds items with quantity: 1 by default
    if (quantity == null) return 1;
    
    if (quantity is int) {
      return quantity > 0 ? quantity : 1;
    }
    
    if (quantity is String) {
      final parsed = int.tryParse(quantity);
      if (parsed != null && parsed > 0) {
        return parsed;
      }
    }
    
    // Default to 1 if parsing fails or value is invalid
    return 1;
  }

  static String _getImageUrl(Map<String, dynamic> json) {
    if (json['images'] != null) {
      if (json['images'] is List && (json['images'] as List).isNotEmpty) {
        return json['images'][0]?.toString() ?? '';
      } else if (json['images'] is String) {
        return json['images'];
      }
    }
    return json['image']?.toString() ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'cartId': cartId,
      'productId': productId,
      'name': name,
      'image': image,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }

  CartItem copyWith({
    String? cartId,
    String? productId,
    String? name,
    String? image,
    String? price,
    int? quantity,
    String? unit,
  }) {
    return CartItem(
      cartId: cartId ?? this.cartId,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      image: image ?? this.image,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  double get totalPrice {
    final priceValue = double.tryParse(price) ?? 0.0;
    return priceValue * quantity;
  }
}

