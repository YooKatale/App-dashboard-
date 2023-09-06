import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '/features/common/widgets/custom_button.dart';
import '/main.dart';

import '../models/user_model.dart';

class FlutterWavePage extends StatefulWidget {
  const FlutterWavePage({super.key, required this.title});

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _FlutterWavePageState createState() => _FlutterWavePageState();
}

class _FlutterWavePageState extends State<FlutterWavePage> {
  final formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final currencyController = TextEditingController();
  final narrationController = TextEditingController();
  final publicKeyController = TextEditingController();
  final encryptionKeyController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();

  String? displayName;
  String? userEmail;
  String? userNumber;

  String selectedCurrency = "";

  bool isTestMode = true;

  @override
  void initState() {
    super.initState();
    // fetchUserCollection();
  }

  Future<List<User>> fetchUserCollection() async {
    List<User> users = [];

    try {
      QuerySnapshot userCollection =
          await FirebaseFirestore.instance.collection('users').get();

      List<QueryDocumentSnapshot> userDocs = userCollection.docs;
      log('userDocs ${userDocs.first.data()}');
      for (QueryDocumentSnapshot doc in userDocs) {
        Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;

        User user = User(
          displayName: userData['displayName'] ?? '',
          phoneNumber: userData['phoneNumber'] ?? '',
          email: userData['email'] ?? '',
        );

        users.add(user);
        displayName = user.displayName;
        userEmail = user.email;
        userNumber = user.phoneNumber;

        log('user: ${user.displayName}');
      }

      return users;
    } catch (err) {
      log('Error fetching user collection: $err');

      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    fetchUserCollection();
    currencyController.text = selectedCurrency;
    log('UserEmail $userEmail $displayName');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),

      backgroundColor: const Color(0Xffefefef),
      body: Center(
        child: Container(
          // width: double.infinity,
          width: 450,
          height: 700,
          margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Form(
            key: formKey,
            child: ListView(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                  child: TextFormField(
                    controller: amountController,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.black),
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(61, 60, 60, 0.2),
                        ),
                      ),
                      hintText: 'Amount',
                      hintStyle: TextStyle(
                        fontFamily: 'Cabin',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0XFFA0AEC0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 34, 104, 235)),
                      ),
                    ),
                    validator: (value) => value != null && value.isNotEmpty
                        ? null
                        : "Amount is required",
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                  child: TextFormField(
                    controller: currencyController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.black),
                    readOnly: true,
                    onTap: _openBottomSheet,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(61, 60, 60, 0.2),
                        ),
                      ),
                      hintText: 'Currency',
                      hintStyle: TextStyle(
                        fontFamily: 'Cabin',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0XFFA0AEC0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 34, 104, 235)),
                      ),
                    ),
                    validator: (value) => value != null && value.isNotEmpty
                        ? null
                        : "Currency is required",
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                  child: TextFormField(
                    controller: publicKeyController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.black),
                    obscureText: true,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(61, 60, 60, 0.2),
                        ),
                      ),
                      hintText: 'Public Key',
                      hintStyle: TextStyle(
                        fontFamily: 'Cabin',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0XFFA0AEC0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 34, 104, 235)),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                  child: TextFormField(
                    controller: encryptionKeyController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.black),
                    obscureText: true,
                    decoration: const InputDecoration(
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(61, 60, 60, 0.2),
                        ),
                      ),
                      hintText: 'Encryption Key',
                      hintStyle: TextStyle(
                        fontFamily: 'Cabin',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0XFFA0AEC0),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 34, 104, 235)),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                  child: TextFormField(
                    controller: emailController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(61, 60, 60, 0.2),
                        ),
                      ),
                      hintText: userEmail,
                      hintStyle: const TextStyle(
                        fontFamily: 'Cabin',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0XFFA0AEC0),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 34, 104, 235)),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                  child: TextFormField(
                    controller: phoneNumberController,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Color.fromRGBO(61, 60, 60, 0.2),
                        ),
                      ),
                      hintText: userNumber,
                      hintStyle: const TextStyle(
                        fontFamily: 'Cabin',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0XFFA0AEC0),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Color.fromARGB(255, 34, 104, 235)),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                  child: Row(
                    children: [
                      const Text("Use Debug"),
                      Switch(
                        onChanged: (value) => {
                          setState(() {
                            isTestMode = value;
                          })
                        },
                        value: isTestMode,
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    // width: double.infinity,
                    height: 50,
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 10),
                    child: CustomButton(
                      onPressed: _onPressed,
                      title: 'Make Payment',
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  _onPressed() {
    final currentState = formKey.currentState;
    if (currentState != null && currentState.validate()) {
      _handlePaymentInitialization();
    }
  }

  _handlePaymentInitialization() async {
    final Customer customer = Customer(
      email: userEmail!,
      name: displayName!,
      phoneNumber: userNumber!,
    );

    var value = double.parse(amountController.text.trim());
    log('value: $value');

    try {
      final Flutterwave flutterwave = Flutterwave(
        context: context,
        publicKey: 'FLWPUBK_TEST-07d1b505448d1358e34d597736dd6b8a-X',
        currency: selectedCurrency,
        redirectUrl: 'https://facebook.com',
        txRef: const Uuid().v1(),
        amount: amountController.text.toString().trim(),
        customer: customer,
        paymentOptions: "card, payattitude, barter, bank transfer, ussd, visa",
        customization: Customization(title: "Test Payment"),
        isTestMode: true,
      );

      final ChargeResponse response = await flutterwave.charge();
      showLoading(response.toString());
      log("${response.toJson()}");
      analytics!.logPurchase(
        currency: currencyController.text.trim(),
        value: double.parse(amountController.text.trim()),
        transactionId: Uuid().v1(),
      );
    } on Exception catch (err) {
      log('Error is $err');
      analytics!.logEvent(
        name: 'purchase_error',
        parameters: {
          'error': err.toString(),
        },
      );
    }
  }

  String getPublicKey() {
    return "";
  }

  void _openBottomSheet() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return _getCurrency();
        });
  }

  Widget _getCurrency() {
    final currencies = ["NGN", "RWF", "UGX", "KES", "ZAR", "USD", "GHS", "TZS"];
    return Container(
      height: 250,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        // border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView(
        children: currencies
            .map((currency) => ListTile(
                  onTap: () => {_handleCurrencyTap(currency)},
                  title: Column(
                    children: [
                      Text(
                        currency,
                        textAlign: TextAlign.start,
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 4),
                      const Divider(height: 1)
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  _handleCurrencyTap(String currency) {
    setState(() {
      selectedCurrency = currency;
      currencyController.text = currency;
    });
    Navigator.pop(context);
  }

  Future<void> showLoading(String message) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            margin: const EdgeInsets.fromLTRB(30, 20, 30, 20),
            width: double.infinity,
            height: 50,
            child: Text(message),
          ),
        );
      },
    );
  }
}
