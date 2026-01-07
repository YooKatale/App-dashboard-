// To parse this JSON data, do
//
//     final products = productsFromJson(jsonString);

import 'dart:convert';

Products productsFromJson(String str) => Products.fromJson(json.decode(str));

String productsToJson(Products data) => json.encode(data.toJson());

class Products {
  List<PopularDetails> popularProducts;

  Products({
    required this.popularProducts,
  });

  factory Products.fromJson(Map<String, dynamic> json) => Products(
        popularProducts: List<PopularDetails>.from(
            json["popular_products"].map((x) => PopularDetails.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "popular_products":
            List<dynamic>.from(popularProducts.map((x) => x.toJson())),
      };
}

class PopularDetails {
  int id;
  String image;
  String title;
  String price;
  String? per;
  String? actualId; // Store actual _id from backend for API calls

  PopularDetails({
    required this.id,
    required this.image,
    required this.title,
    required this.price,
    this.per = '',
    this.actualId,
  });

  factory PopularDetails.fromJson(Map<String, dynamic> json) => PopularDetails(
        id: json["id"],
        image: json["image"],
        title: json["title"],
        price: json["price"],
        per: json["per"],
        actualId: json["_id"]?.toString() ?? json["id"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "image": image,
        "title": title,
        "price": price,
        "per": per,
        if (actualId != null) "_id": actualId,
      };
}
