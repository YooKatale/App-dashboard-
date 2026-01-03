import 'package:flutter/material.dart';

class FAQsPage extends StatelessWidget {
  const FAQsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQs'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Frequently Asked Questions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 80,
                height: 3,
                color: const Color.fromRGBO(24, 95, 45, 1),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildFAQItem(
              'What is YooKatale?',
              'YooKatale is a digital mobile food market for natural and organic foods products',
            ),
            _buildFAQItem(
              'What is YooCard?',
              'YooCard is a product of YooKatale that allows its customers get access to all food items with or without cash, offers them free delivery and other loyalties',
            ),
            _buildFAQItem(
              'How does YooCard work?',
              'Once a client buys YooCard, he/she is required to Sign Up and input the 14 digit code on the card, then wait for a confirmation message to start ordering',
            ),
            _buildFAQItem(
              'How do I order with YooKatale?',
              'Google search YooKatale.com, log in or register if you don\'t have an account, scroll through the items on the homepage and select whichever item of want and add to chart or search for any items you don\'t see or use the WhatsApp button to place an order',
            ),
            _buildFAQItem(
              'How much does YooCard cost?',
              '30,000 ugx or \$8.2 and 25,000 on promotion',
            ),
            _buildFAQItem(
              'Why should I buy YooCard?',
              'YooCard is nicknamed a home food bank, cause it comes with a month or two of free delivery so you never have to go to the market, gas refill discounts and it unlocks a credit option for daily users and more depending on the card purchased.',
            ),
            _buildFAQItem(
              'Where is YooKatale located?',
              'YooKatale is located in Uganda, with it\'s head office in Naguru plot27, P.O Box 74940 clock tower',
            ),
            _buildFAQItem(
              'Where does YooKatale operate?',
              'The digital mobile market delivers allover Kampala and it\'s outskirts these include Kololo, Ntinda, Kiwatule, najjera, Kyanja, Makindye, Ggaba, Munyonyo, Luzira, Kitintale, Gayaza, Kiteezi, Rubaga, Mengo, Lubowa and more.',
            ),
            _buildFAQItem(
              'How do I get YooCard? Or how do I subscribe to YooKatale?',
              'A card can be requested info@yookatale.com or Get Card to order & it\'s delivered direct to your doorstep. You can pay online or pay on delivery.',
            ),
            _buildFAQItem(
              'Can I use YooKatale without a card?',
              'Yes, everyone can use the mobile platform without have a card b signing up, however an additional fee charge is added for delivery and other services where necessary.',
            ),
            _buildFAQItem(
              'How do I pay for products with YooKatale?',
              'Yookatale accepts cash on delivery, mobile money, visa or debit cards and YooCard as payment methods for items and services',
            ),
            _buildFAQItem(
              'How long does YooKatale take to deliver?',
              'Usually, it takes between 5 - 35 minutes depending on the client\'s location',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
        iconColor: const Color.fromRGBO(24, 95, 45, 1),
        collapsedIconColor: const Color.fromRGBO(24, 95, 45, 1),
      ),
    );
  }
}
