import 'package:flutter/material.dart';
import '../../../services/driver_auth_service.dart';
import '../../../services/api_service.dart';

const _kGreen  = Color(0xFF0D7C3B);
const _kBg     = Color(0xFFF4F5F7);
const _kText   = Color(0xFF111111);
const _kMuted  = Color(0xFF9CA3AF);
const _kBorder = Color(0xFFF3F4F6);
const _kAmber  = Color(0xFFD97706);

class DriverProfileTab extends StatefulWidget {
  const DriverProfileTab({super.key});

  @override
  State<DriverProfileTab> createState() => _DriverProfileTabState();
}

class _DriverProfileTabState extends State<DriverProfileTab> {
  Map<String, dynamic> _driver = {};
  Map<String, dynamic> _dash   = {};
  bool _loading = true;
  String _token = '', _driverId = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _token    = await DriverAuthService.getToken() ?? '';
    _driverId = await DriverAuthService.getDriverId() ?? '';
    final savedDriver = await DriverAuthService.getDriverData();
    if (savedDriver != null) setState(() => _driver = savedDriver);
    if (_token.isNotEmpty && _driverId.isNotEmpty) await _load();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _load() async {
    try {
      final res = await ApiService.fetchDriverDashboard(token: _token, driverId: _driverId);
      final data = res['data'];
      if (data is Map && mounted) {
        setState(() {
          _dash = Map<String, dynamic>.from(data as Map);
          if (data['driver'] is Map) {
            _driver = {..._driver, ...Map<String, dynamic>.from(data['driver'] as Map)};
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _logout() async {
    await DriverAuthService.clearSession();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/driver', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2.5));

    final fullName  = _driver['fullName']?.toString() ?? _driver['name']?.toString() ?? 'Driver';
    final email     = _driver['email']?.toString() ?? '';
    final phone     = _driver['phone']?.toString() ?? _driver['phoneNumber']?.toString() ?? '';
    final picUrl    = _driver['profileImage']?.toString() ?? _driver['profilePicture']?.toString() ?? _driver['avatar']?.toString();
    final initial   = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'D';
    final totalDeliveries = _dash['totalDeliveries'] ?? _driver['totalDeliveries'] ?? 0;
    final avgRating = (_driver['averageRating'] ?? _driver['rating'] ?? 0.0);
    final ratingStr = (avgRating is num) ? avgRating.toStringAsFixed(1) : '5.0';
    final acceptance = _driver['acceptanceRate'] ?? _dash['driver']?['acceptanceRate'] ?? 100;

    return RefreshIndicator(
      onRefresh: _load,
      color: _kGreen,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(children: [
          // ── Profile header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(children: [
              Stack(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _kGreen, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: picUrl != null && picUrl.startsWith('http')
                      ? Image.network(picUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initAvatar(initial))
                      : _initAvatar(initial),
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: _kGreen, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    alignment: Alignment.center,
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Text(fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _kText)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(email, style: const TextStyle(fontSize: 13, color: _kMuted)),
              ],
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(phone, style: const TextStyle(fontSize: 12, color: _kMuted)),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(10)),
                child: const Text('Verified Driver',
                    style: TextStyle(color: _kGreen, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _profileStat('$totalDeliveries', 'Deliveries'),
                Container(width: 1, height: 36, color: _kBorder),
                _profileStat(ratingStr, 'Rating', icon: Icons.star_rounded, iconColor: _kAmber),
                Container(width: 1, height: 36, color: _kBorder),
                _profileStat('$acceptance%', 'Acceptance'),
              ]),
            ]),
          ),
          const SizedBox(height: 8),
          // ── Menu items ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _menuItem(Icons.person_outline_rounded, 'Personal Info',    () => _openPersonalInfo()),
              _menuItem(Icons.two_wheeler_rounded,    'Vehicle Details',  () => _openVehicleDetails()),
              _menuItem(Icons.description_outlined,   'Documents',        () => _openDocuments()),
              _menuItem(Icons.account_balance_wallet_outlined, 'Payout Method', () => _openPayoutMethod()),
              _menuItem(Icons.star_outline_rounded,   'Ratings & Reviews',() => _openRatings()),
              _menuItem(Icons.settings_outlined,      'Settings',         () => _openSettings()),
              _menuItem(Icons.help_outline_rounded,   'Help & Support',   () => _openHelp()),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700, fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('YooKatale Driver v2.1', style: TextStyle(color: _kMuted, fontSize: 11)),
            ]),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── Personal Info Modal ─────────────────────────────────────────────────
  void _openPersonalInfo() {
    final nameCtrl  = TextEditingController(text: _driver['name']?.toString() ?? _driver['fullName']?.toString() ?? '');
    final emailCtrl = TextEditingController(text: _driver['email']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: _driver['phone']?.toString() ?? _driver['phoneNumber']?.toString() ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sheetHeader('Personal Information'),
            const SizedBox(height: 20),
            _inputField('Full Name', nameCtrl),
            const SizedBox(height: 12),
            _inputField('Email Address', emailCtrl, keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _inputField('Phone Number', phoneCtrl, keyboard: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  setSt(() => saving = true);
                  try {
                    final res = await ApiService.updateDriverProfile(
                      token: _token, driverId: _driverId,
                      data: {'name': nameCtrl.text.trim(), 'email': emailCtrl.text.trim(), 'phone': phoneCtrl.text.trim()},
                    );
                    if (res['status'] == 'Success' && mounted) {
                      setState(() {
                        _driver['name'] = nameCtrl.text.trim();
                        _driver['fullName'] = nameCtrl.text.trim();
                        _driver['email'] = emailCtrl.text.trim();
                        _driver['phone'] = phoneCtrl.text.trim();
                      });
                      await DriverAuthService.saveSession(_token, _driver);
                      Navigator.pop(ctx);
                      _showToast('Profile updated!');
                    }
                  } catch (e) {
                    _showToast('Update failed. Try again.', error: true);
                  } finally { setSt(() => saving = false); }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: saving ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  // ── Vehicle Details Modal ────────────────────────────────────────────────
  void _openVehicleDetails() {
    final plateCtrl = TextEditingController(text: _driver['numberPlate']?.toString() ?? _driver['vehiclePlate']?.toString() ?? '');
    String vehicleType = _driver['vehicleType']?.toString() ?? _driver['transportType']?.toString() ?? 'motorcycle';
    bool saving = false;
    final types = ['motorcycle', 'bicycle', 'car', 'van', 'truck'];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sheetHeader('Vehicle Details'),
            const SizedBox(height: 20),
            const Text('Vehicle Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: types.map((t) => ChoiceChip(
              label: Text(t[0].toUpperCase() + t.substring(1), style: TextStyle(
                  color: vehicleType == t ? Colors.white : _kText, fontSize: 12)),
              selected: vehicleType == t,
              selectedColor: _kGreen,
              backgroundColor: Colors.white,
              side: BorderSide(color: vehicleType == t ? _kGreen : _kBorder),
              onSelected: (_) => setSt(() => vehicleType = t),
            )).toList()),
            const SizedBox(height: 16),
            _inputField('Number Plate', plateCtrl),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  setSt(() => saving = true);
                  try {
                    final res = await ApiService.updateDriverProfile(
                      token: _token, driverId: _driverId,
                      data: {'vehicleType': vehicleType, 'numberPlate': plateCtrl.text.trim()},
                    );
                    if (res['status'] == 'Success' && mounted) {
                      setState(() {
                        _driver['vehicleType'] = vehicleType;
                        _driver['numberPlate'] = plateCtrl.text.trim();
                      });
                      Navigator.pop(ctx);
                      _showToast('Vehicle details updated!');
                    }
                  } catch (_) {
                    _showToast('Update failed. Try again.', error: true);
                  } finally { setSt(() => saving = false); }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: saving ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  // ── Documents Modal ──────────────────────────────────────────────────────
  void _openDocuments() {
    final docs = _driver['documents'] as Map? ?? _driver['verification'] as Map? ?? {};
    final nationalId = docs['nationalId']?.toString() ?? 'pending';
    final drivingLicense = docs['drivingLicense']?.toString() ?? 'pending';
    final vehicleReg = docs['vehicleRegistration']?.toString() ?? 'pending';

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sheetHeader('Documents'),
          const SizedBox(height: 8),
          const Text('Document verification status', style: TextStyle(fontSize: 13, color: _kMuted)),
          const SizedBox(height: 20),
          _docRow('National ID', nationalId),
          const SizedBox(height: 12),
          _docRow('Driving License', drivingLicense),
          const SizedBox(height: 12),
          _docRow('Vehicle Registration', vehicleReg),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A))),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, size: 16, color: _kAmber),
              SizedBox(width: 8),
              Expanded(child: Text('Contact support to update your documents.',
                  style: TextStyle(fontSize: 12, color: _kAmber))),
            ]),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  // ── Payout Method Modal ──────────────────────────────────────────────────
  void _openPayoutMethod() {
    final payout = _driver['payoutMethod'] as Map? ?? <String, dynamic>{};
    String provider = payout['provider']?.toString() ?? 'mtn';
    final phoneCtrl = TextEditingController(text: payout['phone']?.toString() ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sheetHeader('Payout Method'),
            const SizedBox(height: 20),
            const Text('Mobile Money Provider', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _providerChip('MTN Mobile Money', 'mtn', provider, (v) => setSt(() => provider = v))),
              const SizedBox(width: 10),
              Expanded(child: _providerChip('Airtel Money', 'airtel', provider, (v) => setSt(() => provider = v))),
            ]),
            const SizedBox(height: 16),
            _inputField('Mobile Money Phone Number', phoneCtrl, keyboard: TextInputType.phone),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  setSt(() => saving = true);
                  try {
                    final res = await ApiService.updateDriverPayoutMethod(
                      token: _token, driverId: _driverId,
                      data: {'provider': provider, 'phone': phoneCtrl.text.trim(), 'type': 'mobile_money'},
                    );
                    if (res['status'] == 'Success' && mounted) {
                      setState(() => _driver['payoutMethod'] = {'provider': provider, 'phone': phoneCtrl.text.trim()});
                      Navigator.pop(ctx);
                      _showToast('Payout method updated!');
                    }
                  } catch (_) {
                    _showToast('Update failed. Try again.', error: true);
                  } finally { setSt(() => saving = false); }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: saving ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Payout Method', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      )),
    );
  }

