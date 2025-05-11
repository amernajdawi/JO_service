import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/provider_model.dart';
import 'package:provider/provider.dart' as ctx; // Alias for provider package
import '../services/auth_service.dart'; // To get token for API calls
// import './booking_screen.dart'; // For booking navigation
// import './chat_screen.dart'; // For chat navigation

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchProviderDetails();
      }
    });
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
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: provider.profilePictureUrl != null &&
                            provider.profilePictureUrl!.isNotEmpty
                        ? NetworkImage(provider.profilePictureUrl!)
                        : null,
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
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: const Text('Book Service'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                        textStyle: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      // TODO: Navigate to BookingScreen
                      // Navigator.of(context).pushNamed(BookingScreen.routeName, arguments: provider.id);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Booking for ${provider.fullName}')));
                    },
                  ),
                ),
                const SizedBox(height: 10.0),
                Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat with Provider'),
                    onPressed: () {
                      // TODO: Navigate to ChatScreen
                      // Navigator.of(context).pushNamed(
                      //   ChatScreen.routeName,
                      //   arguments: {'recipientId': provider.id, 'recipientName': provider.fullName ?? 'Provider'}
                      // );
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Chatting with ${provider.fullName}')));
                    },
                  ),
                )
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
