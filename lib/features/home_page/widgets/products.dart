import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../common/models/products_model.dart';
import '../../products/widgets/mobile_product_card.dart';
import '../../products/widgets/product_detail_page.dart';
import '../notifiers/product_notifier.dart';

class ProductsPage extends ConsumerWidget {
  const ProductsPage({super.key, this.productProvider, this.title});
  final AsyncValue<Products>? productProvider;
  final String? title;

  static const _kPrimary = Color(0xFF0B2416);
  static const _kAccent  = Color(0xFF2ECC71);
  static const _kBg      = Color(0xFFF4F6F4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: (productProvider != null ? productProvider! : ref.watch(productsProvider)).when(
        data: (value) {
          if (value.popularProducts.isEmpty) {
            return const SizedBox(height: 50, child: Center(child: Text('No products', style: TextStyle(color: Colors.grey, fontSize: 12))));
          }
          return SizedBox(
            height: 210,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              itemCount: value.popularProducts.length,
              itemBuilder: (context, index) {
                final product   = value.popularProducts[index];
                final productId = product.actualId ?? product.id?.toString() ?? '';
                if (productId.isEmpty || productId == 'null' || productId == '0') return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 11),
                  width: 155,
                  child: MobileProductCard(
                    product: product,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductDetailPage(productId: productId, product: product)),
                    ),
                  ),
                );
              },
            ),
          );
        },
        error: (err, _) {
          log('Error: $err');
          return const SizedBox(height: 50, child: Center(child: Text('No data found', style: TextStyle(color: Colors.grey, fontSize: 12))));
        },
        loading: () => const SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator(color: _kAccent, strokeWidth: 2)),
        ),
      ),
    );
  }

  Future<TaskSnapshot> uploadFile(File file, Uint8List bytes) async {
    UploadTask task =
        FirebaseStorage.instance.ref('images/${file.path}').putData(bytes);

    TaskSnapshot snap = await task;
    return snap;
  }
}
