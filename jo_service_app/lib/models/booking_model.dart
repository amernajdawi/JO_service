import 'package:jo_service_app/models/provider_model.dart';
import 'package:jo_service_app/models/user_model.dart';

class Booking {
  final String id;
  final User? user;
  final Provider? provider;
  final DateTime serviceDateTime;
  final String? serviceLocationDetails;
  final String? userNotes;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Booking({
    required this.id,
    this.user,
    this.provider,
    required this.serviceDateTime,
    this.serviceLocationDetails,
    this.userNotes,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle the case where the server returns just an ID string
    if (json.containsKey('_id') && json.length == 1) {
      // If only ID is provided, create a minimal booking with default values
      return Booking(
        id: json['_id'],
        serviceDateTime: DateTime.now(),
        status: 'pending',
      );
    }

    return Booking(
      id: json['_id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      provider:
          json['provider'] != null ? Provider.fromJson(json['provider']) : null,
      serviceDateTime: DateTime.parse(json['serviceDateTime']),
      serviceLocationDetails: json['serviceLocationDetails'],
      userNotes: json['userNotes'],
      status: json['status'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': user?.toJson(),
      'provider': provider?.toJson(),
      'serviceDateTime': serviceDateTime.toIso8601String(),
      'serviceLocationDetails': serviceLocationDetails,
      'userNotes': userNotes,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Helper method to create a booking request JSON
  static Map<String, dynamic> createBookingRequest({
    required String providerId,
    required DateTime serviceDateTime,
    String? serviceLocationDetails,
    String? userNotes,
  }) {
    return {
      'providerId': providerId,
      'serviceDateTime': serviceDateTime.toIso8601String(),
      'serviceLocationDetails': serviceLocationDetails,
      'userNotes': userNotes,
    };
  }

  // Method to get a readable status
  String get readableStatus {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'declined_by_provider':
        return 'Declined by Provider';
      case 'cancelled_by_user':
        return 'Cancelled';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'payment_due':
        return 'Payment Due';
      case 'paid':
        return 'Paid';
      default:
        return status;
    }
  }

  // Method to get status color
  int get statusColor {
    switch (status) {
      case 'pending':
        return 0xFFFFA726; // Orange
      case 'accepted':
        return 0xFF4CAF50; // Green
      case 'declined_by_provider':
        return 0xFFE53935; // Red
      case 'cancelled_by_user':
        return 0xFFE53935; // Red
      case 'in_progress':
        return 0xFF2196F3; // Blue
      case 'completed':
        return 0xFF4CAF50; // Green
      case 'payment_due':
        return 0xFFE53935; // Red
      case 'paid':
        return 0xFF4CAF50; // Green
      default:
        return 0xFF9E9E9E; // Grey
    }
  }

  // Check if the booking can be cancelled by the user
  bool get canBeCancelledByUser {
    return status == 'pending';
  }

  // Check if the booking can be accepted by the provider
  bool get canBeAcceptedByProvider {
    return status == 'pending';
  }

  // Check if the booking can be declined by the provider
  bool get canBeDeclinedByProvider {
    return status == 'pending';
  }

  // Check if the booking can be marked as in progress
  bool get canBeMarkedInProgress {
    return status == 'accepted';
  }

  // Check if the booking can be marked as completed
  bool get canBeMarkedCompleted {
    return status == 'in_progress';
  }
}
