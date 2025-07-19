import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../widgets/animated_button.dart';
import '../widgets/animated_input.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('User Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Create your Account',
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
                label: 'Phone Number (Optional)',
                placeholder: 'Enter your phone number',
                value: _phoneNumberController.text,
                onChanged: (value) => _phoneNumberController.text = value,
                keyboardType: TextInputType.phone,
                icon: const Icon(Icons.phone, color: AppTheme.grey),
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
                      title: 'Sign Up',
                      onPressed: _submitForm,
                      fullWidth: true,
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed(UserLoginScreen.routeName);
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
