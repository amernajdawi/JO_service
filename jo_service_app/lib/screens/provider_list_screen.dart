import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as ctxProvider;
import '../models/provider_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';
import './provider_signup_screen.dart';
import './role_selection_screen.dart';
import './provider_detail_screen.dart';
import './favorites_screen.dart';
import 'dart:convert';

class ProviderListScreen extends StatefulWidget {
  final String? initialSearch;
  final String? initialLocation;

  const ProviderListScreen(
      {this.initialSearch, this.initialLocation, super.key});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  late Future<ProviderListResponse> _providersFuture;
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalProviders = 0;
  final int _limit = 10;
  bool _isLoadingPage = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLocation = '';

  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'All',
      'icon': Icons.grid_view_rounded,
    },
    {
      'name': 'Plumbing',
      'icon': Icons.plumbing,
    },
    {
      'name': 'Electrical',
      'icon': Icons.electrical_services,
    },
    {
      'name': 'Cleaning',
      'icon': Icons.cleaning_services,
    },
    {
      'name': 'Gardening',
      'icon': Icons.yard,
    },
    {
      'name': 'Painting',
      'icon': Icons.format_paint,
    },
    {
      'name': 'Carpentry',
      'icon': Icons.handyman,
    },
  ];

  @override
  void initState() {
    super.initState();
    // Initialize search query from initialSearch if provided
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchQuery = widget.initialSearch!;
      _searchController.text = _searchQuery;
    }

    // Initialize location from initialLocation if provided
    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      _selectedLocation = widget.initialLocation!;
    }

    _loadProviders();
  }

  void _loadProviders({bool resetPage = false}) {
    if (!mounted) return;
    if (resetPage) {
      _currentPage = 1;
    }
    setState(() {
      _isLoadingPage = true;
    });

    final queryParams = {
      'page': _currentPage.toString(),
      'limit': _limit.toString(),
    };

    // Handle search queries
    if (_searchQuery.isNotEmpty) {
      // If the search query is prefixed with "Category:", it means
      // we're filtering by a specific category only
      if (_searchQuery.startsWith('Category: ')) {
        // Category is already set in _selectedCategory, so we don't need to add search parameter
      } else {
        // Normal search by text
        queryParams['search'] = _searchQuery;
      }
    }

    // Add category filter if not "All"
    if (_selectedCategory != 'All') {
      queryParams['category'] = _selectedCategory;
    }

    // Add location filter if specified
    if (_selectedLocation.isNotEmpty) {
      queryParams['location'] = _selectedLocation;
      queryParams['serviceArea'] =
          _selectedLocation; // Also search in service areas
    }

    _providersFuture = _apiService.fetchProviders(queryParams).then((response) {
      // Apply client-side filtering if search query exists and backend didn't filter
      if (_searchQuery.isNotEmpty &&
          !_searchQuery.startsWith('Category: ') &&
          response.providers.length > 0) {
        // Get the search term for client-side filtering
        final String searchTerm = _searchQuery.toLowerCase();

        // Filter providers whose name contains the search term
        final filteredProviders = response.providers.where((provider) {
          final fullName = (provider.fullName ?? '').toLowerCase();
          final companyName = (provider.companyName ?? '').toLowerCase();
          final serviceType = (provider.serviceType ?? '').toLowerCase();

          return fullName.contains(searchTerm) ||
              companyName.contains(searchTerm) ||
              serviceType.contains(searchTerm);
        }).toList();

        // If we filtered out any providers, return our filtered list
        if (filteredProviders.length != response.providers.length) {
          print(
              'Client-side filtering applied: ${filteredProviders.length} of ${response.providers.length} providers match "$searchTerm"');
          return ProviderListResponse(
            providers: filteredProviders,
            currentPage: response.currentPage,
            totalPages: response.totalPages,
            totalProviders: filteredProviders.length,
          );
        }
      }

      // Apply client-side location filtering if needed
      if (_selectedLocation.isNotEmpty && response.providers.length > 0) {
        final filteredByLocation = response.providers.where((provider) {
          // Check the city field in location
          final providerCity = provider.location?.city?.toLowerCase() ?? '';

          // Check the address text field
          final providerAddress =
              provider.location?.addressText?.toLowerCase() ?? '';

          // Check service areas field if available
          List<String> serviceAreas = [];
          try {
            if (provider.toJson().containsKey('serviceAreas') &&
                provider.toJson()['serviceAreas'] is List) {
              serviceAreas =
                  List<String>.from(provider.toJson()['serviceAreas']);
            }
          } catch (e) {
            print('Error parsing service areas: $e');
          }

          // Check if the provider operates in the selected location
          final bool inCity =
              providerCity.contains(_selectedLocation.toLowerCase());
          final bool inAddress =
              providerAddress.contains(_selectedLocation.toLowerCase());
          final bool inServiceArea = serviceAreas.any((area) =>
              area.toLowerCase().contains(_selectedLocation.toLowerCase()));

          return inCity || inAddress || inServiceArea;
        }).toList();

        if (filteredByLocation.length != response.providers.length) {
          print(
              'Location filtering applied: ${filteredByLocation.length} of ${response.providers.length} providers in $_selectedLocation');
          return ProviderListResponse(
            providers: filteredByLocation,
            currentPage: response.currentPage,
            totalPages: response.totalPages,
            totalProviders: filteredByLocation.length,
          );
        }
      }

      // Return original response if no filtering needed
      return response;
    });

    _providersFuture.then((response) {
      if (mounted) {
        setState(() {
          _totalPages = response.totalPages;
          _totalProviders = response.totalProviders;
          _isLoadingPage = false;
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingPage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading page: ${error.toString()}')),
        );
      }
    });
  }

  void _goToNextPage() {
    if (_currentPage < _totalPages && !_isLoadingPage) {
      setState(() {
        _currentPage++;
      });
      _loadProviders();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1 && !_isLoadingPage) {
      setState(() {
        _currentPage--;
      });
      _loadProviders();
    }
  }

  void _performSearch(String query) {
    // Trim whitespace from the query
    final trimmedQuery = query.trim();

    // If a category filter is already active, and we're now adding a text search
    if (_selectedCategory != 'All' &&
        trimmedQuery.isNotEmpty &&
        !trimmedQuery.startsWith('Category: ')) {
      // Keep both filters - category stays as is, and add text search
      setState(() {
        _searchQuery = trimmedQuery;
      });
    } else {
      // Normal search query
      setState(() {
        _searchQuery = trimmedQuery;

        // If we're searching for a specific category using text (e.g., "Category: Plumbing")
        if (trimmedQuery.startsWith('Category: ')) {
          String categoryName = trimmedQuery.substring('Category: '.length);
          // Find if this category exists in our list
          bool validCategory =
              _categories.any((cat) => cat['name'] == categoryName);
          if (validCategory) {
            _selectedCategory = categoryName;
          }
        }
      });
    }

    _loadProviders(resetPage: true);
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;

      // If we're selecting a specific category, update the search UI to reflect that
      if (category != 'All') {
        _searchController.text = 'Category: $category';
      } else if (_searchQuery.startsWith('Category: ')) {
        // Clear the search box if we're deselecting a category filter
        _searchController.text = '';
      }
    });
    _loadProviders(resetPage: true);
  }

  // Clear all filters and search
  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedCategory = 'All';
      _searchController.clear();
    });
    _loadProviders(resetPage: true);
  }

  // This is a helper method for development to show some sample data
  // when the backend is not returning results. Remove in production.
  void _createSampleData() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sample Data Mode'),
        content: Text(
            'This will display sample data for testing purposes. The data is not real and not saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                // Create and show a sample provider with the name containing the search term
                final sampleProvider = Provider(
                  id: 'sample-1',
                  fullName: _searchQuery.isNotEmpty
                      ? 'Amer Professional Services'
                      : 'John Doe',
                  companyName: _searchQuery.isNotEmpty
                      ? 'Amer IT Solutions'
                      : 'ABC Company',
                  serviceType: _selectedCategory != 'All'
                      ? _selectedCategory
                      : 'General Services',
                  hourlyRate: 75.0,
                  averageRating: 4.5,
                  totalRatings: 12,
                  serviceDescription:
                      'Professional services with years of experience',
                  location: ProviderLocation(
                    addressText: 'New York, NY',
                    coordinates: [-74.0060, 40.7128],
                  ),
                );

                _providersFuture = Future.value(ProviderListResponse(
                  providers: [sampleProvider],
                  currentPage: 1,
                  totalPages: 1,
                  totalProviders: 1,
                ));
              });
            },
            child: Text('Show Sample Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Toggle favorite status for a provider
  void _toggleFavorite(String providerId) {
    setState(() {
      if (favoriteProviders.contains(providerId)) {
        favoriteProviders.remove(providerId);
      } else {
        favoriteProviders.add(providerId);
      }
    });
    print('Favorites count: ${favoriteProviders.length}');
  }

  // Add this method to handle location selection
  void _selectLocation(String location) {
    setState(() {
      _selectedLocation = location;
    });
    _loadProviders(resetPage: true);
  }

  // Show a dialog to select location
  void _showLocationSelectionDialog() {
    // List of Jordanian cities
    final List<String> jordanCities = [
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

    // Selected city (initially the current location)
    String selectedCity = _selectedLocation;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select City'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: jordanCities.length,
                    itemBuilder: (context, index) {
                      final city = jordanCities[index];
                      return ListTile(
                        title: Text(city),
                        trailing: selectedCity == city
                            ? Icon(Icons.check, color: AppTheme.primary)
                            : null,
                        onTap: () {
                          selectedCity = city;
                          Navigator.of(context).pop();
                          _selectLocation(city);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear location filter
                _selectLocation('');
              },
              child: Text('Clear Filter'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService =
        ctxProvider.Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      backgroundColor: AppTheme.light,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: Text(
          _selectedLocation.isNotEmpty
              ? 'Providers in $_selectedLocation'
              : _searchQuery.isNotEmpty && !_searchQuery.startsWith('Category:')
                  ? 'Results for "${_searchQuery}"'
                  : 'Service Providers',
          style: AppTheme.h3.copyWith(color: AppTheme.dark),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.dark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (favoriteProviders.isNotEmpty)
            IconButton(
              icon: Icon(Icons.favorite, color: Colors.red),
              tooltip: 'View Favorites',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FavoritesScreen(
                      favoriteProviderIds: favoriteProviders,
                    ),
                  ),
                );
              },
            ),
          if (_searchQuery.isNotEmpty || _selectedCategory != 'All')
            IconButton(
              icon: Icon(Icons.filter_alt_off, color: AppTheme.primary),
              tooltip: 'Clear Filters',
              onPressed: _clearFilters,
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.dark),
            tooltip: 'Refresh List',
            onPressed: () => _loadProviders(resetPage: true),
          ),
          // Add a debug button for sample data creation (remove in production)
          IconButton(
            icon: Icon(Icons.bug_report, color: AppTheme.dark),
            tooltip: 'Create Sample Data',
            onPressed: _createSampleData,
          ),
          if (_selectedLocation.isNotEmpty)
            IconButton(
              icon: Icon(Icons.location_on, color: AppTheme.primary),
              tooltip: 'City: $_selectedLocation',
              onPressed: () {
                // Show location selection dialog
                _showLocationSelectionDialog();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildCategoryFilter(),
          Expanded(
            child: FutureBuilder<ProviderListResponse>(
              future: _providersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading providers: ${snapshot.error}.\nMake sure your backend server is running and accessible.',
                        textAlign: TextAlign.center,
                        style: AppTheme.body3.copyWith(color: AppTheme.danger),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.providers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: AppTheme.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No providers found',
                          style: AppTheme.h3.copyWith(color: AppTheme.dark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No results match "${_searchQuery}"'
                              : _selectedCategory != 'All'
                                  ? 'No providers in ${_selectedCategory} category'
                                  : 'Add some via your API or try refreshing',
                          style: AppTheme.body3.copyWith(color: AppTheme.grey),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isNotEmpty ||
                            _selectedCategory != 'All')
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: ElevatedButton.icon(
                              icon: Icon(Icons.clear, color: AppTheme.white),
                              label: Text('Clear Filters',
                                  style: TextStyle(color: AppTheme.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radius),
                                ),
                              ),
                              onPressed: _clearFilters,
                            ),
                          ),
                      ],
                    ),
                  );
                }

                final providerListResponse = snapshot.data!;
                final providers = providerListResponse.providers;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return _buildProviderCard(provider);
                  },
                );
              },
            ),
          ),
          if (_totalProviders > 0) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppTheme.white,
      child: Column(
        children: [
          // Search box
          Container(
            decoration: BoxDecoration(
              color: AppTheme.light,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              boxShadow: [AppTheme.lightShadow],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or service type...',
                hintStyle: TextStyle(color: AppTheme.grey),
                prefixIcon: Icon(Icons.search, color: AppTheme.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.grey),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onSubmitted: _performSearch,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                // Only search if we have 2+ characters or empty string (to clear search)
                if (value.length >= 2 || value.isEmpty) {
                  _performSearch(value);
                }
              },
            ),
          ),

          // Location filter indicator
          if (_selectedLocation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: InkWell(
                onTap: _showLocationSelectionDialog,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border:
                        Border.all(color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: AppTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'City: $_selectedLocation',
                        style: TextStyle(color: AppTheme.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 14, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 80,
      color: AppTheme.white,
      padding: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['name'];

          return GestureDetector(
            onTap: () => _selectCategory(category['name']),
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primary : AppTheme.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color:
                            isSelected ? AppTheme.primary : AppTheme.greyLight,
                      ),
                      boxShadow: isSelected ? [AppTheme.lightShadow] : null,
                    ),
                    child: Icon(
                      category['icon'],
                      color: isSelected ? AppTheme.white : AppTheme.grey,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    category['name'],
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.grey,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProviderCard(Provider provider) {
    final isFavorite = provider.id != null && favoriteProviders.contains(provider.id);

    // Determine provider location info
    String? providerCity = provider.location?.city;
    String? addressText = provider.location?.addressText;

    // Highlight the location if it matches the selected filter
    final bool locationMatches = _selectedLocation.isNotEmpty &&
        ((providerCity
                    ?.toLowerCase()
                    .contains(_selectedLocation.toLowerCase()) ??
                false) ||
            (addressText
                    ?.toLowerCase()
                    .contains(_selectedLocation.toLowerCase()) ??
                false));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pushNamed(
            ProviderDetailScreen.routeName,
            arguments: provider.id ?? '',
          );
        },
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProviderAvatar(provider),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.companyName ?? provider.fullName ?? 'N/A',
                            style: AppTheme.h3.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorite ? Colors.red : AppTheme.grey,
                            size: 20,
                          ),
                          onPressed: () {
                            if (provider.id != null) {
                              _toggleFavorite(provider.id!);
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFavorite
                                    ? 'Removed from favorites'
                                    : 'Added to favorites'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          tooltip: isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          padding: EdgeInsets.all(4),
                          constraints: BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '\$${provider.hourlyRate ?? 'N/A'}/hr',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 16,
                          color: AppTheme.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            provider.serviceType ?? 'General Services',
                            style: TextStyle(color: AppTheme.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Location information with icon
                    if (providerCity != null || addressText != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: locationMatches
                                ? AppTheme.primary
                                : AppTheme.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              providerCity != null
                                  ? (addressText != null
                                      ? '$providerCity, $addressText'
                                      : providerCity)
                                  : (addressText ?? 'Location not specified'),
                              style: TextStyle(
                                color: locationMatches
                                    ? AppTheme.primary
                                    : AppTheme.grey,
                                fontWeight: locationMatches
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildRatingStars(provider.averageRating),
                        const SizedBox(width: 4),
                        Text(
                          provider.totalRatings != null
                              ? '(${provider.totalRatings})'
                              : '(0)',
                          style: TextStyle(color: AppTheme.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    if (provider.serviceDescription != null &&
                        provider.serviceDescription!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          provider.serviceDescription!,
                          style: TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProviderAvatar(Provider provider) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(provider.fullName ?? provider.companyName ?? 'P'),
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else {
      return name.isNotEmpty ? name[0].toUpperCase() : 'P';
    }
  }

  Widget _buildRatingStars(double? rating) {
    final actualRating = rating ?? 0.0;
    return Row(
      children: List.generate(5, (index) {
        if (index < actualRating.floor()) {
          return Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == actualRating.floor() && actualRating % 1 > 0) {
          return Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: AppTheme.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPaginationButton(
            icon: Icons.arrow_back_ios,
            onPressed: (_currentPage > 1 && !_isLoadingPage)
                ? _goToPreviousPage
                : null,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Page $_currentPage of $_totalPages',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildPaginationButton(
            icon: Icons.arrow_forward_ios,
            onPressed: (_currentPage < _totalPages && !_isLoadingPage)
                ? _goToNextPage
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      color: onPressed != null ? AppTheme.primary : AppTheme.greyLight,
      tooltip: onPressed != null
          ? (icon == Icons.arrow_back_ios ? 'Previous Page' : 'Next Page')
          : null,
    );
  }
}
