import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as ctxProvider;
import '../models/provider_model.dart';
import '../constants/theme.dart';
import 'provider_list_screen.dart';
import 'user_bookings_screen.dart';
import 'user_profile_screen.dart';
import 'favorites_screen.dart';
import 'user_chats_screen.dart';
import 'provider_detail_screen.dart'; // Import to access favoriteProviders

class UserHomeScreen extends StatefulWidget {
  static const routeName = '/user-home';
  
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  late Future<List<Provider>> _providersFuture;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _providersFuture = _getMockProviders();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<List<Provider>> _getMockProviders() async {
    // Mock data for demonstration
    await Future.delayed(const Duration(seconds: 1));
    return [
      Provider(
        id: '1',
        fullName: 'Ahmed Al-Zahra',
        serviceType: 'Electrician',
        email: 'ahmed@example.com',
        companyName: 'Ahmed Electrical Services',
        serviceDescription: 'Professional electrical services for homes and businesses',
        hourlyRate: 25.0,
        location: ProviderLocation(
          addressText: 'Amman, Jordan',
          city: 'Amman',
        ),
        contactInfo: ProviderContactInfo(
          phone: '+962791234567',
        ),
        averageRating: 4.5,
        totalRatings: 25,
      ),
      Provider(
        id: '2',
        fullName: 'Fatima Hassan',
        serviceType: 'Plumber',
        email: 'fatima@example.com',
        companyName: 'Fatima Plumbing Co.',
        serviceDescription: 'Expert plumbing and water system services',
        hourlyRate: 30.0,
        location: ProviderLocation(
          addressText: 'Irbid, Jordan',
          city: 'Irbid',
        ),
        contactInfo: ProviderContactInfo(
          phone: '+962791234568',
        ),
        averageRating: 4.8,
        totalRatings: 18,
      ),
      Provider(
        id: '3',
        fullName: 'Omar Khalil',
        serviceType: 'Painter',
        email: 'omar@example.com',
        companyName: 'Omar Painting Services',
        serviceDescription: 'Quality painting and decoration services',
        hourlyRate: 20.0,
        location: ProviderLocation(
          addressText: 'Zarqa, Jordan',
          city: 'Zarqa',
        ),
        contactInfo: ProviderContactInfo(
          phone: '+962791234569',
        ),
        averageRating: 4.2,
        totalRatings: 12,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return WillPopScope(
      onWillPop: () async {
        // Handle back button press
        if (_currentIndex != 0) {
          // If not on home tab, go back to home
          setState(() {
            _currentIndex = 0;
          });
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
          return false; // Don't pop the route
        }
        // If on home tab, allow normal back navigation
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark ? AppTheme.dark : AppTheme.light,
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            _buildHomeTab(),
            const ProviderListScreen(),
            const UserBookingsScreen(),
            FavoritesScreen(
              favoriteProviderIds: favoriteProviders,
              showAppBar: false, // No AppBar when used as tab
            ),
            const UserProfileScreen(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(isDark),
      ),
    );
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildHomeTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return CustomScrollView(
      slivers: [
        // Custom App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          backgroundColor: isDark ? AppTheme.dark : AppTheme.white,
          elevation: 0,
          automaticallyImplyLeading: false, // Remove back button
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_rounded),
              color: isDark ? AppTheme.white : AppTheme.primary,
              onPressed: () {
                // Navigate to user chats screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserChatsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Jordan Service Provider',
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primary,
                    AppTheme.secondary,
                  ],
                ),
              ),
            ),
          ),
        ),
        
        // Welcome Section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(isDark),
                const SizedBox(height: 24),
                _buildQuickActions(isDark),
                const SizedBox(height: 24),
                _buildRecentProviders(isDark),
                const SizedBox(height: 24),
                _buildStatsCard(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primary,
            AppTheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.home_rounded,
              color: AppTheme.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back!',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find the perfect service provider for your needs',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: isDark ? AppTheme.white : AppTheme.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.search_rounded,
                title: 'Find Services',
                subtitle: 'Browse providers',
                color: AppTheme.primary,
                isDark: isDark,
                onTap: () => _onTabTapped(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.calendar_today_rounded,
                title: 'My Bookings',
                subtitle: 'View appointments',
                color: AppTheme.accent,
                isDark: isDark,
                onTap: () => _onTabTapped(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.favorite_rounded,
                title: 'Favorites',
                subtitle: 'Saved providers',
                color: AppTheme.warning,
                isDark: isDark,
                onTap: () => _onTabTapped(3),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_rounded,
                title: 'Profile',
                subtitle: 'Manage account',
                color: AppTheme.secondary,
                isDark: isDark,
                onTap: () => _onTabTapped(4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.dark : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentProviders(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Providers',
              style: TextStyle(
                color: isDark ? AppTheme.white : AppTheme.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _onTabTapped(1),
              child: Text(
                'See All',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: FutureBuilder<List<Provider>>(
            future: _providersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                  ),
                );
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading providers',
                    style: TextStyle(
                      color: isDark ? AppTheme.white : AppTheme.black,
                    ),
                  ),
                );
              }
              
              final providers = snapshot.data ?? [];
              if (providers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No providers found',
                        style: TextStyle(
                          color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
                        ),
                      ),
                    ],
                  ),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: providers.take(5).length,
                itemBuilder: (context, index) {
                  final provider = providers[index];
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildProviderCard(provider, isDark),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(Provider provider, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(
                Icons.business_rounded,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.fullName ?? 'Unknown',
                  style: TextStyle(
                    color: isDark ? AppTheme.white : AppTheme.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  provider.serviceType ?? 'Service',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppTheme.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${provider.averageRating?.toStringAsFixed(1) ?? '4.5'}',
                      style: TextStyle(
                        color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark : AppTheme.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Activity',
            style: TextStyle(
              color: isDark ? AppTheme.white : AppTheme.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today_rounded,
                  value: '3',
                  label: 'Active Bookings',
                  color: AppTheme.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.favorite_rounded,
                  value: '8',
                  label: 'Favorites',
                  color: AppTheme.warning,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: isDark ? AppTheme.white : AppTheme.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppTheme.systemGray : AppTheme.systemGray,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.dark : AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: isDark 
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppTheme.dark : AppTheme.white,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.systemGray,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_rounded),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