  // ── Ratings Modal ────────────────────────────────────────────────────────
  void _openRatings() {
    bool loading = true;
    List<dynamic> ratings = [];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) {
        if (loading) {
          ApiService.fetchDriverRatings(token: _token, driverId: _driverId).then((res) {
            final data = res['data'] ?? res['ratings'];
            setSt(() {
              ratings = data is List ? data : [];
              loading = false;
            });
          }).catchError((_) => setSt(() => loading = false));
        }
        final avgRating = _driver['averageRating'] ?? _driver['rating'] ?? 0.0;
        final ratingStr = (avgRating is num) ? avgRating.toStringAsFixed(1) : '0.0';
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sheetHeader('Ratings & Reviews'),
            const SizedBox(height: 16),
            Row(children: [
              Text(ratingStr, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: _kText)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: List.generate(5, (i) => Icon(Icons.star_rounded,
                    size: 18, color: i < (avgRating as num).round() ? _kAmber : _kBorder))),
                const SizedBox(height: 2),
                Text('${_driver['ratingCount'] ?? ratings.length} reviews',
                    style: const TextStyle(fontSize: 12, color: _kMuted)),
              ]),
            ]),
            const SizedBox(height: 16),
            const Divider(),
            if (loading)
              const Center(child: Padding(padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _kGreen, strokeWidth: 2)))
            else if (ratings.isEmpty)
              const Padding(padding: EdgeInsets.all(24),
                  child: Center(child: Text('No reviews yet', style: TextStyle(color: _kMuted))))
            else
              Expanded(child: ListView.builder(
                shrinkWrap: true,
                itemCount: ratings.length,
                itemBuilder: (_, i) {
                  final r = ratings[i] as Map? ?? <String, dynamic>{};
                  final stars = ((r['rating'] ?? r['stars'] ?? 0) as num).round();
                  final comment = r['comment']?.toString() ?? r['review']?.toString() ?? '';
                  final user = r['customerName']?.toString() ?? r['userName']?.toString() ?? 'Customer';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(width: 32, height: 32, decoration: const BoxDecoration(color: _kBorder, shape: BoxShape.circle),
                            alignment: Alignment.center,
                            child: Text(user.isNotEmpty ? user[0].toUpperCase() : 'C',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(user, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Row(children: List.generate(5, (j) => Icon(Icons.star_rounded, size: 12,
                              color: j < stars ? _kAmber : _kBorder))),
                        ])),
                      ]),
                      if (comment.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(comment, style: const TextStyle(fontSize: 13, color: _kMuted, height: 1.4)),
                      ],
                      const Divider(),
                    ]),
                  );
                },
              )),
          ]),
        );
      }),
    );
  }

  // ── Settings Modal ───────────────────────────────────────────────────────
  void _openSettings() {
    bool pushNotifs = _driver['pushNotifications'] as bool? ?? true;
    bool locationSharing = _driver['locationSharing'] as bool? ?? true;
    bool soundAlerts = _driver['soundAlerts'] as bool? ?? true;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSt) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sheetHeader('Settings'),
          const SizedBox(height: 16),
          _settingsToggle('Push Notifications', 'Receive order alerts', Icons.notifications_rounded,
              pushNotifs, (v) => setSt(() => pushNotifs = v)),
          const Divider(),
          _settingsToggle('Location Sharing', 'Share real-time location with customers', Icons.location_on_rounded,
              locationSharing, (v) => setSt(() => locationSharing = v)),
          const Divider(),
          _settingsToggle('Sound Alerts', 'Play sound for new orders', Icons.volume_up_rounded,
              soundAlerts, (v) => setSt(() => soundAlerts = v)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await ApiService.updateDriverProfile(
                    token: _token, driverId: _driverId,
                    data: {'pushNotifications': pushNotifs, 'locationSharing': locationSharing, 'soundAlerts': soundAlerts},
                  );
                  if (mounted) {
                    setState(() {
                      _driver['pushNotifications'] = pushNotifs;
                      _driver['locationSharing'] = locationSharing;
                      _driver['soundAlerts'] = soundAlerts;
                    });
                    Navigator.pop(ctx);
                    _showToast('Settings saved!');
                  }
                } catch (_) {
                  _showToast('Failed to save settings.', error: true);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      )),
    );
  }

  // ── Help & Support ───────────────────────────────────────────────────────
  void _openHelp() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sheetHeader('Help & Support'),
          const SizedBox(height: 20),
          _helpItem(Icons.email_outlined, 'Email Support', 'support@yookatale.com'),
          const Divider(),
          _helpItem(Icons.phone_outlined, 'Phone Support', '+256 700 000 000'),
          const Divider(),
          _helpItem(Icons.chat_bubble_outline_rounded, 'Live Chat', 'Available 8am - 8pm EAT'),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _initAvatar(String ini) => Container(
    color: _kGreen, alignment: Alignment.center,
    child: Text(ini, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
  );

  Widget _profileStat(String value, String label, {IconData? icon, Color? iconColor}) {
    return Column(children: [
      if (icon != null) ...[Icon(icon, color: iconColor ?? _kGreen, size: 14), const SizedBox(height: 2)],
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kText)),
      Text(label, style: const TextStyle(fontSize: 10, color: _kMuted)),
    ]);
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder)),
        child: Row(children: [
          Icon(icon, color: _kGreen, size: 20),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: _kText, fontSize: 14, fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right_rounded, color: _kMuted, size: 18),
        ]),
      ),
    );
  }

  Widget _sheetHeader(String title) => Row(children: [
    Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _kText))),
    GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(width: 28, height: 28,
          decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.center,
          child: const Icon(Icons.close_rounded, size: 16, color: _kText)),
    ),
  ]);

  Widget _inputField(String label, TextEditingController ctrl, {TextInputType? keyboard}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kMuted)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl, keyboardType: keyboard,
        style: const TextStyle(fontSize: 14, color: _kText),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGreen, width: 1.5)),
          filled: true, fillColor: Colors.white,
        ),
      ),
    ],
  );

  Widget _providerChip(String label, String value, String selected, void Function(String) onSel) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onSel(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? _kGreen : _kBorder, width: active ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: active ? _kGreen : _kText)),
      ),
    );
  }

  Widget _docRow(String label, String status) {
    final isVerified = status == 'verified' || status == 'approved';
    final isPending  = status == 'pending' || status == 'processing';
    final color = isVerified ? _kGreen : (isPending ? _kAmber : Colors.red);
    final text  = isVerified ? 'Verified' : (isPending ? 'Pending' : 'Required');
    return Row(children: [
      Icon(isVerified ? Icons.check_circle_rounded : (isPending ? Icons.schedule_rounded : Icons.error_outline_rounded),
          color: color, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: _kText, fontWeight: FontWeight.w500))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    ]);
  }

  Widget _settingsToggle(String title, String sub, IconData icon, bool value, void Function(bool) onChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, color: _kGreen, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kText)),
          Text(sub, style: const TextStyle(fontSize: 11, color: _kMuted)),
        ])),
        Switch(value: value, onChanged: onChange, activeColor: _kGreen),
      ]),
    );
  }

  Widget _helpItem(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Container(width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: Icon(icon, color: _kGreen, size: 18)),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _kText)),
          Text(sub, style: const TextStyle(fontSize: 12, color: _kMuted)),
        ]),
      ]),
    );
  }

  void _showToast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red[700] : _kGreen,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }
}
