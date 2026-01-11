import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../common/models/products_model.dart';
import '../../common/widgets/custom_button.dart';
import '../../payment/widgets/flutter_wave.dart';
import '../../products/widgets/mobile_product_card.dart';
import '../../products/widgets/product_detail_page.dart';
import '../../products/widgets/mobile_products_page.dart';
import '../notifiers/product_notifier.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key, this.productProvider, this.title});
  final AsyncValue<Products>? productProvider;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // var productProvider = ref.watch(productsProvider);
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 50),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color.fromRGBO(0, 0, 0, 0.1),
            ),
          ),
        ),
        // height: 500,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? 'Products',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.black),
                      ),
                      Container(
                        height: 2.5,
                        width: 80,
                        color: const Color.fromRGBO(24, 95, 45, 1),
                      )
                    ],
                  ),
                  TextButton(
                    child: const Text(
                      'View More',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color.fromRGBO(24, 95, 45, 1),
                      ),
                    ),
                    onPressed: () {
                      // Navigate to all products page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MobileProductsPage(
                            title: title ?? 'All Products',
                            category: null, // Show all products
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
            (productProvider != null ? productProvider! : ref.watch(productsProvider)).when(
              data: (value) {
                if (value.popularProducts.isEmpty) {
                  return const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('No products available'),
                    ),
                  );
                }
                return SizedBox(
                  height: 320,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: value.popularProducts.length,
                    itemBuilder: (context, index) {
                      final product = value.popularProducts[index];
                      // Ensure we have a valid product ID before rendering
                      final productId = product.actualId ?? 
                                      product.id?.toString() ?? 
                                      '';
                      
                      // Skip products without valid ID
                      if (productId.isEmpty || productId == 'null' || productId == '0') {
                        return const SizedBox.shrink();
                      }
                      
                      return Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 180,
                        child: MobileProductCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailPage(
                                  productId: productId,
                                  product: product,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                );
              },
              error: (err, stackTrace) {
                log('Error: $err');
                return const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('No Data found'),
                  ),
                );
              },
              loading: () => const SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color.fromRGBO(24, 95, 45, 1),
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Future<TaskSnapshot> uploadFile(File file, Uint8List bytes) async {
    UploadTask task =
        FirebaseStorage.instance.ref('images/${file.path}').putData(bytes);

    TaskSnapshot snap = await task;
    return snap;
  }
}
