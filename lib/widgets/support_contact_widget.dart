import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Widget to display support contact information
class SupportContactWidget extends StatelessWidget {
  final bool showTitle;
  final EdgeInsets? padding;

  const SupportContactWidget({
    super.key,
    this.showTitle = true,
    this.padding,
  });

  static const String whatsappSupport = '+256786118137';
  static const String emailSupport = 'info@yookatale.app';

  Future<void> _openWhatsApp() async {
    final url = Uri.parse('https://wa.me/$whatsappSupport');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final url = Uri.parse('mailto:$emailSupport?subject=Support Request');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Row(
              children: [
                Icon(
                  Icons.support_agent,
                  color: const Color.fromRGBO(24, 95, 45, 1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Need Help?',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _SupportOption(
            icon: Icons.chat,
            label: 'WhatsApp Support',
            value: whatsappSupport,
            onTap: _openWhatsApp,
          ),
          const SizedBox(height: 8),
          _SupportOption(
            icon: Icons.email,
            label: 'Email Support',
            value: emailSupport,
            onTap: _openEmail,
          ),
        ],
      ),
    );
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SupportOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: const Color.fromRGBO(24, 95, 45, 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}
