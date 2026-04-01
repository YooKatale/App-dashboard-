import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';

// ── Exact webapp colors ─────────────────────────────────────────────────────
const _kPrimary   = Color(0xFF185F2D); // ThemeColors.primaryColor
const _kSecondary = Color(0xFF2E7D32); // ThemeColors.secondaryColor
const _kGreen50   = Color(0xFFF0FFF4);
const _kGreen100  = Color(0xFFC6F6D5);
const _kGray50    = Color(0xFFF7FAFC);
const _kGray100   = Color(0xFFEDF2F7);
const _kGray400   = Color(0xFFA0AEC0);
const _kGray500   = Color(0xFF718096);
const _kGray600   = Color(0xFF4A5568);
const _kGray700   = Color(0xFF2D3748);
const _kGray800   = Color(0xFF1A202C);

class CareersPage extends StatefulWidget {
  const CareersPage({super.key});

  @override
  State<CareersPage> createState() => _CareersPageState();
}

class _CareersPageState extends State<CareersPage> {
  List<dynamic> _careers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCareers();
  }

  Future<void> _loadCareers() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.fetchCareers();
      final data = res['data'] ?? res['careers'] ?? res;
      if (mounted) {
        setState(() {
          _careers = data is List ? data : [];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandlerService.getErrorMessage(e);
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kGray800,
        elevation: 0,
        title: const Text('Careers',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _kGray800)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: _kPrimary,
        onRefresh: _loadCareers,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHero()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _kPrimary)),
              )
            else if (_error != null && _careers.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else if (_careers.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _JobCard(job: _careers[i]),
                    ),
                    childCount: _careers.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          // "Open Positions" label
          Text(
            'OPEN POSITIONS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kPrimary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          // "Join Our Team" gradient heading
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [_kPrimary, _kSecondary],
            ).createShader(bounds),
            child: const Text(
              'Join Our Team',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 10),

          // Green divider bar
          Container(
            width: 70,
            height: 4,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_kPrimary, _kSecondary]),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            "We're looking for passionate people to help grow Uganda's leading food marketplace.",
            style: const TextStyle(fontSize: 14, color: _kGray600, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Perks row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 10,
            children: [
              _PerkChip(icon: Icons.groups_outlined, label: 'Collaborative Team'),
              _PerkChip(icon: Icons.trending_up_rounded, label: 'Growth Opportunities'),
              _PerkChip(icon: Icons.favorite_outline_rounded, label: 'Mission-Driven Work'),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: _kGray50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kGray100, style: BorderStyle.none),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(color: _kGreen50, shape: BoxShape.circle),
            child: const Icon(Icons.work_outline_rounded, size: 28, color: _kPrimary),
          ),
          const SizedBox(height: 16),
          const Text('No open positions right now',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kGray700)),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(fontSize: 14, color: _kGray500, height: 1.5),
              children: [
                TextSpan(text: "We're not actively hiring at the moment, but send your CV to "),
                TextSpan(
                  text: 'info@yookatale.app',
                  style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Perk chip ──────────────────────────────────────────────────────────────
class _PerkChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PerkChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(color: _kGreen50, shape: BoxShape.circle),
          child: Icon(icon, size: 15, color: _kPrimary),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _kGray700)),
      ],
    );
  }
}

// ── Job card ────────────────────────────────────────────────────────────────
class _JobCard extends StatefulWidget {
  final dynamic job;
  const _JobCard({required this.job});

  @override
  State<_JobCard> createState() => _JobCardState();
}

class _JobCardState extends State<_JobCard> {
  bool _detailsOpen = false;
  bool _applyOpen   = false;

