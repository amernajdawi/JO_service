import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart' as ctxProvider;
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
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
          const SnackBar(
              content: Text('Authentication token not found. Please log in.')),
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
            const SnackBar(
                content: Text('Authentication error. Cannot save profile.')),
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
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    }
  }

  // Add method to pick image from gallery
  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Image upload is not supported in web mode. Please use the mobile app.')),
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
          SnackBar(content: Text('Error picking image: $e')),
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
            const SnackBar(
                content: Text('Authentication error. Cannot upload image.')),
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
            const SnackBar(
                content: Text('Profile picture uploaded successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload profile picture: $e')),
        );
      }
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo(User user) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          user.fullName ?? 'User',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          user.email ?? '',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        Text(
          user.phoneNumber ?? 'No phone number',
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
            const Text('Full Name',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(
                hintText: 'Enter your full name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            const Text('Phone Number',
                style: TextStyle(fontWeight: FontWeight.bold)),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                hintText: 'Enter your phone number',
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
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save'),
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
            const Text(
              'Account Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSettingItem(
              'Push Notifications',
              themeService.notificationsEnabled,
              (value) {
                themeService.toggleNotifications(value);
              },
            ),
            const Divider(),
            _buildSettingItem(
              'Dark Mode',
              themeService.darkModeEnabled,
              (value) {
                themeService.toggleDarkMode(value);
              },
            ),
            const Divider(),
            _buildSettingItem(
              'Location Services',
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
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontSize: 16),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
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
                child: Text('Error loading profile: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Could not load user profile.'));
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
                                      user.profilePictureUrl!.isNotEmpty
                                  ? NetworkImage(user.profilePictureUrl!)
                                      as ImageProvider<Object>
                                  : const AssetImage('assets/default_user.png')
                                      as ImageProvider<Object>),
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
