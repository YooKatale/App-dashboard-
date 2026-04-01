import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../services/auth_service.dart';
import '../../../services/api_service.dart';
import '../../../services/error_handler_service.dart';
import '../../authentication/providers/auth_provider.dart';

const _primaryGreen = Color(0xFF185F2D);
const _secondaryGreen = Color(0xFF1F793A);

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  bool _isPasswordExpanded = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  String? _selectedGender;
  Map<String, dynamic>? _userData;
  String? _profilePicUrl;

  static const _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthService.getUserData();
    if (userData != null) {
      final authState = ref.read(authStateProvider);
      setState(() {
        _userData = userData;
        _firstNameController.text = userData['firstname']?.toString() ?? '';
        _lastNameController.text = userData['lastname']?.toString() ?? '';
        _emailController.text = userData['email']?.toString() ?? '';
        _phoneController.text = userData['phone']?.toString() ?? '';
        _addressController.text = userData['address']?.toString() ?? '';
        _selectedGender = userData['gender']?.toString();
        _profilePicUrl = authState.profilePicUrl ??
            userData['avatar']?.toString() ??
            userData['profilePic']?.toString() ??
            userData['photoUrl']?.toString();
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        await _uploadAvatar(File(result.files.single.path!));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _uploadAvatar(File imageFile) async {
    setState(() => _isUploadingAvatar = true);
    try {
      final token = await AuthService.getToken();
      final userId =
          _userData?['_id']?.toString() ?? _userData?['id']?.toString();
      if (token == null || userId == null) {
        throw Exception('Not authenticated');
      }

      final res = await ApiService.uploadUserAvatar(
        userId: userId,
        filePath: imageFile.path,
        token: token,
      );
      final newUrl = res['data']?['avatar']?.toString() ??
          res['user']?['avatar']?.toString() ??
          res['avatar']?.toString();

      if (mounted && newUrl != null) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final token = await AuthService.getToken();
      final userId =
          _userData!['_id']?.toString() ?? _userData!['id']?.toString();

      final response = await ApiService.updateUserProfile(
        userId: userId!,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        token: token,
      );

      if (response['status'] == 'Success') {
        final updatedData = Map<String, dynamic>.from(_userData!);
        updatedData['firstname'] = _firstNameController.text.trim();
        updatedData['lastname'] = _lastNameController.text.trim();
        updatedData['email'] = _emailController.text.trim();
        updatedData['phone'] = _phoneController.text.trim();
        updatedData['address'] = _addressController.text.trim();
        if (_selectedGender != null) {
          updatedData['gender'] = _selectedGender;
        }
        await AuthService.saveUserData(updatedData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          message: ErrorHandlerService.getErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('New passwords do not match'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Password must be at least 6 characters'),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final userId =
          _userData!['_id']?.toString() ?? _userData!['id']?.toString();
      final response = await ApiService.changePassword(
        userId: userId!,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        token: token,
      );

      if (response['status'] == 'Success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          setState(() => _isPasswordExpanded = false);
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to change password');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showErrorSnackBar(
          context,
          message: ErrorHandlerService.getErrorMessage(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F4),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar section
              _buildAvatarSection(),
              const SizedBox(height: 20),

              // Personal info card
              _buildCard(
                title: 'Personal Information',
                children: [
                  _field(
                      controller: _firstNameController,
                      label: 'First Name',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your first name'
                          : null),
                  const SizedBox(height: 12),
                  _field(
                      controller: _lastNameController,
                      label: 'Last Name',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Enter your last name'
                          : null),
                  const SizedBox(height: 12),
                  _field(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      type: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Enter your email';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      }),
                  const SizedBox(height: 12),
                  _field(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      type: TextInputType.phone),
                ],
              ),
              const SizedBox(height: 16),

              // Optional info card
              _buildCard(
                title: 'Additional Details',
                children: [
                  _field(
                      controller: _addressController,
                      label: 'Delivery Address',
                      icon: Icons.location_on_outlined,
                      maxLines: 2),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: _inputDecoration(
                        'Gender', Icons.people_outline),
                    items: _genderOptions
                        .map((g) =>
                            DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _selectedGender = v),
                    style: const TextStyle(
                        color: Colors.black87, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Password section
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: ExpansionTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.lock_outline,
                        color: _primaryGreen, size: 20),
                  ),
                  title: const Text('Change Password',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  initiallyExpanded: _isPasswordExpanded,
                  onExpansionChanged: (e) =>
                      setState(() => _isPasswordExpanded = e),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(children: [
                        _passwordField(
                            controller: _currentPasswordController,
                            label: 'Current Password',
                            obscure: _obscureCurrent,
                            toggle: () => setState(
                                () => _obscureCurrent = !_obscureCurrent)),
                        const SizedBox(height: 12),
                        _passwordField(
                            controller: _newPasswordController,
                            label: 'New Password',
                            obscure: _obscureNew,
                            toggle: () => setState(
                                () => _obscureNew = !_obscureNew)),
                        const SizedBox(height: 12),
                        _passwordField(
                            controller: _confirmPasswordController,
                            label: 'Confirm New Password',
                            obscure: _obscureConfirm,
                            toggle: () => setState(
                                () =>
                                    _obscureConfirm = !_obscureConfirm)),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const _LoadingDot()
                                : const Text('Update Password',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryGreen, _secondaryGreen],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryGreen.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isLoading ? null : _updateProfile,
                    borderRadius: BorderRadius.circular(14),
                    child: Center(
                      child: _isLoading
                          ? const _LoadingDot()
                          : const Text(
                              'Save Changes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: _primaryGreen, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text('Edit Profile',
          style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 18)),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _updateProfile,
          child: const Text('Save',
              style: TextStyle(
                  color: _primaryGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    final initials = _firstNameController.text.isNotEmpty ||
            _lastNameController.text.isNotEmpty
        ? '${_firstNameController.text.isNotEmpty ? _firstNameController.text[0] : ''}${_lastNameController.text.isNotEmpty ? _lastNameController.text[0] : ''}'
            .toUpperCase()
        : '?';

    return Center(
      child: Stack(
        children: [
          // Gold ring + avatar
          Container(
            width: 106,
            height: 106,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFF0C020), Color(0xFF4CD964)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _profilePicUrl != null
                        ? NetworkImage(_profilePicUrl!)
                        : null,
                    child: _profilePicUrl == null
                        ? Text(initials,
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: _primaryGreen))
                        : null,
                  ),
                  if (_isUploadingAvatar)
                    Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black38,
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                  Colors.white),
                            ),
                            SizedBox(height: 4),
                            Text('Uploading…',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Camera overlay button
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: _primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt,
                    size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
      {required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black54)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? type,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: _inputDecoration(label, icon),
      validator: validator,
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      decoration: _inputDecoration(label, Icons.lock_outline).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
              obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: Colors.grey[500]),
          onPressed: toggle,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black54),
      prefixIcon: Icon(icon, size: 18, color: _primaryGreen),
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}

class _LoadingDot extends StatelessWidget {
  const _LoadingDot();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
          strokeWidth: 2, color: Colors.white),
    );
  }
}