  dynamic get j => widget.job;
  String get jobId    => j['_id']?.toString() ?? j['id']?.toString() ?? '';
  String get title    => j['title']?.toString() ?? '';
  String get category => j['category']?.toString() ?? '';

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      final d = DateTime.parse(raw);
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) { return raw; }
  }

  void _toggleDetails() => setState(() {
    _applyOpen = false;
    _detailsOpen = !_detailsOpen;
  });

  void _toggleApply() => setState(() {
    _detailsOpen = false;
    _applyOpen = !_applyOpen;
  });

  void _share() {
    final url = 'https://www.yookatale.app/careers?job=$jobId';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Job link copied to clipboard'), backgroundColor: _kPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGray100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Card header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kGreen50,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: _kGreen100),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _kPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kGray800,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Meta grid ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MetaChip(icon: Icons.work_outline_rounded, label: 'Reports to', value: j['reportsTo']?.toString() ?? '—'),
                _MetaChip(icon: Icons.schedule_rounded, label: 'Employment', value: j['employment']?.toString() ?? j['type']?.toString() ?? '—'),
                _MetaChip(icon: Icons.description_outlined, label: 'Terms', value: j['terms']?.toString() ?? '—'),
                _MetaChip(icon: Icons.payments_outlined, label: 'Salary', value: j['salary']?.toString() ?? '—'),
                _MetaChip(icon: Icons.calendar_today_outlined, label: 'Closes', value: _formatDate(j['closingDate']?.toString())),
                _MetaChip(icon: Icons.location_on_outlined, label: 'Location', value: j['location']?.toString() ?? '—'),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(height: 1, color: _kGray100),

          // ── Actions ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                // View Details
                _ActionBtn(
                  label: _detailsOpen ? 'Hide Details' : 'View Details',
                  trailing: Icon(
                    _detailsOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 16, color: _kPrimary,
                  ),
                  outlined: true,
                  onTap: _toggleDetails,
                ),
                const SizedBox(width: 8),
                // Apply Now
                _ActionBtn(
                  label: 'Apply Now',
                  leading: const Icon(Icons.send_rounded, size: 14, color: Colors.white),
                  filled: true,
                  onTap: _toggleApply,
                ),
                const Spacer(),
                // Share
                GestureDetector(
                  onTap: _share,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kGray50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.ios_share_rounded, size: 16, color: _kGray500),
                  ),
                ),
              ],
            ),
          ),

          // ── Expandable details ────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _detailsOpen ? _buildDetails() : const SizedBox.shrink(),
          ),

          // ── Apply form ────────────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            child: _applyOpen ? _ApplyForm(jobId: jobId, jobTitle: title) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    final responsibilities = j['responsibilities'] is List ? j['responsibilities'] as List : [];
    final requirements     = j['requirements']     is List ? j['requirements']     as List : [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: _kGray100),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Key Responsibilities',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kGray800)),
                        const SizedBox(height: 8),
                        ...responsibilities.map((r) => _BulletPoint(text: r.toString(), color: _kPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Key Requirements',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kGray800)),
                        const SizedBox(height: 8),
                        ...requirements.map((r) => _BulletPoint(text: r.toString(), color: _kSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Apply note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kGreen50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kGreen100),
                ),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 12.5, color: _kGray700, height: 1.5),
                    children: [
                      TextSpan(text: 'To Apply: ', style: TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: 'Send your resume to '),
                      TextSpan(
                        text: 'info@yookatale.app',
                        style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: ' or use the Apply Now button above.'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Apply form ──────────────────────────────────────────────────────────────
class _ApplyForm extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  const _ApplyForm({required this.jobId, required this.jobTitle});

  @override
  State<_ApplyForm> createState() => _ApplyFormState();
}

class _ApplyFormState extends State<_ApplyForm> {
  final _nameCtrl        = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _phoneCtrl       = TextEditingController();
  final _coverLetterCtrl = TextEditingController();
  String? _cvFileName;
  String? _cvPath;
  bool _loading   = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _coverLetterCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _cvFileName = result.files.single.name;
        _cvPath     = result.files.single.path;
      });
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_cvPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach your CV (PDF)'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      // Upload CV first
      String? resumeUrl;
      try {
        final uploadRes = await ApiService.uploadCv(filePath: _cvPath!);
        resumeUrl = uploadRes['url']?.toString() ?? uploadRes['data']?.toString();
      } catch (_) {
        // CV upload failed — submit without resume URL
      }

      await ApiService.submitJobApplicationWithResume(
        jobId: widget.jobId,
        jobTitle: widget.jobTitle,
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        coverLetter: _coverLetterCtrl.text.trim(),
        resume: resumeUrl,
      );
      if (mounted) setState(() { _submitted = true; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandlerService.getErrorMessage(e)), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, color: _kGray100),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: _submitted ? _buildSuccess() : _buildForm(),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: _kGreen50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGreen100),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.send_rounded, size: 22, color: _kPrimary),
          ),
          const SizedBox(height: 12),
          const Text('Application submitted!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kGray800)),
          const SizedBox(height: 4),
          const Text("Thank you for applying. We'll be in touch soon.",
              style: TextStyle(fontSize: 13, color: _kGray600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kGray50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kGray100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apply for ${widget.jobTitle}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _kGray800)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _FormField(ctrl: _nameCtrl,  icon: Icons.person_outline_rounded,  label: 'Full Name *',  hint: 'e.g. Nakato Amina')),
              const SizedBox(width: 10),
              Expanded(child: _FormField(ctrl: _emailCtrl, icon: Icons.email_outlined,           label: 'Email *',      hint: 'e.g. amina@gmail.com', keyboardType: TextInputType.emailAddress)),
            ],
          ),
          const SizedBox(height: 10),
          _FormField(ctrl: _phoneCtrl, icon: Icons.phone_outlined, label: 'Phone *', hint: '+256 700 000 000', keyboardType: TextInputType.phone),
          const SizedBox(height: 10),

          // CV Upload
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel(icon: Icons.upload_file_outlined, label: 'Attach CV / Resume *'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickCv,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _kGray100),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file_rounded, size: 18, color: _cvPath != null ? _kPrimary : _kGray400),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _cvFileName ?? 'Tap to select PDF file',
                          style: TextStyle(
                            fontSize: 13,
                            color: _cvPath != null ? _kGray700 : _kGray400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_cvPath != null)
                        const Icon(Icons.check_circle_rounded, size: 16, color: _kPrimary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 3),
              const Text('PDF format only · Max 5MB',
                  style: TextStyle(fontSize: 11, color: _kGray400)),
            ],
          ),
          const SizedBox(height: 10),

          // Cover letter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FieldLabel(icon: Icons.description_outlined, label: 'Cover Letter'),
              const SizedBox(height: 6),
              TextField(
                controller: _coverLetterCtrl,
                maxLines: 4,
                maxLength: 2500,
                style: const TextStyle(fontSize: 13, color: _kGray700),
                decoration: InputDecoration(
                  hintText: "Tell us why you're a great fit for this role...",
                  hintStyle: const TextStyle(fontSize: 13, color: _kGray400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _kGray100),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: _kGray100),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                  counterStyle: const TextStyle(fontSize: 11, color: _kGray400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 16),
              label: Text(_loading ? 'Submitting...' : 'Submit Application',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small widgets ────────────────────────────────────────────────────────────
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetaChip({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _kGray50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kGray100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: _kGray400),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: const TextStyle(fontSize: 9, color: _kGray400, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              Text(value,
                  style: const TextStyle(fontSize: 12, color: _kGray700, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Widget? leading;
  final Widget? trailing;
  final bool outlined;
  final bool filled;
  final VoidCallback? onTap;
  const _ActionBtn({required this.label, this.leading, this.trailing,
      this.outlined = false, this.filled = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? _kPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: outlined ? _kPrimary : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 5)],
            Text(label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : _kPrimary,
                )),
            if (trailing != null) ...[const SizedBox(width: 4), trailing!],
          ],
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final Color color;
  const _BulletPoint({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Container(
              width: 5, height: 5,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12.5, color: _kGray600, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FieldLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _kGray600),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kGray700)),
      ],
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final IconData icon;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  const _FormField({required this.ctrl, required this.icon, required this.label,
      required this.hint, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(icon: icon, label: label),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 13, color: _kGray700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: _kGray400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _kGray100),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _kGray100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
