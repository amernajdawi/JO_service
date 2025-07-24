import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../widgets/uber_input.dart'; // Use the new UberInput widget
import './provider_dashboard_screen.dart';

class ProviderSignUpScreen extends StatefulWidget {
  static const routeName = '/provider-signup';

  const ProviderSignUpScreen({super.key});

  @override
  State<ProviderSignUpScreen> createState() => _ProviderSignUpScreenState();
}

class _ProviderSignUpScreenState extends State<ProviderSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  String _selectedCity = 'Amman'; // Default city
  final List<String> _cities = [
    'Amman',
    'Zarqa',
    'Irbid',
    'Aqaba',
    'Salt',
    'Madaba',
    'Jerash',
    'Ajloun',
    'Karak',
    'Tafilah',
    'Maan',
    'Mafraq'
  ];

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateHourlyRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Hourly rate is required';
    }
    final rate = double.tryParse(value);
    if (rate == null || rate <= 0) {
      return 'Enter a valid hourly rate';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        // Create address text with city and detailed address
        final String fullAddress = _addressController.text.isNotEmpty
            ? '$_selectedCity, ${_addressController.text}'
            : _selectedCity;

        // IMPORTANT: Pass all required fields to registerProvider
        await authService.registerProvider(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          companyName: _companyNameController.text,
          serviceType: _serviceTypeController.text,
          hourlyRate: _hourlyRateController.text,
          city: _selectedCity,
          addressText: fullAddress,
        );
        setState(() {
          _isLoading = false;
        });
        // Navigate to dashboard screen after successful registration
        Navigator.of(context)
            .pushReplacementNamed(ProviderDashboardScreen.routeName);
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _companyNameController.dispose();
    _serviceTypeController.dispose();
    _hourlyRateController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? Colors.white : const Color(0xFF000000),
            size: 20,
          ),
          onPressed: () {
            // Navigate back to provider login screen
            Navigator.of(context).pushReplacementNamed('/provider-login');
          },
        ),
        title: null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 20),
                
                // Main Title
                Text(
                  'Join as provider',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start offering your services today',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Personal Information Section
                Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 16),
                
                UberInput(
                  label: 'Full name',
                  hint: 'Enter your full name',
                  controller: _fullNameController,
                  validator: (value) => _validateRequired(value, 'Full name'),
                ),
                
                const SizedBox(height: 16),
                
                UberInput(
                  label: 'Email address',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                
                const SizedBox(height: 16),
                
                UberInput(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: _validatePassword,
                ),
                
                const SizedBox(height: 16),
                
                UberInput(
                  label: 'Confirm password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: _validateConfirmPassword,
                ),
                
                const SizedBox(height: 24),
                
                // Business Information Section
                Text(
                  'Business Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                  ),
                ),
                const SizedBox(height: 16),
                
                UberInput(
                  label: 'Company name',
                  hint: 'Enter your company name',
                  controller: _companyNameController,
                  validator: (value) => _validateRequired(value, 'Company name'),
                ),
                
                const SizedBox(height: 16),
                
                UberInput(
                  label: 'Service type',
                  hint: 'e.g., Plumbing, Electrical, Cleaning',
                  controller: _serviceTypeController,
                  validator: (value) => _validateRequired(value, 'Service type'),
                ),
                
                const SizedBox(height: 16),
                
                UberInput(
                  label: 'Hourly rate (JOD)',
                  hint: 'Enter your hourly rate',
                  controller: _hourlyRateController,
                  keyboardType: TextInputType.number,
                  validator: _validateHourlyRate,
                ),
                
                const SizedBox(height: 16),
                
                // City Dropdown
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'City',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : const Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white : const Color(0xFF000000),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                        items: _cities.map((String city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCity = newValue!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                UberInput(
                  label: 'Address',
                  hint: 'Enter your detailed address',
                  controller: _addressController,
                  maxLines: 2,
                ),
                
                const SizedBox(height: 32),
                
                // Error Message
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFFF3B30).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: const Color(0xFFFF3B30),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFFF3B30),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Sign Up Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : const Color(0xFF000000),
                      foregroundColor: isDark ? const Color(0xFF000000) : Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: isDark 
                          ? const Color(0xFF38383A) 
                          : const Color(0xFFF3F4F6),
                      disabledForegroundColor: isDark 
                          ? const Color(0xFF8E8E93) 
                          : const Color(0xFF9CA3AF),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? const Color(0xFF000000) : Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Create provider account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
