import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../widgets/animated_button.dart';
import '../widgets/animated_input.dart';
import './provider_login_screen.dart';
import './provider_dashboard_screen.dart';

class ProviderSignUpScreen extends StatefulWidget {
  static const routeName = '/provider-signup';

  const ProviderSignUpScreen({super.key});

  @override
  State<ProviderSignUpScreen> createState() => _ProviderSignUpScreenState();
}

class _ProviderSignUpScreenState extends State<ProviderSignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _serviceTypeController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _addressController = TextEditingController();

  // Selected city
  String _selectedCity = 'Amman';

  // List of Jordanian cities
  final List<String> _jordanCities = [
    'Amman',
    'Irbid',
    'Zarqa',
    'Mafraq',
    'Ajloun',
    'Jerash',
    'Madaba',
    'Balqa',
    'Karak',
    'Tafileh',
    'Maan',
    'Aqaba',
  ];

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Passwords do not match.';
          _isLoading = false;
        });
        return;
      }

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
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Create your Provider Account',
                style: AppTheme.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              AnimatedInput(
                label: 'Full Name',
                placeholder: 'Enter your full name',
                value: _fullNameController.text,
                onChanged: (value) => _fullNameController.text = value,
                icon: const Icon(Icons.person, color: AppTheme.grey),
                iconPosition: 'left',
              ),
              const SizedBox(height: 15),
              AnimatedInput(
                label: 'Company Name (Optional)',
                placeholder: 'Enter your company name',
                value: _companyNameController.text,
                onChanged: (value) => _companyNameController.text = value,
                icon: const Icon(Icons.business, color: AppTheme.grey),
                iconPosition: 'left',
              ),
              const SizedBox(height: 15),
              AnimatedInput(
                label: 'Email Address',
                placeholder: 'Enter your email',
                value: _emailController.text,
                onChanged: (value) => _emailController.text = value,
                keyboardType: TextInputType.emailAddress,
                icon: const Icon(Icons.email, color: AppTheme.grey),
                iconPosition: 'left',
              ),
              const SizedBox(height: 15),
              AnimatedInput(
                label: 'Password',
                placeholder: 'Enter your password',
                value: _passwordController.text,
                onChanged: (value) => _passwordController.text = value,
                obscureText: true,
                icon: const Icon(Icons.lock, color: AppTheme.grey),
                iconPosition: 'left',
              ),
              const SizedBox(height: 15),
              AnimatedInput(
                label: 'Confirm Password',
                placeholder: 'Confirm your password',
                value: _confirmPasswordController.text,
                onChanged: (value) => _confirmPasswordController.text = value,
                obscureText: true,
                icon: const Icon(Icons.lock_outline, color: AppTheme.grey),
                iconPosition: 'left',
              ),
              const SizedBox(height: 15),
              AnimatedInput(
                label: 'Service Type',
                placeholder: 'e.g., Plumber, Electrician',
                value: _serviceTypeController.text,
                onChanged: (value) => _serviceTypeController.text = value,
                icon: const Icon(Icons.handyman, color: AppTheme.grey),
                iconPosition: 'left',
              ),
              const SizedBox(height: 15),
              AnimatedInput(
                label: 'Hourly Rate (\$)',
                placeholder: 'Enter your hourly rate',
                value: _hourlyRateController.text,
                onChanged: (value) => _hourlyRateController.text = value,
                keyboardType: TextInputType.number,
                icon: const Icon(Icons.attach_money, color: AppTheme.grey),
                iconPosition: 'left',
              ),
              const SizedBox(height: 15),
              // City selection dropdown
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(color: AppTheme.greyLight),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.location_city, color: AppTheme.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCity,
                          icon: const Icon(Icons.arrow_drop_down),
                          elevation: 16,
                          style: AppTheme.body3,
                          isExpanded: true,
                          hint: Text('Select City',
                              style: TextStyle(color: AppTheme.grey)),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCity = newValue;
                              });
                            }
                          },
                          items: _jordanCities
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              AnimatedInput(
                label: 'Detailed Address',
                placeholder: 'Street, building, etc.',
                value: _addressController.text,
                onChanged: (value) => _addressController.text = value,
                icon: const Icon(Icons.location_on, color: AppTheme.grey),
                iconPosition: 'left',
                maxLines: 2,
              ),
              const SizedBox(height: 30),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppTheme.danger, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                      ),
                    )
                  : AnimatedButton(
                      title: 'Sign Up as Provider',
                      onPressed: _submitForm,
                      fullWidth: true,
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed(ProviderLoginScreen.routeName);
                },
                child: Text(
                  'Already have an account? Login',
                  style: TextStyle(color: AppTheme.primary),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
