import 'package:flutter/material.dart';
import '../constants/theme.dart';
import '../widgets/animated_button.dart';
import './user_login_screen.dart';
import './provider_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  static const routeName = '/role-selection';

  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome!'),
        automaticallyImplyLeading: false, // No back button
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
            ],
          ),
        ),
      ),
    );
  }
}
