import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;
  late AnimationController _successController;
  late Animation<double> _successScale;

  @override
  void initState() {
    super.initState();
    _successController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _successScale = CurvedAnimation(parent: _successController, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() { _sending = false; _sent = true; });
    _successController.forward(from: 0);
  }

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF185f2d), Color(0xFF2e7d32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 14),
                  const Text('We\'re Here to Help', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Raleway')),
                  const SizedBox(height: 6),
                  Text('Reach out anytime — we respond within 24 hours', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.85))),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick contact tiles
                  _contactTile(Icons.phone_rounded, 'Call Us', '+256 786 118 137', 'tel:+256786118137', Colors.blue),
                  _contactTile(Icons.email_rounded, 'Email Us', 'info@yookatale.app', 'mailto:info@yookatale.app', Colors.orange),
                  _contactTile(Icons.chat_bubble_rounded, 'WhatsApp', '+256 786 118 137', 'https://wa.me/256786118137', Colors.green),
                  _contactTile(Icons.language_rounded, 'Website', 'www.yookatale.app', 'https://www.yookatale.app', _green),

                  const SizedBox(height: 28),

                  if (_sent)
                    ScaleTransition(
                      scale: _successScale,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                              child: Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 48),
                            ),
                            const SizedBox(height: 16),
                            const Text('Message Sent!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text('Thanks for reaching out. Our team will get back to you within 24 hours.',
                              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5), textAlign: TextAlign.center),
                            const SizedBox(height: 20),
                            OutlinedButton(
                              onPressed: () => setState(() { _sent = false; _nameCtrl.clear(); _emailCtrl.clear(); _subjectCtrl.clear(); _messageCtrl.clear(); }),
                              style: OutlinedButton.styleFrom(foregroundColor: _green, side: const BorderSide(color: _green)),
                              child: const Text('Send Another'),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    const Text('Send a Message', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 14),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _field(_nameCtrl, 'Your Name', Icons.person_outline, validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                          const SizedBox(height: 12),
                          _field(_emailCtrl, 'Email Address', Icons.email_outlined,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) {
                              if (v?.trim().isEmpty ?? true) return 'Required';
                              if (!v!.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          _field(_subjectCtrl, 'Subject', Icons.subject_rounded, validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _messageCtrl,
                            maxLines: 5,
                            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Required' : null,
                            decoration: InputDecoration(
                              labelText: 'Message',
                              alignLabelWithHint: true,
                              prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 80), child: Icon(Icons.message_outlined, color: _green)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 2)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _sending ? null : _send,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: _sending
                                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send_rounded, size: 18),
                                        SizedBox(width: 8),
                                        Text('Send Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),
                  _buildOfficeCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile(IconData icon, String label, String value, String url, Color color) {
    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$value copied'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      },
      onTap: () => _launch(url),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                ],
              ),
            ),
            Icon(Icons.open_in_new, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 2)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildOfficeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: _green, size: 20),
              const SizedBox(width: 8),
              const Text('Office Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Kampala, Uganda', style: TextStyle(fontSize: 14, color: Colors.grey[800], fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text('Mon–Fri: 8:00 AM – 6:00 PM EAT\nSat: 9:00 AM – 3:00 PM EAT',
            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.6)),
        ],
      ),
    );
  }
}
