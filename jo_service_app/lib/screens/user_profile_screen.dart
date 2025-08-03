import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as ctxProvider;
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../l10n/app_localizations.dart';
import './role_selection_screen.dart';

class UserProfileScreen extends StatefulWidget {
  static const routeName = '/user-profile';

  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final ApiService _apiService = ApiService();
  Future<User?>? _userProfileFuture;
  User? _currentUser;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  // TextEditingControllers for editable fields
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProfile();
      }
    });
  }

  void _loadProfile() async {
    final authService =
        ctxProvider.Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!.authenticationTokenNotFound)),
        );
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
      setState(() {
        _userProfileFuture =
            Future.error(Exception('Authentication token not found.'));
      });
      return;
    }
    setState(() {
      _userProfileFuture = _apiService.getMyUserProfile(token).then((user) {
        if (user != null) {
          _currentUser = user;
          _initializeControllers(user);
        }
        return user;
      });
    });
  }

  void _initializeControllers(User user) {
    _fullNameController.text = user.fullName ?? '';
    _phoneNumberController.text = user.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authService =
          ctxProvider.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null || token.isEmpty || _currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.authenticationError)),
          );
        }
        return;
      }

      final Map<String, dynamic> updatedData = {
        'fullName': _fullNameController.text,
        'phoneNumber': _phoneNumberController.text,
      };

      try {
        final updatedUser =
            await _apiService.updateMyUserProfile(token, updatedData);

        setState(() {
          _currentUser = updatedUser;
          _initializeControllers(updatedUser);
          _isEditing = false;
          _userProfileFuture = Future.value(updatedUser);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.profileUpdatedSuccessfully)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUpdateProfile}: $e')),
          );
        }
      }
    }
  }

  // Add method to pick image from gallery
  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.imageUploadNotSupportedWeb)),
      );
      return;
    }

    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _uploadProfilePicture();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorPickingImage}: $e')),
        );
      }
    }
  }

  // Add method to upload profile picture
  Future<void> _uploadProfilePicture() async {
    if (_imageFile == null) return;

    try {
      setState(() {
        _isUploading = true;
      });

      final authService =
          ctxProvider.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.authenticationError)),
          );
        }
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final updatedUser =
          await _apiService.uploadUserProfilePicture(token, _imageFile!);
      if (updatedUser != null) {
        setState(() {
          _currentUser = updatedUser;
          _isUploading = false;
          _imageFile = null;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context)!.profilePictureUploadedSuccessfully)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.failedToUploadProfilePicture}: $e')),
        );
      }
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _handleLogout() async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmLogout),
        content: Text(l10n.areYouSureLogout),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService =
                  ctxProvider.Provider.of<AuthService>(context, listen: false);
              await authService.logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  RoleSelectionScreen.routeName,
                  (route) => false,
                );
              }
            },
            child: Text(l10n.logout, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountConfirmation),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.deleteAccountWarning,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final authService =
          ctxProvider.Provider.of<AuthService>(context, listen: false);
      
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text(AppLocalizations.of(context)!.deletingAccount),
              ],
            ),
          ),
        );
      }
      
      await authService.deleteAccount();
      
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountDeleted),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to role selection screen
        Navigator.of(context).pushNamedAndRemoveUntil(
          RoleSelectionScreen.routeName,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog if it's open
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.failedToDeleteAccount}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildProfileInfo(User user) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          user.fullName ?? AppLocalizations.of(context)!.user,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          user.email ?? '',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        Text(
          user.phoneNumber ?? AppLocalizations.of(context)!.noPhoneNumber,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEditableProfileInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.fullName,
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterYourFullName,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterYourName;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.phoneNumber,
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.enterYourPhoneNumber,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      // Reset controllers to current values
                      if (_currentUser != null) {
                        _initializeControllers(_currentUser!);
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    final themeService = ctxProvider.Provider.of<ThemeService>(context);

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.accountSettings,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              AppLocalizations.of(context)!.pushNotifications,
              themeService.notificationsEnabled,
              (value) {
                themeService.toggleNotifications(value);
              },
            ),
            const Divider(),
            _buildSettingItem(
              AppLocalizations.of(context)!.darkMode,
              themeService.darkModeEnabled,
              (value) {
                themeService.toggleDarkMode(value);
              },
            ),
            const Divider(),
            _buildSettingItem(
              AppLocalizations.of(context)!.locationServices,
              themeService.locationServicesEnabled,
              (value) {
                themeService.toggleLocationServices(value);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.logout,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleDeleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.deleteAccount,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
                  title: Text(l10n.userProfile),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.translate),
            onPressed: () async {
              final localeService = ctxProvider.Provider.of<LocaleService>(context, listen: false);
              await localeService.toggleLocale();
              // Show a snackbar to confirm language change
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      localeService.currentLocale.languageCode == 'ar'
                          ? 'تم تغيير اللغة إلى العربية'
                          : 'Language changed to English',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<User?>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('${AppLocalizations.of(context)!.errorLoadingProfile}: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(AppLocalizations.of(context)!.couldNotLoadProfile));
          }

          final user = snapshot.data!;
          if (!_isEditing && _currentUser != user) {
            _currentUser = user;
            _initializeControllers(user);
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Profile Image Section
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!) as ImageProvider<Object>
                              : (user.profilePictureUrl != null &&
                                      user.profilePictureUrl!.isNotEmpty &&
                                      user.profilePictureUrl!.startsWith('http')
                                  ? NetworkImage(user.profilePictureUrl!)
                                  : const AssetImage('assets/default_user.png')) as ImageProvider<Object>,
                          child: _isUploading
                              ? const CircularProgressIndicator()
                              : ((_imageFile == null &&
                                      (user.profilePictureUrl == null ||
                                          user.profilePictureUrl!.isEmpty))
                                  ? const Icon(Icons.person, size: 60)
                                  : null),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            radius: 20,
                            child: IconButton(
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 20),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Profile Information or Edit Form
                _isEditing
                    ? _buildEditableProfileInfo()
                    : _buildProfileInfo(user),

                // Settings Section
                _buildSettingsSection(),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
