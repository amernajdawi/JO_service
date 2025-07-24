import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/booking_model.dart';
import '../services/auth_service.dart';
import '../services/booking_service.dart';
import '../services/rating_service.dart';
import '../services/navigation_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  static const routeName = '/booking-detail';

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final BookingService _bookingService = BookingService();
  final RatingService _ratingService = RatingService();
  bool _isLoading = true;
  bool _isRatingSubmitting = false;
  Booking? _booking;
  late String _userType;
  double _userRating = 0;
  String _userReview = '';
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();
      final userType = await authService.getUserType();

      if (token == null || userType == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Authentication error. Please login again.')),
          );
        }
        return;
      }

      _userType = userType;
      final booking = await _bookingService.getBookingById(
        token: token,
        bookingId: widget.bookingId,
      );

      // Check if user has already rated this booking
      if (userType == 'user' && booking.status == 'completed') {
        try {
          final hasRated = await _ratingService.checkIfUserHasRated(
            token: token,
            bookingId: widget.bookingId,
          );
          if (mounted) {
            setState(() {
              _hasRated = hasRated;
            });
          }
        } catch (e) {
          print('Error checking if user has rated: $e');
          // Default to false if there's an error
          if (mounted) {
            setState(() {
              _hasRated = false;
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking details: $e')),
        );
      }
    }
  }

  Future<void> _updateBookingStatus(String newStatus) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Authentication error. Please login again.')),
          );
        }
        return;
      }

      final updatedBooking = await _bookingService.updateBookingStatus(
        token: token,
        bookingId: widget.bookingId,
        status: newStatus,
      );

      if (mounted) {
        setState(() {
          _booking = updatedBooking;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Booking ${_getStatusActionText(newStatus)} successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating booking status: $e')),
        );
      }
    }
  }

  Future<void> _submitRating() async {
    if (_userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isRatingSubmitting = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final token = await authService.getToken();

      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Authentication error. Please login again.')),
          );
        }
        return;
      }

      await _ratingService.rateProvider(
        token: token,
        bookingId: widget.bookingId,
        providerId: _booking!.provider!.id ?? '',
        rating: _userRating,
        review: _userReview,
      );

      if (mounted) {
        setState(() {
          _isRatingSubmitting = false;
          _hasRated = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRatingSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting rating: $e')),
        );
      }
    }
  }

  String _getStatusActionText(String status) {
    switch (status) {
      case 'cancelled_by_user':
        return 'cancelled';
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

  void _showConfirmationDialog(String action, String newStatus) {
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
              _updateBookingStatus(newStatus);
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
      case 'cancelled_by_user':
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

  Widget _buildStatusActions() {
    if (_booking == null) return const SizedBox.shrink();

    if (_userType == 'user') {
      // User actions
      if (_booking!.canBeCancelledByUser) {
        return ElevatedButton.icon(
          icon: const Icon(Icons.cancel, color: Colors.white),
          label: const Text('Cancel Booking'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () =>
              _showConfirmationDialog('cancel', 'cancelled_by_user'),
        );
      }
    } else if (_userType == 'provider') {
      // Provider actions
      if (_booking!.canBeAcceptedByProvider) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => _showConfirmationDialog('accept', 'accepted'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.cancel, color: Colors.white),
              label: const Text('Decline'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () =>
                  _showConfirmationDialog('decline', 'declined_by_provider'),
            ),
          ],
        );
      } else if (_booking!.canBeMarkedInProgress) {
        return ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow, color: Colors.white),
          label: const Text('Start Service'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          onPressed: () => _showConfirmationDialog('start', 'in_progress'),
        );
      } else if (_booking!.canBeMarkedCompleted) {
        return ElevatedButton.icon(
          icon: const Icon(Icons.done_all, color: Colors.white),
          label: const Text('Complete Service'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          onPressed: () => _showConfirmationDialog('complete', 'completed'),
        );
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildRatingSection() {
    if (_booking == null ||
        _userType != 'user' ||
        _booking!.status != 'completed') {
      return const SizedBox.shrink();
    }

    if (_hasRated) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Thank you for your rating!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You have already rated this service.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate this service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    icon: Icon(
                      i <= _userRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        _userRating = i.toDouble();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Review (optional)',
                border: OutlineInputBorder(),
                hintText: 'Write your experience with this service...',
              ),
              maxLines: 3,
              onChanged: (value) {
                _userReview = value;
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: _isRatingSubmitting ? null : _submitRating,
                child: _isRatingSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit Rating'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Open navigation to user's location
  Future<void> _openNavigation() async {
    try {
      if (_booking?.serviceLocationDetails != null && 
          _booking!.serviceLocationDetails!.isNotEmpty) {
        await NavigationService.openGoogleMapsNavigation(
          latitude: 31.9539, // Default to Amman coordinates
          longitude: 35.9106,
          address: _booking!.serviceLocationDetails,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No location information available'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open navigation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _booking != null
        ? DateFormat('EEEE, MMM dd, yyyy').format(_booking!.serviceDateTime)
        : '';
    final formattedTime = _booking != null
        ? DateFormat('hh:mm a').format(_booking!.serviceDateTime)
        : '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Card
                      Card(
                        color: Color(_booking!.statusColor).withOpacity(0.2),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Color(_booking!.statusColor)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status: ${_booking!.readableStatus}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Color(_booking!.statusColor),
                                      ),
                                    ),
                                    if (_booking!.createdAt != null)
                                      Text(
                                        'Requested on ${DateFormat('MMM dd, yyyy').format(_booking!.createdAt!)}',
                                        style:
                                            const TextStyle(color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Service Details
                      const Text(
                        'Service Details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              _booking!.provider?.profilePictureUrl != null &&
                                      _booking!.provider!.profilePictureUrl!
                                          .isNotEmpty
                                  ? NetworkImage(
                                      _booking!.provider!.profilePictureUrl!)
                                  : const AssetImage('assets/default_user.png')
                                      as ImageProvider,
                          backgroundColor: Colors.grey[200],
                        ),
                        title: Text(
                            _booking!.provider?.fullName ?? 'Unknown Provider'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_booking!.provider?.serviceType ??
                                'Unknown Service'),
                            if (_booking!.provider?.averageRating != null &&
                                _booking!.provider!.averageRating! > 0)
                              Row(
                                children: [
                                  Icon(Icons.star,
                                      color: Colors.amber, size: 16),
                                  Text(
                                      ' ${_booking!.provider!.averageRating!.toStringAsFixed(1)}')
                                ],
                              ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Date and Time
                      ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Date'),
                        subtitle: Text(formattedDate),
                      ),
                      ListTile(
                        leading: const Icon(Icons.access_time),
                        title: const Text('Time'),
                        subtitle: Text(formattedTime),
                      ),

                      // Location if available
                      if (_booking!.serviceLocationDetails != null &&
                          _booking!.serviceLocationDetails!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.location_on),
                          title: const Text('Location'),
                          subtitle: Text(_booking!.serviceLocationDetails!),
                          trailing: _userType == 'provider' 
                              ? IconButton(
                                  icon: const Icon(Icons.directions),
                                  onPressed: () => _openNavigation(),
                                  tooltip: 'Open in Google Maps',
                                )
                              : null,
                        ),

                      // Notes if available
                      if (_booking!.userNotes != null &&
                          _booking!.userNotes!.isNotEmpty)
                        ListTile(
                          leading: const Icon(Icons.note),
                          title: const Text('Notes'),
                          subtitle: Text(_booking!.userNotes!),
                        ),

                      // Rating section for completed bookings (user only)
                      _buildRatingSection(),

                      const SizedBox(height: 32),

                      // Actions
                      Center(child: _buildStatusActions()),
                    ],
                  ),
                ),
    );
  }
}
