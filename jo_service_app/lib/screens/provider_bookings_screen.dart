import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import './booking_detail_screen.dart';

class ProviderBookingsScreen extends StatefulWidget {
  static const routeName = '/provider-bookings';

  const ProviderBookingsScreen({super.key});

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with TickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;
  bool _isLoading = false;
  List<Booking> _bookings = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMorePages = false;
  final ScrollController _scrollController = ScrollController();

  // Define status filters for tabs
  final List<String?> _statusFilters = [
    null, // All bookings
    'pending',
    'accepted',
    'in_progress',
    'completed',
    'declined_by_provider',
    'cancelled_by_user',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _scrollController.addListener(_scrollListener);
    _fetchBookings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  // Handle tab changes to filter bookings by status
  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentPage = 1;
        _bookings = [];
      });
      _fetchBookings();
    }
  }

  // Implement infinite scrolling
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMorePages) {
        _loadMoreBookings();
      }
    }
  }

  // Fetch bookings with the current filter
  Future<void> _fetchBookings() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final providerId = await authService.getUserId();

      if (token == null || providerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error. Please login again.')),
        );
        return;
      }

      // First try the regular endpoint
      try {
        final result = await _bookingService.getProviderBookings(
          token: token,
          status: _statusFilters[_tabController.index],
          page: _currentPage,
        );

        final bookings = result['bookings'] as List<Booking>;

        setState(() {
          _bookings = bookings;
          _currentPage = result['currentPage'] as int;
          _totalPages = result['totalPages'] as int;
          _hasMorePages = _currentPage < _totalPages;
          _isLoading = false;
        });
      } catch (e) {
        // If regular endpoint fails, try the direct method
        print('Regular endpoint failed, trying direct method: $e');
        final bookings = await _bookingService.getBookingsByProviderId(
          token: token,
          providerId: providerId,
        );

        setState(() {
          _bookings = bookings;
          _currentPage = 1;
          _totalPages = 1;
          _hasMorePages = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
      );
    }
  }

  // Load more bookings when scrolling to the bottom
  Future<void> _loadMoreBookings() async {
    if (_isLoading || !_hasMorePages) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final providerId = await authService.getUserId();

      if (token == null || providerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error. Please login again.')),
        );
        return;
      }

      try {
        final result = await _bookingService.getProviderBookings(
          token: token,
          status: _statusFilters[_tabController.index],
          page: _currentPage + 1,
        );

        final List<Booking> newBookings = result['bookings'] as List<Booking>;

        setState(() {
          _bookings.addAll(newBookings);
          _currentPage = result['currentPage'] as int;
          _totalPages = result['totalPages'] as int;
          _hasMorePages = _currentPage < _totalPages;
          _isLoading = false;
        });
      } catch (e) {
        // If pagination fails, don't add more bookings
        setState(() {
          _hasMorePages = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more bookings: $e')),
      );
    }
  }

  // Update booking status (accept, decline, etc.)
  Future<void> _updateBookingStatus(Booking booking, String newStatus) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Authentication error. Please login again.')),
        );
        return;
      }

      await _bookingService.updateBookingStatus(
        token: token,
        bookingId: booking.id,
        status: newStatus,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Booking ${_getStatusActionText(newStatus)} successfully.')),
      );

      // Refresh the list
      _fetchBookings();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking: $e')),
      );
    }
  }

  String _getStatusActionText(String status) {
    switch (status) {
      case 'accepted':
        return 'accepted';
      case 'declined_by_provider':
        return 'declined';
      case 'in_progress':
        return 'marked as in progress';
      case 'completed':
        return 'marked as completed';
      default:
        return 'updated';
    }
  }

  // Confirm status update dialog
  void _showStatusUpdateDialog(
      Booking booking, String action, String newStatus) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _updateBookingStatus(booking, newStatus);
            },
            child: Text('Yes',
                style: TextStyle(color: _getActionColor(newStatus))),
          ),
        ],
      ),
    );
  }

  Color _getActionColor(String status) {
    switch (status) {
      case 'declined_by_provider':
        return Colors.red;
      case 'accepted':
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  // Navigate to booking details
  void _viewBookingDetails(Booking booking) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => BookingDetailScreen(bookingId: booking.id),
          ),
        )
        .then((_) => _fetchBookings()); // Refresh when returning from details
  }

  // Build a card for each booking
  Widget _buildBookingCard(Booking booking) {
    final formattedDate =
        DateFormat('MMM dd, yyyy').format(booking.serviceDateTime);
    final formattedTime = DateFormat('hh:mm a').format(booking.serviceDateTime);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _viewBookingDetails(booking),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      booking.user?.fullName ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(booking.statusColor),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booking.readableStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    formattedDate,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              if (booking.serviceLocationDetails != null &&
                  booking.serviceLocationDetails!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          booking.serviceLocationDetails!,
                          style: TextStyle(color: Colors.grey[700]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),

              // Provider actions based on booking status
              if (booking.canBeAcceptedByProvider)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      label: const Text('Accept',
                          style: TextStyle(color: Colors.green)),
                      onPressed: () => _showStatusUpdateDialog(
                          booking, 'accept', 'accepted'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Decline',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () => _showStatusUpdateDialog(
                          booking, 'decline', 'declined_by_provider'),
                    ),
                  ],
                )
              else if (booking.canBeMarkedInProgress)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.play_arrow, color: Colors.blue),
                    label: const Text('Start Service',
                        style: TextStyle(color: Colors.blue)),
                    onPressed: () => _showStatusUpdateDialog(
                        booking, 'start', 'in_progress'),
                  ),
                )
              else if (booking.canBeMarkedCompleted)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: const Icon(Icons.done_all, color: Colors.green),
                    label: const Text('Complete',
                        style: TextStyle(color: Colors.green)),
                    onPressed: () => _showStatusUpdateDialog(
                        booking, 'complete', 'completed'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: 'All'),
            const Tab(text: 'Pending'),
            const Tab(text: 'Accepted'),
            const Tab(text: 'In Progress'),
            const Tab(text: 'Completed'),
            const Tab(text: 'Declined'),
            const Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
        child: _isLoading && _bookings.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _bookings.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('No bookings found'),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);
                              final token = await authService.getToken();

                              if (token == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Authentication error. Please login again.')),
                                );
                                return;
                              }

                              // Try to get a specific booking directly as a test
                              final specificBookingId =
                                  '6842f0d4f1a24fa13b8c5849';
                              try {
                                final booking =
                                    await _bookingService.getBookingById(
                                  token: token,
                                  bookingId: specificBookingId,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Found specific booking: ${booking.id}')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to get specific booking: $e')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Debug test error: $e')),
                              );
                            }
                          },
                          child:
                              const Text('Debug Test: Check Specific Booking'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);
                              final token = await authService.getToken();

                              if (token == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Authentication error. Please login again.')),
                                );
                                return;
                              }

                              // Try to fetch all bookings
                              try {
                                final allBookings = await _bookingService
                                    .fetchAllBookingsForTests(
                                  token: token,
                                );

                                if (allBookings.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'No bookings found in the system')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Found ${allBookings.length} bookings in the system')),
                                  );
                                  // Update the bookings list
                                  setState(() {
                                    _bookings = allBookings;
                                  });
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Failed to get all bookings: $e')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Debug test error: $e')),
                              );
                            }
                          },
                          child: const Text('Debug Test: Fetch All Bookings'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);
                              final token = await authService.getToken();
                              final userId = await authService.getUserId();

                              if (token == null || userId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Authentication error. Please login again.')),
                                );
                                return;
                              }

                              print(
                                  'Attempting direct provider ID lookup with: $userId');

                              // Direct provider ID lookup
                              final bookings =
                                  await _bookingService.getBookingsByProviderId(
                                token: token,
                                providerId: userId,
                              );

                              if (bookings.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'No bookings found with direct provider ID lookup')),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Found ${bookings.length} bookings with direct provider ID lookup')),
                                );

                                // Update the bookings list
                                setState(() {
                                  _bookings = bookings;
                                });
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Error with direct provider ID lookup: $e')),
                              );
                            }
                          },
                          child: const Text(
                              'Debug Test: Direct Provider ID Lookup'),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            try {
                              final authService = Provider.of<AuthService>(
                                  context,
                                  listen: false);
                              final token = await authService.getToken();
                              final providerUserId =
                                  await authService.getUserId();

                              if (token == null || providerUserId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Authentication error. Please login again.')),
                                );
                                return;
                              }

                              // Fetch all bookings to see what we're working with
                              final allBookings = await _bookingService
                                  .fetchAllBookingsForTests(token: token);

                              // Find a booking to reassign for testing
                              if (allBookings.isNotEmpty) {
                                final booking = allBookings[0];
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Found booking ${booking.id} to reassign to you')),
                                );

                                // Call reassign endpoint (you'll need to create this)
                                try {
                                  await _bookingService
                                      .reassignBookingToProvider(
                                    token: token,
                                    bookingId: booking.id,
                                    providerId: providerUserId,
                                  );

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Successfully reassigned booking ${booking.id} to you')),
                                  );

                                  // Refresh the bookings list
                                  _fetchBookings();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Failed to reassign booking: $e')),
                                  );
                                }
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'No bookings found to reassign')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Debug test error: $e')),
                              );
                            }
                          },
                          child: const Text('Debug: Reassign Booking To Me'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _bookings.length + (_hasMorePages ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < _bookings.length) {
                        return _buildBookingCard(_bookings[index]);
                      } else {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                    },
                  ),
      ),
    );
  }
}
