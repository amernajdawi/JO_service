import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import './role_selection_screen.dart'; // For logout
import './provider_list_screen.dart'; // For viewing all providers (can be their own profile later)
import './edit_provider_profile_screen.dart'; // Import the new screen
import './provider_bookings_screen.dart'; // Import ProviderBookingsScreen
import 'package:provider/provider.dart';

class ProviderDashboardScreen extends StatelessWidget {
  static const routeName = '/provider-dashboard'; // Added routeName

  const ProviderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // final AuthService authService = AuthService(); // DO NOT create a new instance here
    final authService =
        Provider.of<AuthService>(context, listen: false); // Use Provider

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
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
              'Welcome, Provider!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const EditProviderProfileScreen()),
                );
              },
              child: const Text('Manage My Profile'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ProviderListScreen()),
                );
              },
              child: const Text('View All Providers'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamed(ProviderBookingsScreen.routeName);
              },
              child: const Text('Manage Bookings'),
            ),
            // TODO: Add other provider-specific actions/dashboard items
            // (e.g., view my services, manage bookings)
          ],
        ),
      ),
    );
  }
}
