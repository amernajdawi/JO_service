import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/theme.dart';
import '../widgets/animated_button.dart';
import './user_login_screen.dart';
import './provider_login_screen.dart';
import './admin_login_screen.dart'; // Add admin login import

class RoleSelectionScreen extends StatelessWidget {
  static const routeName = '/role-selection';

  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Show exit confirmation dialog
        final bool shouldExit = await _showExitConfirmation(context);
        return shouldExit;
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
        automaticallyImplyLeading: false, // No back button
        actions: [
          // Admin access button in top right
          IconButton(
            icon: Icon(
              Icons.admin_panel_settings,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : const Color(0xFF000000),
            ),
            onPressed: () {
              Navigator.of(context)
                  .pushReplacementNamed(AdminLoginScreen.routeName);
            },
            tooltip: 'Admin Access',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'How would you like to continue?',
                style: AppTheme.h2.copyWith(color: AppTheme.dark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              AnimatedButton(
                title: 'I am a User',
                fullWidth: true,
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed(UserLoginScreen.routeName);
                },
              ),
              const SizedBox(height: 20),
              AnimatedButton(
                title: 'I am a Service Provider',
                variant: 'outlined',
                fullWidth: true,
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed(ProviderLoginScreen.routeName);
                },
              ),
              
              const SizedBox(height: 32),
              
              // Admin access info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: const Color(0xFF007AFF),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin? Tap the admin icon above to access the management portal',
                        style: TextStyle(
                          color: const Color(0xFF007AFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ), // Close Scaffold
  ); // Close WillPopScope
}

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Exit App',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            'Are you sure you want to exit the app?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                SystemNavigator.pop(); // Exit the app
              },
              child: const Text(
                'Exit',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }
}
