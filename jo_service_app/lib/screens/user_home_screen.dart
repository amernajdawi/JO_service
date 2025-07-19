import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import './role_selection_screen.dart';
import './provider_list_screen.dart';
import './user_profile_screen.dart';
import './user_bookings_screen.dart';
import './favorites_screen.dart';
import './provider_detail_screen.dart';
import 'package:provider/provider.dart';

class UserHomeScreen extends StatefulWidget {
  static const routeName = '/user-home';

  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final List<Map<String, dynamic>> _serviceCategories = [
    {
      'name': 'Painter',
      'icon': Icons.format_paint,
      'color': Colors.orange.shade200,
    },
    {
      'name': 'Electrician',
      'icon': Icons.electrical_services,
      'color': Colors.blue.shade200,
    },
    {
      'name': 'TV Repair',
      'icon': Icons.tv,
      'color': Colors.purple.shade200,
    },
    {
      'name': 'AC Repair',
      'icon': Icons.ac_unit,
      'color': Colors.teal.shade200,
    },
    {
      'name': 'Plumber',
      'icon': Icons.plumbing,
      'color': Colors.red.shade200,
    },
    {
      'name': 'Cleaning',
      'icon': Icons.cleaning_services,
      'color': Colors.green.shade200,
    },
    {
      'name': 'Gardening',
      'icon': Icons.yard,
      'color': Colors.amber.shade200,
    },
    {
      'name': 'Carpentry',
      'icon': Icons.handyman,
      'color': Colors.brown.shade200,
    },
  ];

  // Update location to use Jordanian cities
  String _selectedLocation = 'Amman';

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

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location and Cart Header
              _buildHeader(),

              // Featured Service Card (Banner)
              _buildFeaturedServiceBanner(),

              // Service Categories Grid
              _buildServiceCategoriesGrid(),

              const SizedBox(height: 80), // Bottom padding for navigation bar
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location Selector
          Row(
            children: [
              Icon(Icons.location_on, size: 20, color: Colors.black),
              const SizedBox(width: 4),
              Text('Select City',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedLocation,
                icon: const Icon(Icons.keyboard_arrow_down),
                elevation: 16,
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
                underline: Container(height: 0),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLocation = newValue!;
                  });
                },
                items:
                    _jordanCities.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),

          // Cart/Notifications Icon
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              // Navigate to cart or notifications
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedServiceBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Logo or Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.home_work, color: Colors.orange),
                ),
                const SizedBox(width: 12),
                // Text
                Text(
                  'JOSERVICE\nHome Maintenance Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCategoriesGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _serviceCategories.length,
      itemBuilder: (context, index) {
        final category = _serviceCategories[index];
        return GestureDetector(
          onTap: () {
            // Show location confirmation dialog before proceeding
            _showLocationConfirmationDialog(category['name']);
          },
          child: Column(
            children: [
              // Icon Circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    category['icon'],
                    color: category['color'],
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Category Name
              Text(
                category['name'],
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLocationConfirmationDialog(String categoryName) {
    final TextEditingController addressController = TextEditingController();
    addressController.text = _selectedLocation; // Pre-fill with selected city

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Your Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Please confirm or update your location for $categoryName service',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      value: _selectedLocation,
                      items: _jordanCities.map((String city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLocation = newValue;
                          });
                          addressController.text = newValue;
                        }
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: InputDecoration(
                  labelText: 'Detailed Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Street, building, etc.',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'A detailed address helps service providers locate you easily',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Update the selected location if user changed it
                setState(() {
                  _selectedLocation =
                      addressController.text.split(',').first.trim();
                });

                // Close dialog
                Navigator.of(context).pop();

                // Navigate to provider list with the category and location filter
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProviderListScreen(
                      initialSearch: 'Category: $categoryName',
                      initialLocation: _selectedLocation,
                    ),
                  ),
                );
              },
              child: Text('Confirm & Continue'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'Categories',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_border),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });

        if (index != 0) {
          // If not home
          switch (index) {
            case 1: // Bookings
              Navigator.of(context).pushNamed(UserBookingsScreen.routeName);
              break;
            case 2: // Categories
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProviderListScreen(),
                ),
              );
              break;
            case 3: // Favorites
              // Use the global favorites set from provider_detail_screen.dart
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(
                    favoriteProviderIds: favoriteProviders,
                  ),
                ),
              );
              break;
            case 4: // More/Profile
              Navigator.of(context).pushNamed(UserProfileScreen.routeName);
              break;
          }

          // Reset selection to home after navigation
          setState(() {
            _selectedIndex = 0;
          });
        }
      },
    );
  }
}
