import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import './role_selection_screen.dart'; // For logout
// Import ProviderListScreen if users should be able to browse providers from their home
import './provider_list_screen.dart';
import 'package:provider/provider.dart';

class UserHomeScreen extends StatelessWidget {
  static const routeName = '/user-home';

  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final AuthService authService = AuthService(); // DO NOT create a new instance here
    final authService =
        Provider.of<AuthService>(context, listen: false); // Use Provider

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authService.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const RoleSelectionScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Welcome, User!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ProviderListScreen()),
                );
              },
              child: const Text('Browse Service Providers'),
            ),
            // TODO: Add other user-specific actions/dashboard items
          ],
        ),
      ),
    );
  }
}
