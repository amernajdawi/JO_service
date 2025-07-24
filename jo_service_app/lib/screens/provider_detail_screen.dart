import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/provider_model.dart';
import '../models/chat_conversation.dart';
import 'package:provider/provider.dart' as ctx; // Alias for provider package
import '../services/auth_service.dart'; // To get token for API calls
import './create_booking_screen.dart'; // For booking navigation
import './favorites_screen.dart'; // For favorites screen
import './chat_screen.dart'; // For chat navigation

// Global set to track favorites across the app
final Set<String> favoriteProviders = {};

class ProviderDetailScreen extends StatefulWidget {
  static const routeName = '/provider-detail';

  final String providerId;

  const ProviderDetailScreen({required this.providerId, super.key});

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  final ApiService _apiService = ApiService();
  Future<Provider?>? _providerFuture; // Nullable as provider might not be found

  // Check if the current provider is in favorites
  bool get isFavorite => favoriteProviders.contains(widget.providerId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchProviderDetails();
      }
    });
  }

  // Toggle favorite status of the provider
  void _toggleFavorite() {
    setState(() {
      if (isFavorite) {
        favoriteProviders.remove(widget.providerId);
      } else {
        favoriteProviders.add(widget.providerId);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View Favorites',
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
      ),
    );
  }

  Future<void> _fetchProviderDetails() async {
    final authService = ctx.Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication token not found. Please log in.')),
        );
      }
      setState(() {
        _providerFuture =
            Future.error(Exception('Authentication token not found.'));
      });
      return;
    }
    setState(() {
      _providerFuture = _apiService.fetchProviderById(widget.providerId, token);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Profile'),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
        ],
      ),
      body: FutureBuilder<Provider?>(
        future: _providerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: _fetchProviderDetails,
                      child: const Text('Try Again'))
                ],
              ),
            ));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Provider not found.'));
          }

          final provider = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: provider.profilePictureUrl != null &&
                                provider.profilePictureUrl!.isNotEmpty &&
                                provider.profilePictureUrl!.startsWith('http')
                            ? NetworkImage(provider.profilePictureUrl!)
                            : const AssetImage('assets/default_user.png') as ImageProvider,
                        child: (provider.profilePictureUrl == null ||
                                provider.profilePictureUrl!.isEmpty)
                            ? Text(
                                provider.fullName?.isNotEmpty == true
                                    ? provider.fullName![0].toUpperCase()
                                    : 'P',
                                style: TextStyle(
                                    fontSize: 40,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 1,
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: InkWell(
                            onTap: _toggleFavorite,
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: Text(
                    provider.fullName ?? 'N/A',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (provider.serviceType != null &&
                    provider.serviceType!.isNotEmpty)
                  Center(
                    child: Text(
                      provider.serviceType!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const SizedBox(height: 16.0),
                _buildRatingSection(context, provider),
                const SizedBox(height: 10.0),
                const Divider(),
                const SizedBox(height: 10.0),

                _buildSectionTitle(context, 'Service Details'),
                _buildDetailRow(context, Icons.work_outline, 'Description',
                    provider.serviceDescription ?? 'No description provided.'),
                if (provider.hourlyRate != null)
                  _buildDetailRow(context, Icons.attach_money, 'Hourly Rate',
                      '\$${provider.hourlyRate!.toStringAsFixed(2)}/hr'),
                const SizedBox(height: 10.0),
                const Divider(),
                const SizedBox(height: 10.0),

                _buildSectionTitle(context, 'Location & Contact'),
                _buildDetailRow(context, Icons.location_on_outlined, 'Address',
                    provider.location?.addressText ?? 'Not specified'),
                // TODO: Display map if coordinates are available
                // if (provider.location?.coordinates != null && provider.location!.coordinates!.length == 2) ...

                _buildDetailRow(context, Icons.phone_outlined, 'Phone',
                    provider.contactInfo?.phone ?? 'Not specified'),
                _buildDetailRow(context, Icons.alternate_email_outlined,
                    'Email', provider.email ?? 'Not specified'),
                const SizedBox(height: 10.0),
                const Divider(),
                const SizedBox(height: 10.0),

                _buildSectionTitle(context, 'Availability'),
                _buildDetailRow(
                    context,
                    Icons.access_time_outlined,
                    'Availability',
                    provider.availabilityDetails ?? 'Not specified'),
                const SizedBox(height: 24.0),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: const Text('Book Service'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            textStyle: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          // Navigate to CreateBookingScreen
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CreateBookingScreen(
                                serviceProvider: provider,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        label:
                            Text(isFavorite ? 'Favorited' : 'Add to Favorites'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 15),
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat with Provider'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) {
                            // Create a temporary conversation object to pass to the chat screen
                            final conversation = ChatConversation(
                              id: provider.id ?? 'unknown-provider', // Use provider ID as a temporary unique ID
                              participantId: provider.id ?? 'unknown-provider',
                              participantName: provider.fullName ?? 'Provider',
                              participantAvatar: provider.profilePictureUrl,
                              participantType: 'provider',
                            );
                            return ChatScreen(conversation: conversation);
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (favoriteProviders.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton.icon(
                        icon: const Icon(Icons.favorite),
                        label: const Text('View All Favorites'),
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
                    ),
                  ),
                // TODO: Display Reviews Section
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(BuildContext context, Provider provider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (provider.averageRating != null && provider.averageRating! > 0) ...[
          Icon(Icons.star, color: Colors.amber[600], size: 28),
          const SizedBox(width: 8),
          Text(
            '${provider.averageRating!.toStringAsFixed(1)} ',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            '(${provider.totalRatings} ratings)',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Colors.grey[600]),
          ),
        ] else
          Text(
            'No ratings yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontStyle: FontStyle.italic, color: Colors.grey[600]),
          ),
      ],
    );
  }
}
