import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import '../widgets/animated_button.dart';
import '../widgets/animated_input.dart';
import './user_home_screen.dart'; // Navigate to UserHomeScreen
import './user_signup_screen.dart'; // To navigate to signup
import 'package:provider/provider.dart';

class UserLoginScreen extends StatefulWidget {
  static const routeName = '/user-login'; // Added routeName

  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  // final _authService = AuthService(); // DO NOT create a new instance here
  // AuthService will be obtained via Provider in _submitForm

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService =
          Provider.of<AuthService>(context, listen: false); // Use Provider
      try {
        await authService.loginUser(
          email: _emailController.text,
          password: _passwordController.text,
        );
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context)
            .pushReplacementNamed(UserHomeScreen.routeName); // Use named route
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 20),
              Text(
                'Welcome Back!',
                style: AppTheme.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
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
                      title: 'Login',
                      onPressed: _submitForm,
                      fullWidth: true,
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed(UserSignUpScreen.routeName);
                },
                child: Text(
                  'Don\'t have an account? Sign Up',
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
