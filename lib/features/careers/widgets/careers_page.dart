import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

const _green = Color.fromRGBO(24, 95, 45, 1);

// Static job data (matches webapp)
const List<Map<String, dynamic>> _jobs = [
  {
    'id': 'j1',
    'category': 'Engineering',
    'title': 'Mobile App Developer (Flutter)',
    'reportsTo': 'CTO',
    'type': 'Full-time',
    'salary': 'Competitive',
    'location': 'Kampala, Uganda',
    'closingDate': '2026-04-30',
    'responsibilities': [
      'Build and maintain the YooKatale Flutter mobile app',
      'Collaborate with backend team on API integrations',
      'Write clean, testable Dart code',
      'Participate in code reviews and sprint planning',
    ],
    'requirements': [
      'Minimum 2 years Flutter/Dart experience',
      'Experience with state management (Riverpod/BLoC)',
      'Knowledge of Firebase and RESTful APIs',
      'Strong problem-solving skills',
    ],
    'applyEmail': 'careers@yookatale.app',
  },
  {
    'id': 'j2',
    'category': 'Operations',
    'title': 'Delivery Operations Manager',
    'reportsTo': 'COO',
    'type': 'Full-time',
    'salary': 'Competitive',
    'location': 'Kampala, Uganda',
    'closingDate': '2026-04-30',
    'responsibilities': [
      'Manage and coordinate delivery driver fleet',
      'Optimise delivery routes and logistics',
      'Handle customer delivery complaints and escalations',
      'Track and improve delivery performance KPIs',
    ],
    'requirements': [
      'Minimum 3 years operations/logistics experience',
      'Strong leadership and communication skills',
      'Experience with delivery management systems',
      'Ability to work under pressure in fast-paced environment',
    ],
    'applyEmail': 'careers@yookatale.app',
  },
  {
    'id': 'j3',
    'category': 'Sales & Marketing',
    'title': 'Vendor Acquisition Representative',
    'reportsTo': 'Head of Sales',
    'type': 'Full-time',
    'salary': 'Base + Commission',
    'location': 'Kampala, Uganda',
    'closingDate': '2026-04-30',
    'responsibilities': [
      'Identify and onboard new food vendors and sellers',
      'Conduct vendor presentations and demos',
      'Maintain relationships with existing vendor partners',
      'Meet monthly vendor acquisition targets',
    ],
    'requirements': [
      'Minimum 2 years sales or business development experience',
      'Experience in FMCG or food industry preferred',
      'Excellent communication and negotiation skills',
      'Own a smartphone and reliable transport',
    ],
    'applyEmail': 'careers@yookatale.app',
  },
  {
    'id': 'j4',
    'category': 'Customer Support',
    'title': 'Customer Success Agent',
    'reportsTo': 'Customer Experience Manager',
    'type': 'Full-time',
    'salary': 'Competitive',
    'location': 'Kampala, Uganda (Remote possible)',
    'closingDate': '2026-04-30',
    'responsibilities': [
      'Respond to customer inquiries via WhatsApp, email, and in-app chat',
      'Resolve order, delivery, and payment issues',
      'Escalate complex issues to appropriate departments',
      'Maintain customer satisfaction scores above target',
    ],
    'requirements': [
      'Excellent written and verbal communication skills',
      'Experience in customer service or hospitality',
      'Patience, empathy, and problem-solving mindset',
      'Comfortable using digital tools and CRM systems',
    ],
    'applyEmail': 'careers@yookatale.app',
  },
];

class CareersPage extends StatelessWidget {
  const CareersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Careers', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
        backgroundColor: _green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF185f2d), Color(0xFF2e7d32)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Join the YooKatale Team',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Raleway')),
                  const SizedBox(height: 10),
                  Text('Help us feed Uganda. Build something that matters.',
                      style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.9), height: 1.4)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildPerk(Icons.flash_on, 'Fast-paced'),
                      const SizedBox(width: 12),
                      _buildPerk(Icons.favorite, 'Mission-driven'),
                      const SizedBox(width: 12),
                      _buildPerk(Icons.trending_up, 'High growth'),
                    ],
                  ),
                ],
              ),
            ),

            // Job count
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Open Positions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('${_jobs.length} roles', style: const TextStyle(color: _green, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            // Job listings
            ..._jobs.map((j) => _JobCard(job: j)),
            const SizedBox(height: 24),

            // No suitable role?
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Don\'t see a suitable role?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('Send your CV to careers@yookatale.app and we\'ll keep you in mind for future openings.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5)),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: 'careers@yookatale.app'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email copied!'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16, color: _green),
                      label: const Text('careers@yookatale.app', style: TextStyle(color: _green)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: _green)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPerk(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _JobCard extends StatefulWidget {
  final Map<String, dynamic> job;
  const _JobCard({required this.job});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _expanded = false;
  bool _showForm = false;

  @override
  Widget build(BuildContext context) {
    final j = widget.job;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // Header - always visible
          InkWell(
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) _showForm = false;
            }),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(j['category'] as String, style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(j['title'] as String, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Raleway')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _chip(Icons.work_outline, j['type'] as String),
                      _chip(Icons.location_on_outlined, j['location'] as String),
                      _chip(Icons.calendar_today_outlined, 'Closes: ${j['closingDate']}'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Reports to', j['reportsTo'] as String),
                  _buildInfoRow('Salary', j['salary'] as String),
                  const SizedBox(height: 16),
                  _buildBulletSection('Key Responsibilities', j['responsibilities'] as List),
                  const SizedBox(height: 12),
                  _buildBulletSection('Key Requirements', j['requirements'] as List),
                  const SizedBox(height: 16),
                  if (!_showForm)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => setState(() => _showForm = true),
                            icon: const Icon(Icons.send, size: 16),
                            label: const Text('Apply Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    _ApplicationForm(job: j),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
          Text(value, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildBulletSection(String title, List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...items.map((i) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, size: 14, color: _green),
              const SizedBox(width: 8),
              Expanded(child: Text(i.toString(), style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
            ],
          ),
        )),
      ],
    );
  }
}

class _ApplicationForm extends StatefulWidget {
  final Map<String, dynamic> job;
  const _ApplicationForm({required this.job});

  @override
  State<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<_ApplicationForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _coverCtrl = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _coverCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ApiService.submitJobApplication(
        jobId: widget.job['id'] as String,
        jobTitle: widget.job['title'] as String,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        coverLetter: _coverCtrl.text.trim(),
      );
      if (mounted) setState(() { _submitted = true; _isLoading = false; });
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(context, message: ErrorHandlerService.getErrorMessage(e));
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Application Submitted!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text('We\'ll review your application and get back to you at ${_emailCtrl.text}',
                      style: TextStyle(fontSize: 12, color: Colors.green[700])),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Apply for this Role', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _tf(_nameCtrl, 'Full Name *', Icons.person, required: true),
          const SizedBox(height: 10),
          _tf(_emailCtrl, 'Email *', Icons.email, keyboard: TextInputType.emailAddress, required: true),
          const SizedBox(height: 10),
          _tf(_phoneCtrl, 'Phone *', Icons.phone, keyboard: TextInputType.phone, required: true),
          const SizedBox(height: 10),
          TextFormField(
            controller: _coverCtrl,
            maxLines: 4,
            maxLength: 2500,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Cover Letter (Optional)',
              labelStyle: TextStyle(color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Application', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboard, bool required = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
        prefixIcon: Icon(icon, color: _green, size: 18),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _green, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
      ),
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
    );
  }
}
