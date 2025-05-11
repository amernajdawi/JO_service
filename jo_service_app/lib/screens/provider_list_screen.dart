import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as ctxProvider;
import '../models/provider_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import './provider_signup_screen.dart';
import './role_selection_screen.dart';
import './provider_detail_screen.dart';

class ProviderListScreen extends StatefulWidget {
  const ProviderListScreen({super.key});

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  late Future<ProviderListResponse> _providersFuture;
  final ApiService _apiService = ApiService();

  int _currentPage = 1;
  int _totalPages = 1;
  int _totalProviders = 0;
  final int _limit = 10;
  bool _isLoadingPage = false;

  @override
  void initState() {
    super.initState();
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

    _providersFuture = _apiService.fetchProviders(queryParams);
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

  @override
  Widget build(BuildContext context) {
    final authService =
        ctxProvider.Provider.of<AuthService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Service Providers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            tooltip: 'Sign Up as Provider',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const ProviderSignUpScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await authService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => const RoleSelectionScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh List',
            onPressed: () => _loadProviders(resetPage: true),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Providers',
            onPressed: () {
              // TODO: Implement search functionality
              // _showSearchDialog(); // You would define this method
            },
          ),
        ],
      ),
      body: FutureBuilder<ProviderListResponse>(
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
                  'Error loading providers: ${snapshot.error}.\nMake sure your backend server is running and accessible. Check the API base URL in api_service.dart.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.providers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No providers found.'),
                  SizedBox(height: 10),
                  Text('Add some via your API or try refreshing.'),
                ],
              ),
            );
          }

          final providerListResponse = snapshot.data!;
          final providers = providerListResponse.providers;
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: providers.length,
                  itemBuilder: (context, index) {
                    final provider = providers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          provider.companyName ?? provider.fullName ?? 'N/A',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: 8),
                            Text(
                              provider.serviceType ?? 'General Service',
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              provider.serviceDescription ??
                                  'No description available.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Address: ${provider.location?.addressText ?? 'Not specified'}',
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rating: ${provider.averageRating?.toStringAsFixed(1) ?? 'N/A'} (${provider.totalRatings ?? 0} ratings)',
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            ProviderDetailScreen.routeName,
                            arguments: provider.id,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              if (_totalProviders > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: (_currentPage > 1 && !_isLoadingPage)
                            ? _goToPreviousPage
                            : null,
                        tooltip: 'Previous Page',
                      ),
                      Text('Page $_currentPage of $_totalPages',
                          style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios),
                        onPressed:
                            (_currentPage < _totalPages && !_isLoadingPage)
                                ? _goToNextPage
                                : null,
                        tooltip: 'Next Page',
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
