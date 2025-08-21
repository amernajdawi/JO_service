class ApiConfig {
  // Production backend URL
  static const String productionBaseUrl = 'https://joservicebackend-production.up.railway.app';
  
  // API endpoints
  static const String apiBaseUrl = '$productionBaseUrl/api';
  
  // WebSocket endpoints
  static const String wsBaseUrl = 'wss://joservicebackend-production.up.railway.app';
  
  // File uploads
  static const String uploadsBaseUrl = '$productionBaseUrl/uploads';
  
  // Profile pictures
  static const String profilePicturesBaseUrl = '$productionBaseUrl/uploads/profile-pictures';
}
