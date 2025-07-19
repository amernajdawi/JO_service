import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart'
    as ctxProvider; // Aliased provider import
import 'package:image_picker/image_picker.dart';
import '../models/provider_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart'; // For AuthService type and its methods

class EditProviderProfileScreen extends StatefulWidget {
  const EditProviderProfileScreen({super.key});

  @override
  State<EditProviderProfileScreen> createState() =>
      _EditProviderProfileScreenState();
}

class _EditProviderProfileScreenState extends State<EditProviderProfileScreen> {
  final ApiService _apiService = ApiService();
  Future<Provider?>? _providerProfileFuture;
  Provider? _currentProvider; // Store the current provider data
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isUploading = false;

  bool _isEditing = false; // To toggle edit mode
  final _formKey = GlobalKey<FormState>(); // For form validation

  // TextEditingControllers for editable fields
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _serviceDescriptionController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _addressTextController = TextEditingController();
  final _phoneController = TextEditingController();
  final _availabilityDetailsController = TextEditingController();
  final _profilePictureUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // It's good practice to ensure context is available for Provider.of
    // and to handle async operations safely within initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if mounted before accessing context dependent things
        _loadProfile();
      }
    });
  }

  void _loadProfile() async {
    // Get AuthService from Provider
    final authService = ctxProvider.Provider.of<AuthService>(context,
        listen: false); // Use alias
    final token = await authService.getToken();

    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication token not found. Please log in.')),
        );
        // Consider popping or redirecting more robustly
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop();
        } else {
          // If cannot pop (e.g. it's the first screen after some error),
          // navigate to a safe place like RoleSelectionScreen.
          // This depends on how EditProviderProfileScreen can be reached.
          // For now, we assume it can be popped.
        }
      }
      // Set future to an error if token is missing to ensure FutureBuilder shows error
      setState(() {
        _providerProfileFuture =
            Future.error(Exception('Authentication token not found.'));
      });
      return;
    }
    setState(() {
      _providerProfileFuture =
          _apiService.getMyProviderProfile(token).then((provider) {
        if (provider != null) {
          _currentProvider = provider; // Store loaded provider data
          _initializeControllers(provider); // Initialize controllers
        }
        return provider;
      });
    });
  }

  void _initializeControllers(Provider provider) {
    _fullNameController.text = provider.fullName ?? '';
    _companyNameController.text = provider.companyName ?? '';
    _serviceTypeController.text = provider.serviceType ?? '';
    _serviceDescriptionController.text = provider.serviceDescription ?? '';
    _hourlyRateController.text = provider.hourlyRate?.toString() ?? '';
    _addressTextController.text = provider.location?.addressText ?? '';
    _phoneController.text = provider.contactInfo?.phone ?? '';
    _availabilityDetailsController.text = provider.availabilityDetails ?? '';
    _profilePictureUrlController.text = provider.profilePictureUrl ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _serviceTypeController.dispose();
    _serviceDescriptionController.dispose();
    _hourlyRateController.dispose();
    _addressTextController.dispose();
    _phoneController.dispose();
    _availabilityDetailsController.dispose();
    _profilePictureUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    print('[DEBUG] _saveProfile called'); // 1. Check if called
    if (_formKey.currentState?.validate() ?? false) {
      final authService =
          ctxProvider.Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      print('[DEBUG] Token: $token'); // 2. Check token
      print(
          '[DEBUG] Current Provider ID: ${_currentProvider?.id}'); // 2. Check current provider

      if (token == null || token.isEmpty || _currentProvider == null) {
        print('[DEBUG] Token or currentProvider is null/empty. Aborting save.');
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
        'companyName': _companyNameController.text,
        'serviceType': _serviceTypeController.text,
        'serviceDescription': _serviceDescriptionController.text,
        'hourlyRate': double.tryParse(_hourlyRateController.text),
        'location': {'addressText': _addressTextController.text},
        'contactInfo': {'phone': _phoneController.text},
        'availabilityDetails': _availabilityDetailsController.text,
        'profilePictureUrl': _profilePictureUrlController.text,
      };
      print(
          '[DEBUG] UpdatedData being sent: $updatedData'); // 3. Check data being sent

      try {
        print('[DEBUG] Calling _apiService.updateMyProviderProfile...');
        final updatedProvider =
            await _apiService.updateMyProviderProfile(token, updatedData);
        print(
            '[DEBUG Client] Received updatedProvider object from API: ${updatedProvider.toJson()}');
        print(
            '[DEBUG] Profile updated successfully on API. Response: $updatedProvider');

        setState(() {
          print('[DEBUG] setState called after successful save.');
          _currentProvider = updatedProvider;
          _initializeControllers(updatedProvider);
          _isEditing = false;
          _providerProfileFuture = Future.value(updatedProvider);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        print('[DEBUG] Error saving profile: $e'); // 5. Check for errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: $e')),
          );
        }
      }
    } else {
      print('[DEBUG] Form validation failed.');
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

      final updatedProvider =
          await _apiService.uploadProfilePicture(token, _imageFile!);
      if (updatedProvider != null) {
        setState(() {
          _currentProvider = updatedProvider;
          _profilePictureUrlController.text =
              updatedProvider.profilePictureUrl ?? '';
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
      print('Error uploading profile picture: $e');
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

  Widget _buildProfileDetail(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$title: ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
              child:
                  Text(value ?? 'N/A', style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildEditableProfileDetail(
      String title, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text,
      bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: title,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        validator: (value) {
          if (isNumeric) {
            // Only proceed if numeric validation is needed
            if (value == null || value.isEmpty) {
              // If numeric is expected, an empty value might be invalid or valid depending on requirements.
              // For now, let's assume an empty value is fine if not mandatory.
              // If it should be mandatory and numeric, add: return 'This field requires a number';
            } else {
              // At this point, value is not null and not empty.
              if (double.tryParse(value) == null) {
                // 'value' is now safe to pass directly
                return 'Please enter a valid number';
              }
            }
          }
          // Add other non-numeric validations here if needed, e.g. for 'Full Name'
          // if (title == 'Full Name' && (value == null || value.isEmpty)) {
          //   return 'Full Name cannot be empty';
          // }
          return null; // No errors
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(_isEditing ? 'Edit Provider Profile' : 'My Provider Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? 'Save Profile' : 'Edit Profile',
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() {
                  _isEditing = true;
                  // Ensure controllers are initialized if _currentProvider exists
                  if (_currentProvider != null) {
                    _initializeControllers(_currentProvider!);
                  }
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Provider?>(
        future: _providerProfileFuture,
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
            return const Center(
                child: Text('Could not load provider profile.'));
          }

          final provider = snapshot.data!;
          // If not editing, ensure controllers are synced if they haven't been or data changed.
          // This might be redundant if _loadProfile always sets _currentProvider and calls _initializeControllers
          // but serves as a safeguard.
          if (!_isEditing && _currentProvider != provider) {
            _currentProvider = provider;
            _initializeControllers(provider);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              // Wrap content in a Form
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_isEditing
                                  ? (_profilePictureUrlController
                                          .text.isNotEmpty
                                      ? NetworkImage(
                                              _profilePictureUrlController.text)
                                          as ImageProvider<Object>
                                      : null)
                                  : (provider.profilePictureUrl != null &&
                                          provider.profilePictureUrl!.isNotEmpty
                                      ? NetworkImage(
                                              provider.profilePictureUrl!)
                                          as ImageProvider<Object>
                                      : null)),
                          child: _isUploading
                              ? const CircularProgressIndicator()
                              : (_imageFile == null &&
                                      (_isEditing
                                          ? _profilePictureUrlController
                                              .text.isEmpty
                                          : (provider.profilePictureUrl ==
                                                  null ||
                                              provider
                                                  .profilePictureUrl!.isEmpty))
                                  ? const Icon(Icons.person, size: 50)
                                  : null),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: _pickImage,
                            color: Theme.of(context).primaryColor,
                            tooltip: 'Pick Image',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_isEditing) ...[
                    _buildEditableProfileDetail(
                        'Full Name', _fullNameController),
                    _buildEditableProfileDetail(
                        'Company Name', _companyNameController),
                    _buildEditableProfileDetail(
                        'Service Type', _serviceTypeController),
                    _buildEditableProfileDetail(
                        'Service Description', _serviceDescriptionController,
                        keyboardType: TextInputType.multiline),
                    _buildEditableProfileDetail(
                        'Hourly Rate', _hourlyRateController,
                        keyboardType: TextInputType.number, isNumeric: true),
                    _buildEditableProfileDetail(
                        'Address', _addressTextController),
                    _buildEditableProfileDetail('Phone', _phoneController,
                        keyboardType: TextInputType.phone),
                    _buildEditableProfileDetail(
                        'Availability Details', _availabilityDetailsController),
                    _buildEditableProfileDetail(
                        'Profile Picture URL', _profilePictureUrlController,
                        keyboardType: TextInputType.url),
                  ] else ...[
                    _buildProfileDetail(
                        'Full Name', provider.fullName ?? provider.companyName),
                    _buildProfileDetail(
                        'Email', provider.email), // Email is not editable here
                    _buildProfileDetail('Company Name', provider.companyName),
                    _buildProfileDetail('Service Type', provider.serviceType),
                    _buildProfileDetail(
                        'Service Description', provider.serviceDescription),
                    _buildProfileDetail(
                        'Address', provider.location?.addressText),
                    _buildProfileDetail('Phone', provider.contactInfo?.phone),
                    _buildProfileDetail(
                        'Hourly Rate', provider.hourlyRate?.toString()),
                    _buildProfileDetail(
                        'Availability', provider.availabilityDetails),
                    _buildProfileDetail('Profile Picture URL',
                        provider.profilePictureUrl), // Displaying as text
                    _buildProfileDetail(
                        'Average Rating', provider.averageRating?.toString()),
                  ]
                  // Add more fields as needed
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
