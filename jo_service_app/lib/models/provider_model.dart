class ProviderLocation {
  final String? addressText;
  final List<double>? coordinates; // longitude, latitude

  ProviderLocation({this.addressText, this.coordinates});

  factory ProviderLocation.fromJson(Map<String, dynamic> json) {
    List<double>? coords;
    if (json['point'] != null && json['point']['coordinates'] is List) {
      coords = (json['point']['coordinates'] as List).cast<double>();
    }
    return ProviderLocation(
      addressText: json['addressText'] as String?,
      coordinates: coords,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addressText': addressText,
      'point': coordinates != null ? {'coordinates': coordinates} : null,
    };
  }
}

class ProviderContactInfo {
  final String? phone;
  // Add other contact fields if needed, e.g., secondaryEmail

  ProviderContactInfo({this.phone});

  factory ProviderContactInfo.fromJson(Map<String, dynamic> json) {
    return ProviderContactInfo(
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
    };
  }
}

class Provider {
  final String id;
  final String? fullName;
  final String? email; // Usually part of top-level, not contactInfo for login
  final String? companyName; // Can be same as fullName or separate
  final String? serviceType;
  final String? serviceDescription; // Changed from description for clarity
  final double? hourlyRate;
  final ProviderLocation? location;
  final ProviderContactInfo? contactInfo;
  final String? availabilityDetails;
  final String? profilePictureUrl; // Renamed from profileImage for consistency
  final double? averageRating;
  final int? totalRatings;
  // Add other fields like operationalHours, serviceAreas if needed

  Provider({
    required this.id,
    this.fullName,
    this.email,
    this.companyName,
    this.serviceType,
    this.serviceDescription,
    this.hourlyRate,
    this.location,
    this.contactInfo,
    this.availabilityDetails,
    this.profilePictureUrl,
    this.averageRating,
    this.totalRatings,
  });

  factory Provider.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }

    int? parseInt(dynamic value) {
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    return Provider(
      id: json['_id'] as String, // Assuming your API returns _id
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      companyName: json['companyName'] as String?,
      serviceType: json['serviceType'] as String?,
      // Use serviceDescription, fallback to description if it exists from older model versions
      serviceDescription: json['serviceDescription'] as String? ??
          json['description'] as String?,
      hourlyRate: parseDouble(json['hourlyRate']),
      location: json['location'] != null
          ? ProviderLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      contactInfo: json['contactInfo'] != null
          ? ProviderContactInfo.fromJson(
              json['contactInfo'] as Map<String, dynamic>)
          : null,
      availabilityDetails: json['availabilityDetails'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String? ??
          json['profileImage'] as String?, // Fallback
      averageRating: parseDouble(json['averageRating']),
      totalRatings: parseInt(json['totalRatings']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'companyName': companyName,
      'serviceType': serviceType,
      'serviceDescription': serviceDescription,
      'hourlyRate': hourlyRate,
      'location': location?.toJson(),
      'contactInfo': contactInfo?.toJson(),
      'availabilityDetails': availabilityDetails,
      'profilePictureUrl': profilePictureUrl,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
    };
  }
}
