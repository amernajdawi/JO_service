import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../widgets/animated_button.dart';
import '../widgets/animated_input.dart';
import '../widgets/language_selector.dart';
import '../widgets/lottie_loader.dart';
import './role_selection_screen.dart';
import './user_signup_screen.dart';
import './user_home_screen.dart';

class UserLoginScreen extends StatefulWidget {
  static const routeName = '/user-login'; // Added routeName

  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.emailRequired;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return l10n.enterValidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return l10n.passwordRequired;
    }
    if (value.length < 6) {
      return l10n.passwordMinLength;
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        
        // Check if it's a provider email
        if (email.endsWith('@joprovider.com')) {
          // Provider login flow
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.loginProvider(email: email, password: password);
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/provider-dashboard');
          }
        } else {
          // Regular user login flow
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.loginUser(email: email, password: password);
          
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(UserHomeScreen.routeName);
          }
        }
        
        setState(() {
          _isLoading = false;
        });
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
    final l10n = AppLocalizations.of(context)!;
    final localeService = Provider.of<LocaleService>(context);
    
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.login),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context)
                    .pushReplacementNamed(RoleSelectionScreen.routeName);
              },
            ),
            actions: [
              // Language toggle in app bar
              const LanguageToggleButton(
                margin: EdgeInsets.only(right: 8),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    const SizedBox(height: 40),
                    
                    // Welcome text
                    Text(
                      l10n.signInToAccount,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                                         // Email field
                     TextFormField(
                       controller: _emailController,
                       keyboardType: TextInputType.emailAddress,
                       decoration: InputDecoration(
                         labelText: l10n.email,
                         prefixIcon: const Icon(Icons.email_outlined),
                         border: const OutlineInputBorder(),
                       ),
                       validator: _validateEmail,
                     ),
                     
                     const SizedBox(height: 20),
                     
                     // Password field
                     TextFormField(
                       controller: _passwordController,
                       obscureText: _obscurePassword,
                       decoration: InputDecoration(
                         labelText: l10n.password,
                         prefixIcon: const Icon(Icons.lock_outlined),
                         suffixIcon: IconButton(
                           icon: Icon(
                             _obscurePassword ? Icons.visibility : Icons.visibility_off,
                           ),
                           onPressed: () {
                             setState(() {
                               _obscurePassword = !_obscurePassword;
                             });
                           },
                         ),
                         border: const OutlineInputBorder(),
                       ),
                       validator: _validatePassword,
                     ),
                    
                    const SizedBox(height: 12),
                    
                    // Forgot password
                    Align(
                      alignment: localeService.isRTL 
                          ? Alignment.centerLeft 
                          : Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Handle forgot password
                        },
                        child: Text(l10n.forgotPassword),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Error message display
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(l10n.login),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.dontHaveAccount),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushReplacementNamed(UserSignUpScreen.routeName);
                          },
                          child: Text(l10n.signup),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 40),
                    

                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
