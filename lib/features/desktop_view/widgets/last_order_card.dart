import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:yookatale/main.dart';

class LastOrdersCard extends ConsumerWidget {
  const LastOrdersCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      surfaceTintColor: Colors.white,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            OrderListCard(
              itemName: 'Orange',
              itemPrice: '10000',
              itemWeight: '500 gms',
              imageUrl: 'popular_products1/oranges.jpeg',
            ),
            const Divider(
              thickness: 2,
              color: Colors.green,
            ),
            OrderListCard(
              itemName: 'Apple',
              itemPrice: '20000',
              itemWeight: '1 Kg',
              imageUrl: 'popular_products1/apple.jpeg',
            ),
            const Divider(
              thickness: 2,
              color: Colors.green,
            ),
            OrderListCard(
              itemName: 'Avocado',
              itemPrice: '10000',
              itemWeight: '500 gms',
              imageUrl: 'popular_products1/avocado.jpeg',
            )
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class OrderListCard extends StatefulWidget {
  OrderListCard({
    super.key,
    required this.itemName,
    required this.itemPrice,
    required this.itemWeight,
    required this.imageUrl,
  });

  String itemName;
  String itemWeight;
  String itemPrice;
  String imageUrl;

  @override
  State<OrderListCard> createState() => _OrderListCardState();
}

class _OrderListCardState extends State<OrderListCard> {
  int items = 0;
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xffe6f5f0),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                image: DecorationImage(
                    image: AssetImage('assets/${widget.imageUrl}'),
                    fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.itemName,
                    style: const TextStyle(color: Colors.black),
                  ),
                  SizedBox(
                    width: 140,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Weight ${widget.itemWeight} ',
                          style: const TextStyle(
                            // fontFamily: 'Cabin',
                            color: Colors.black,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          '${widget.itemPrice} ugx',
                          style: const TextStyle(
                            fontFamily: 'Cabin',
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          log('Button tapped');
                          if (items > 0) {
                            setState(() {
                              items -= 1;
                              analytics?.logEvent(
                                  name: 'remove_from_cart',
                                  parameters: {
                                    'item_id': 'p123',
                                    'item_name': 'Product 1',
                                    'currency': 'USD ',
                                    'value': 12.99
                                  });
                            });
                          } else {
                            setState(() {
                              items = 0;
                            });
                          }
                        },
                        child: const FaIcon(
                          FontAwesomeIcons.circleMinus,
                          color: Colors.green,
                          size: 15,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$items',
                        style: const TextStyle(
                            color: Colors.green, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          log('Button tapped');
                          setState(() {
                            items += 1;
                            log('Items $items');
                            analytics?.logEvent(
                              name: 'add_from_cart',
                              parameters: {
                                'item_id': 'p123',
                                'item_name': 'Product 1',
                                'currency': 'USD ',
                                'value': 12.99
                              },
                            );
                          });
                        },
                        child: const FaIcon(
                          FontAwesomeIcons.circlePlus,
                          color: Colors.green,
                          size: 15,
                        ),
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
