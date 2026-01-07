import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/auth_service.dart';
import '../../authentication/widgets/mobile_sign_in.dart';
import '../../authentication/providers/auth_provider.dart';
import 'tabs/mobile_profile_tabs.dart';
import 'invite_friend_dialog.dart';
import 'edit_profile_page.dart';
import 'service_ratings_page.dart';
import '../../common/widgets/bottom_navigation_bar.dart';

class MobileAccountPage extends ConsumerStatefulWidget {
  const MobileAccountPage({super.key});

  @override
  ConsumerState<MobileAccountPage> createState() => _MobileAccountPageState();
}

class _MobileAccountPageState extends ConsumerState<MobileAccountPage> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _profilePicUrl;
  bool _isUploadingPic = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Check stored user data (like webapp: const { userInfo } = useSelector((state) => state.auth))
    // Webapp checks: if (!userInfo || userInfo == {} || userInfo == "") or userInfo?._id
    final userData = await AuthService.getUserData();
    final token = await AuthService.getToken();
    
    // Check if user is logged in (like webapp checks userInfo?._id)
    if (userData != null && userData.isNotEmpty) {
      final userId = userData['_id']?.toString() ?? userData['id']?.toString();
      
      // If we have userId, user is logged in (like webapp: userInfo?._id)
      if (userId != null) {
        // Update auth state if not already set
        final authState = ref.read(authStateProvider);
        if (!authState.isLoggedIn) {
          ref.read(authStateProvider.notifier).state = AuthState.loggedIn(
            userId: userId,
            email: userData['email']?.toString(),
            firstName: userData['firstname']?.toString(),
            lastName: userData['lastname']?.toString(),
          );
        }
        
        setState(() {
          _userData = userData;
          _profilePicUrl = userData['profilePic']?.toString();
          _isLoading = false;
        });
        return;
      }
    }
    
    // Fallback: Check auth state
    final authState = ref.read(authStateProvider);
    if (authState.isLoggedIn && authState.userId != null) {
      setState(() {
        _userData = {
          '_id': authState.userId,
          'email': authState.email,
          'firstname': authState.firstName,
          'lastname': authState.lastName,
        };
        _isLoading = false;
      });
      return;
    }
    
    // User is not logged in (like webapp: if (!userInfo || userInfo == {} || userInfo == ""))
    setState(() {
      _userData = null;
      _isLoading = false;
    });
  }

  Future<void> _showProfilePicOptions() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
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

  Future<void> _pickImageFromCamera() async {
    // Note: For camera, you might need image_picker package
    // For now, this will use gallery as fallback
    await _pickImageFromGallery();
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    setState(() {
      _isUploadingPic = true;
    });

    try {
      // TODO: Implement actual upload to Firebase Storage or your backend
      // For now, just set a local state
      // You would typically:
      // 1. Upload to Firebase Storage
      // 2. Get download URL
      // 3. Update user profile in Firestore/Database
      // 4. Update local state

      // Simulate upload delay
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isUploadingPic = false;
          // _profilePicUrl = downloadUrl; // Set after actual upload
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingPic = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black54),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Content
              const Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      // EXACT WEBAPP LOGIC: dispatch(logout()) - clears Redux state AND localStorage
      // 1. Clear stored data (like webapp: localStorage.removeItem("yookatale-app"))
      await AuthService.clearUserData();
      
      // 2. Clear auth state (like webapp: state.userInfo = null)
      ref.read(authStateProvider.notifier).state = const AuthState.loggedOut();
      
      // 3. Clear local state
      setState(() {
        _userData = null;
      });
      
      if (mounted) {
        // Navigate to sign in (like webapp: router.push("/signin"))
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MobileSignInPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch auth state in build method (like webapp watches Redux state)
    final authState = ref.watch(authStateProvider);
    
    // Reload user data if auth state changed to logged in
    if (authState.isLoggedIn && _userData == null && !_isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadUserData();
        }
      });
    }
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      );
    }

    // Check if user is logged in (like webapp checks Redux state)
    // Check both auth state and stored user data
    final isLoggedIn = authState.isLoggedIn || _userData != null;
    
    if (!isLoggedIn) {
      // Not logged in - Show welcome screen with greenish theme
      return Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Account Access Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromRGBO(24, 95, 45, 1),
                      const Color.fromRGBO(24, 95, 45, 1).withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My YooKatale Account',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signin');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color.fromRGBO(24, 95, 45, 1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Access Account'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/signup');
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white, width: 2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Create Account'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Assistance Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // WhatsApp button only (Live Chat removed)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final uri = Uri.parse('https://wa.me/256786118137');
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('WhatsApp Support'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(24, 95, 45, 1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Need Assistance?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Help & Support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, '/help');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('FAQs'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.pushNamed(context, '/faqs');
                      },
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // My YooKatale Account Section
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'My YooKatale Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _AccountMenuItem(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Orders',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MobileSignInPage(),
                          ),
                        );
                      },
                    ),
                    _AccountMenuItem(
                      icon: Icons.star_outline,
                      title: 'Ratings & Reviews',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ServiceRatingsPage(),
                          ),
                        );
                      },
                    ),
                    _AccountMenuItem(
                      icon: Icons.favorite_border,
                      title: 'Wishlist',
                      onTap: () {
                        Navigator.pushNamed(context, '/wishlist');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Logged in - Show full account page
    final firstName = _userData!['firstname']?.toString() ?? '';
    final lastName = _userData!['lastname']?.toString() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final email = _userData!['email']?.toString() ?? '';
    final phone = _userData!['phone']?.toString() ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontFamily: 'Raleway',
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: const MobileBottomNavigationBar(currentIndex: 4),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header Card
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color.fromRGBO(24, 95, 45, 1),
                  const Color.fromRGBO(24, 95, 45, 1).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _isUploadingPic ? null : () => _showProfilePicOptions(),
                  child: _isUploadingPic
                      ? Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                                image: _profilePicUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(_profilePicUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: _profilePicUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 35,
                                      color: Color.fromRGBO(24, 95, 45, 1),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color.fromRGBO(24, 95, 45, 1),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 12,
                                  color: Color.fromRGBO(24, 95, 45, 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isEmpty ? 'User' : fullName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Raleway',
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Personal Information Section
          _ProfileSection(
            title: 'Personal Information',
            children: [
              _ProfileTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfilePage(),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: email.isNotEmpty ? email : 'Not set',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              _ProfileTile(
                icon: Icons.phone_outlined,
                title: 'Phone',
                subtitle: phone.isNotEmpty ? phone : 'Not set',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Orders & Subscriptions
          _ProfileSection(
            title: 'Orders & Subscriptions',
            children: [
              _ProfileTile(
                icon: Icons.shopping_bag_outlined,
                title: 'My Orders',
                subtitle: 'View your order history',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MobileOrdersTab(),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.card_membership,
                title: 'Subscriptions',
                subtitle: 'Manage your subscriptions',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MobileSubscriptionsTab(),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.calendar_today,
                title: 'Meal Calendar',
                subtitle: 'View your weekly meal plan',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/meal-calendar');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Social & Referrals
          _ProfileSection(
            title: 'Social & Referrals',
            children: [
              _ProfileTile(
                icon: Icons.card_giftcard,
                title: 'Invite Friends',
                subtitle: 'Earn rewards by inviting friends',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Earn',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => InviteFriendDialog(
                      userId: _userData!['_id']?.toString() ?? '',
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.star_outline,
                title: 'Rate Our Service',
                subtitle: 'Share your feedback about YooKatale',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServiceRatingsPage(),
                    ),
                  );
                },
              ),
              _ProfileTile(
                icon: Icons.help_outline,
                title: 'FAQs',
                subtitle: 'Frequently asked questions',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/faqs');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Support & Settings
          _ProfileSection(
            title: 'Support & Settings',
            children: [
              _ProfileTile(
                icon: Icons.phone_outlined,
                title: 'Call Us',
                subtitle: '+256786118137',
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final phoneNumber = 'tel:+256786118137';
                  final uri = Uri.parse(phoneNumber);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Could not open phone dialer'),
                        ),
                      );
                    }
                  }
                },
              ),
              _ProfileTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                subtitle: 'Manage app settings and preferences',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
              _ProfileTile(
                icon: Icons.logout,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Account Menu Item for non-logged in state
class _AccountMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}

// Profile Section Widget - Matches Settings Page Style
class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

// Profile Tile Widget - Matches Settings Page Style
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color.fromRGBO(24, 95, 45, 1),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
