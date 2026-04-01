import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../authentication/widgets/mobile_sign_in.dart';
import '../../authentication/providers/auth_provider.dart';
// extractProfilePicUrl is defined in auth_provider.dart
import 'tabs/mobile_profile_tabs.dart';
import 'invite_friend_dialog.dart';
import 'edit_profile_page.dart';
import 'service_ratings_page.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

// Color constants
const _primaryGreen = Color(0xFF185F2D);
const _secondaryGreen = Color(0xFF1F793A);
const _darkGreen = Color(0xFF0B2416);
const _accent = Color(0xFF2ECC71);

class MobileAccountPage extends ConsumerStatefulWidget {
  const MobileAccountPage({super.key});

  @override
  ConsumerState<MobileAccountPage> createState() => _MobileAccountPageState();
}

class _MobileAccountPageState extends ConsumerState<MobileAccountPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _profilePicUrl;
  bool _isUploadingPic = false;
  int _activeTab = 0; // 0=Profile, 1=Orders, 2=Subscriptions, 3=Settings

  late TabController _tabController;

  static const _tabs = ['Profile', 'Orders', 'Subscriptions', 'Settings'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() => _activeTab = _tabController.index);
        }
      });
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    var userData = await AuthService.getUserData();

    // Try to fetch fresh data from /auth/me to sync avatar from webapp (Task 6)
    final freshData = await AuthService.fetchFreshUserData();
    if (freshData != null) {
      userData = freshData;
    }

    if (userData != null && userData.isNotEmpty) {
      final userId =
          userData['_id']?.toString() ?? userData['id']?.toString();
      if (userId != null) {
        final authState = ref.read(authStateProvider);
        if (!authState.isLoggedIn) {
          ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
            userId: userId,
            email: userData['email']?.toString(),
            firstName: userData['firstname']?.toString(),
            lastName: userData['lastname']?.toString(),
            profilePicUrl: extractProfilePicUrl(userData),
          );
        } else {
          // Update auth state with latest avatar if it changed
          final newAvatarUrl = extractProfilePicUrl(userData);
          if (newAvatarUrl != null && newAvatarUrl != authState.profilePicUrl) {
            ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
              userId: authState.userId,
              email: authState.email,
              firstName: authState.firstName,
              lastName: authState.lastName,
              profilePicUrl: newAvatarUrl,
            );
          }
        }
        final authStateNow = ref.read(authStateProvider);
        setState(() {
          _userData = userData;
          _profilePicUrl = authStateNow.profilePicUrl ??
              extractProfilePicUrl(userData);
          _isLoading = false;
        });
        return;
      }
    }

    final authState = ref.read(authStateProvider);
    if (authState.isLoggedIn && authState.userId != null) {
      setState(() {
        _userData = {
          '_id': authState.userId,
          'email': authState.email,
          'firstname': authState.firstName,
          'lastname': authState.lastName,
        };
        _profilePicUrl = authState.profilePicUrl;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _userData = null;
      _isLoading = false;
    });
  }

  Future<void> _showProfilePicOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Update Profile Photo',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: _primaryGreen),
                ),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        await _uploadProfilePicture(File(result.files.single.path!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    setState(() => _isUploadingPic = true);
    try {
      final token = await AuthService.getToken();
      final userData = await AuthService.getUserData();
      final userId =
          userData?['_id']?.toString() ?? userData?['id']?.toString();
      if (token == null || userId == null) throw Exception('Not authenticated');

      final res = await ApiService.uploadUserAvatar(
        userId: userId,
        filePath: imageFile.path,
        token: token,
      );
      final newUrl = res['data']?['avatar']?.toString() ??
          res['user']?['avatar']?.toString() ??
          res['avatar']?.toString();

      if (mounted) {
        if (newUrl != null) {
          setState(() => _profilePicUrl = newUrl);
          final updatedData = {...?_userData, 'avatar': newUrl};
          await AuthService.saveUserData(updatedData);
          final authState = ref.read(authStateProvider);
          ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
            userId: authState.userId,
            email: authState.email,
            firstName: authState.firstName,
            lastName: authState.lastName,
            profilePicUrl: newUrl,
          );
        }
        setState(() => _isUploadingPic = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPic = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.logout, color: Colors.red, size: 32),
              ),
              const SizedBox(height: 16),
              const Text('Logout',
                  style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Are you sure you want to logout?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Logout',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await AuthService.clearUserData();
      ref.read(authStateProvider.notifier).state = const AuthState.loggedOut();
      setState(() => _userData = null);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MobileSignInPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    if (authState.isLoggedIn && _userData == null && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadUserData();
      });
    }

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          backgroundColor: _primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar:
            const MobileBottomNavigationBar(currentIndex: 4),
      );
    }

    final isLoggedIn = authState.isLoggedIn || _userData != null;
    if (!isLoggedIn) return _buildLoggedOutView();

    return _buildLoggedInView();
  }

  // ── Logged-out screen ─────────────────────────────────────────
  Widget _buildLoggedOutView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: SingleChildScrollView(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_primaryGreen, _secondaryGreen],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My YooKatale Account',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/signin'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primaryGreen,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Access Account'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/signup'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: Colors.white, width: 2),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Create Account'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://wa.me/256786118137');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/help'),
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('FAQs'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.pushNamed(context, '/faqs'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── Logged-in screen ──────────────────────────────────────────
  Widget _buildLoggedInView() {
    final firstName = _userData!['firstname']?.toString() ?? '';
    final lastName = _userData!['lastname']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = _userData!['email']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _buildHeroCard(fullName, email)),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              tabController: _tabController,
              tabs: _tabs,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProfileTab(),
            const MobileOrdersTab(),
            const MobileSubscriptionsTab(),
            _buildSettingsTab(),
          ],
        ),
      ),
    );
  }

  // ── Hero card ─────────────────────────────────────────────────
  Widget _buildHeroCard(String fullName, String email) {
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').map((p) => p.isNotEmpty ? p[0] : '').take(2).join().toUpperCase()
        : '?';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0.0, -1.0),
          end: Alignment(0.5, 1.0),
          colors: [Color(0xFF061806), Color(0xFF1A5C1A), Color(0xFF2D8C2D)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _isUploadingPic ? null : _showProfilePicOptions,
                child: Stack(
                  children: [
                    // Gold ring
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF0C020), Color(0xFF4CD964)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: _isUploadingPic
                            ? Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                        Colors.white),
                                  ),
                                ),
                              )
                            : CircleAvatar(
                                radius: 40,
                                backgroundColor: Colors.white,
                                backgroundImage: _profilePicUrl != null
                                    ? NetworkImage(_profilePicUrl!)
                                    : null,
                                child: _profilePicUrl == null
                                    ? Text(initials,
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: _primaryGreen))
                                    : null,
                              ),
                      ),
                    ),
                    // Camera button
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE07820),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Name
              Text(
                fullName.isEmpty ? 'Your Name' : fullName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // FREE MEMBER badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0C020),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('FREE MEMBER',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatPill(label: 'Orders', value: '0'),
                  Container(
                      width: 1, height: 30, color: Colors.white24),
                  _StatPill(label: 'UGX Spent', value: '0'),
                  Container(
                      width: 1, height: 30, color: Colors.white24),
                  _StatPill(label: 'Points', value: '0'),
                ],
              ),
              const SizedBox(height: 16),
              // Loyalty progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Loyalty Progress',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 11)),
                      const Text('60%',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor:
                          const Color(0xFFF0C020).withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation(_accent),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile tab ───────────────────────────────────────────────
  Widget _buildProfileTab() {
    final userData = _userData ?? {};
    final email = userData['email']?.toString() ?? '';
    final phone = userData['phone']?.toString() ?? '';
    final address = userData['address']?.toString() ?? '';
    final gender = userData['gender']?.toString() ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(children: [
              _InfoRow(
                label: 'Full Name',
                value: '${userData['firstname'] ?? ''} ${userData['lastname'] ?? ''}'.trim(),
                onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfilePage())),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _InfoRow(
                label: 'Email',
                value: email.isNotEmpty ? email : 'Not set',
                onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfilePage())),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _InfoRow(
                label: 'Phone',
                value: phone.isNotEmpty ? phone : 'Not set',
                onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfilePage())),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _InfoRow(
                label: 'Address',
                value: address.isNotEmpty ? address : 'Not set',
                onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfilePage())),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _InfoRow(
                label: 'Gender',
                value: gender.isNotEmpty ? gender : 'Not set',
                onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const EditProfilePage())),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Edit profile button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EditProfilePage())),
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick actions
          _SectionLabel(label: 'Quick Actions'),
          const SizedBox(height: 10),
          _buildQuickMenu(),
          const SizedBox(height: 24),

          // Danger zone
          _SectionLabel(label: 'Account'),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Logout',
                    style: TextStyle(color: Colors.red)),
                trailing: const Icon(Icons.chevron_right,
                    color: Colors.red),
                onTap: _handleLogout,
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.red),
                title: const Text('Delete Account',
                    style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right,
                    color: Colors.red),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Please contact support to delete your account.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
              ),
            ]),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildQuickMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(children: [
        _QuickTile(
            icon: Icons.shopping_bag_outlined,
            title: 'My Orders',
            onTap: () =>
                _tabController.animateTo(1)),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _QuickTile(
            icon: Icons.card_membership,
            title: 'Subscriptions',
            onTap: () => _tabController.animateTo(2)),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _QuickTile(
            icon: Icons.calendar_today,
            title: 'Meal Calendar',
            onTap: () => Navigator.pushNamed(context, '/meal-calendar')),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _QuickTile(
            icon: Icons.card_giftcard_outlined,
            title: 'Invite Friends',
            badge: 'Earn',
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => InviteFriendDialog(
                  userId: _userData!['_id']?.toString() ?? '',
                ),
              );
            }),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _QuickTile(
            icon: Icons.star_outline,
            title: 'Rate Our Service',
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ServiceRatingsPage()))),
        const Divider(height: 1, indent: 16, endIndent: 16),
        _QuickTile(
            icon: Icons.help_outline,
            title: 'FAQs',
            onTap: () => Navigator.pushNamed(context, '/faqs')),
      ]),
    );
  }

  // ── Settings tab ──────────────────────────────────────────────
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _SectionLabel(label: 'Support & Contact'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: [
            _QuickTile(
              icon: Icons.phone_outlined,
              title: 'Call Us',
              subtitle: '+256786118137',
              onTap: () async {
                final uri = Uri.parse('tel:+256786118137');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _QuickTile(
              icon: Icons.chat_rounded,
              title: 'WhatsApp Support',
              onTap: () async {
                final uri = Uri.parse('https://wa.me/256786118137');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                }
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _QuickTile(
              icon: Icons.info_outline,
              title: 'About YooKatale',
              onTap: () => Navigator.pushNamed(context, '/about'),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        _SectionLabel(label: 'Opportunities'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: [
            _QuickTile(
              icon: Icons.two_wheeler,
              title: 'Driver Dashboard',
              onTap: () =>
                  Navigator.pushNamed(context, '/driver-dashboard'),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _QuickTile(
              icon: Icons.storefront,
              title: 'Become a Partner',
              onTap: () => Navigator.pushNamed(context, '/partner'),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16)),
      const SizedBox(height: 2),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]);
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onEdit;

  const _InfoRow({required this.label, required this.value, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      subtitle: Text(value,
          style: const TextStyle(
              fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
      trailing: IconButton(
        icon: const Icon(Icons.edit_rounded, size: 18, color: _primaryGreen),
        onPressed: onEdit,
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
              letterSpacing: 0.3)),
    );
  }
}

class _QuickTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
  final VoidCallback? onTap;

  const _QuickTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _primaryGreen, size: 22),
      title: Text(title,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: badge != null
          ? Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ])
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final List<String> tabs;

  _TabBarDelegate({required this.tabController, required this.tabs});

  @override
  double get minExtent => 50;

  @override
  double get maxExtent => 50;

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: tabController,
        isScrollable: true,
        labelColor: _primaryGreen,
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(
            fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: _primaryGreen, width: 2.5),
          insets: EdgeInsets.symmetric(horizontal: 8),
        ),
        tabs: tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }
}
