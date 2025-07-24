import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../widgets/uber_input.dart'; // Use the new UberInput widget
import './user_login_screen.dart';
import './user_home_screen.dart';

class UserSignUpScreen extends StatefulWidget {
  static const routeName = '/user-signup';

  const UserSignUpScreen({super.key});

  @override
  State<UserSignUpScreen> createState() => _UserSignUpScreenState();
}

class _UserSignUpScreenState extends State<UserSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

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

  String? _validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.length < 2) {
      return 'Full name must be at least 2 characters';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 10) {
      return 'Enter a valid phone number';
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
        await authService.registerUser(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
          phoneNumber: _phoneNumberController.text,
        );
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pushReplacementNamed(UserHomeScreen.routeName);
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
    _phoneNumberController.dispose();
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
            // Navigate back to user login screen
            Navigator.of(context).pushReplacementNamed('/user-login');
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
                  'Create account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF000000),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join us and start booking services',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Full Name Input
                UberInput(
                  label: 'Full name',
                  hint: 'Enter your full name',
                  controller: _fullNameController,
                  validator: _validateFullName,
                ),
                
                const SizedBox(height: 20),
                
                // Email Input
                UberInput(
                  label: 'Email address',
                  hint: 'Enter your email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),
                
                const SizedBox(height: 20),

                // Phone Number Input
                UberInput(
                  label: 'Phone number',
                  hint: 'Enter your phone number',
                  controller: _phoneNumberController,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhoneNumber,
                ),
                
                const SizedBox(height: 20),
                
                // Password Input
                UberInput(
                  label: 'Password',
                  hint: 'Enter your password',
                  controller: _passwordController,
                  obscureText: true,
                  validator: _validatePassword,
                ),
                
                const SizedBox(height: 20),
                
                // Confirm Password Input
                UberInput(
                  label: 'Confirm password',
                  hint: 'Confirm your password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  validator: _validateConfirmPassword,
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
                            'Create account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Sign In Link
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context)
                          .pushReplacementNamed(UserLoginScreen.routeName);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF000000),
                    ),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF6B7280),
                        ),
                        children: [
                          const TextSpan(text: "Already have an account? "),
                          TextSpan(
                            text: 'Sign in',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF000000),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
