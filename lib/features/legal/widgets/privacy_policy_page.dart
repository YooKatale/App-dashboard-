import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'This Privacy Policy describes how Yookatale a product of Seconds Tech Limited ("We") collects and processes the User\'s ("You") your personal information through the Company\'s sites and services online and applications (collectively "our Services" or "Services") that reference this Privacy Policy. By using our services, you are consenting to the practices described in this Privacy Policy.',
              style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
            const SizedBox(height: 24),
            
            _buildSection(
              '1.0 Collection of Personal Information',
              'We collect your personal information in order to provide and continually improve our products and services.',
              [
                _buildSubsection(
                  '1.1 The types of personal information collected includes but is not limited to;',
                  [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                        children: [
                          const TextSpan(
                            text: 'Information You Give Us: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(
                            text: 'We receive and store any information you provide in relation to our Services. This includes email addresses, phone numbers and location details. The user reserves the right not to provide certain information.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                        children: [
                          TextSpan(
                            text: 'Automatic Information: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: 'We automatically collect and store certain types of information about your use of our Services, including information about your interaction with content and services available through our Services. We use "cookies" and other unique identifiers, and we obtain certain types of information when your web browser or device accesses our Services and other content served by or on behalf of the Company on other websites.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                        children: [
                          TextSpan(
                            text: 'Information from Other Sources: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: 'We might receive information about you from other sources, such as updated delivery and address information from our carriers, which we use to correct our records and deliver your next purchase more easily.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            _buildSection(
              '2.0 Use of Personal Information',
              'We use your personal information to operate, provide, develop, and improve the products and services that we offer users. These purposes include:',
              [
                _buildListItem('Purchase and delivery of products and services: We use your personal information to take, handle and facilitate online transactions, process payments, and communicate with you about orders, products and services, and promotional offers.'),
                _buildListItem('Provide, troubleshoot, and improve our Services: We use your personal information to provide functionality, analyze performance, fix errors, and improve the usability and effectiveness of the Services.'),
                _buildListItem('Recommendations and personalization: We use your personal information to recommend features, products, and services that might be of interest to you, identify your preferences, and personalize your experience with our Services.'),
                _buildListItem('Comply with legal obligations: In certain cases, we collect and use your personal information to comply with laws.'),
                _buildListItem('Communicate with you: We use your personal information to communicate with you in relation to our Services via different channels (e.g., by phone, e-mail, chat).'),
                _buildListItem('Advertising: We use your personal information to display interest-based ads for features, products, and services that might be of interest to you. We do not use information that personally identifies you to display interest-based ads.'),
                _buildListItem('Fraud prevention: We use personal information to prevent and detect fraud and abuse in order to protect the security of users, the Company, and others.'),
              ],
            ),
            
            _buildSection(
              '3.0 Sharing Your Personal Information',
              'The Company does not sell users\' personal information to third parties. Users\' personal information is shared only in the following circumstances;',
              [
                _buildListItem('Information to sellers using the Services: We make available to you services and products provided by sellers for use on or through our Services. Users\' personal information related to those transactions is shared with the seller.'),
                _buildListItem('Protection of the Company and Others: We release account and other personal information when we believe release is appropriate to comply with the law; enforce or apply our general terms and conditions and other agreements; or protect the rights, property, or safety of the Company, our users, or others. This includes exchanging information with other companies and organizations for fraud protection.'),
                const Text(
                  'Other than as set out above, you will receive notice when personal information about you might be shared with third parties, and you will have an opportunity to choose not to share the information.',
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                ),
              ],
            ),
            
            _buildSection(
              '4.0 Security of Your Personal Information',
              'The Site is designed in such a way as to protect your privacy and personal information. Personal Information is protected in the following ways;',
              [
                _buildListItem('We work to protect the security of your personal information during transmission by using encryption protocols and software.'),
                _buildListItem('We maintain physical, electronic, and procedural safeguards in connection with the collection, storage, and disclosure of personal customer information. The security procedures mean that we may occasionally request proof of identity before we disclose personal information to you.'),
                _buildListItem('Protection against unauthorized access to the use\'s password, computers, devices, and applications is highly advised as a security measure.'),
              ],
            ),
            
            _buildSection(
              '5.0 Advertising',
              null,
              [
                _buildListItem('Third-Party Advertisers and Links to Other Websites: Our Services may include third-party advertising and links to other websites and apps. Third-party advertising partners may collect information about you when you interact with their content, advertising, and services.'),
                _buildListItem('Use of Third-Party Advertising Services: We may provide Ad companies with information that allows them to serve you with more useful and relevant Ads. In the event this happens, your name or other information that directly identifies you is not shared.'),
              ],
            ),
            
            _buildSection(
              '6.0 Access to your information',
              'You can access your information, including your name, address, payment options, profile information, and purchase history in the "Your Account" section of the site.',
              null,
            ),
            
            _buildSection(
              '7.0 Conditions of Use',
              null,
              [
                const Text(
                  '7.1 Upon registration of your account with the Company, this policy will apply to you in so far as your account is concerned.',
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 8),
                const Text(
                  '7.2 This policy will be applicable in conjunction with our General Terms and Conditions and all such other policies and notices made by the Company from time to time.',
                  style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String? intro, List<Widget>? children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (intro != null) ...[
          const SizedBox(height: 8),
          Text(
            intro,
            style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ],
        if (children != null) ...[
          const SizedBox(height: 12),
          ...children,
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSubsection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildBoldText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 14, color: Colors.black87)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
