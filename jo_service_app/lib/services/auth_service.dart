import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import './api_service.dart'; // To use getBaseUrl
import 'package:flutter/material.dart'; // Added for ChangeNotifier

// UserInfo class to hold basic user details after login
class UserInfo {
  final String id;
  final String email;
  final String fullName;
  // Add other fields you might want to store globally, e.g., profilePictureUrl

  UserInfo({required this.id, required this.email, required this.fullName});

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['_id'] ?? json['id'] as String, // Handle both _id and id
      email: json['email'] as String,
      fullName: json['fullName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
    };
  }
}

class AuthService with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final String _authBaseUrl = "${ApiService.getBaseUrl()}/auth";

  // Using more specific keys for clarity with new _saveAuthData logic
  static const String _tokenKey = 'auth_token_key';
  static const String _userTypeKey = 'user_type_key';
  static const String _userInfoKey = 'user_info_key';

  String? _token;
  String? _userType;
  UserInfo? _userInfo;
  bool _isAuthenticated = false;
  bool _isLoading =
      true; // Start with loading true until _loadAuthData completes

  String? get token => _token;
  String? get userType => _userType;
  UserInfo? get userInfo => _userInfo;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthService() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    _token = await _storage.read(key: _tokenKey);
    _userType = await _storage.read(key: _userTypeKey);
    final userInfoString = await _storage.read(key: _userInfoKey);
    if (userInfoString != null) {
      try {
        _userInfo = UserInfo.fromJson(json.decode(userInfoString));
      } catch (e) {
        print("Error decoding user info from storage: $e");
        await _storage.delete(key: _userInfoKey); // Clear corrupted data
      }
    }
    _isAuthenticated = _token != null &&
        _token!.isNotEmpty &&
        _userType != null &&
        _userType!.isNotEmpty;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveAuthData(
      String token, String userType, UserInfo userInfo) async {
    _isLoading = true;
    notifyListeners(); // Notify UI that an auth operation is starting

    _token = token;
    _userType = userType;
    _userInfo = userInfo;
    _isAuthenticated = true;

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _userTypeKey, value: userType);
    await _storage.write(
        key: _userInfoKey, value: json.encode(userInfo.toJson()));

    _isLoading = false;
    notifyListeners(); // Notify UI that auth operation completed and state updated
  }

  Future<void> clearAuthData() async {
    _isLoading = true;
    notifyListeners();

    _token = null;
    _userType = null;
    _userInfo = null;
    _isAuthenticated = false;

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userTypeKey);
    await _storage.delete(key: _userInfoKey);

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> getToken() async {
    return _token; // Return loaded token, no need to read from storage again if loaded
  }

  Future<String?> getUserType() async {
    return _userType; // Return loaded user type
  }

  Future<String?> getUserId() async {
    return _userInfo?.id; // Return loaded user ID
  }

  Future<Map<String, dynamic>> registerProvider({
    required String email,
    required String password,
    String? fullName,
    String? companyName, // Added for provider registration
    required String serviceType,
    String? hourlyRate, // Added hourlyRate parameter (as String)
    String? city, // Added city parameter
    String? addressText, // Added addressText parameter
    // Add other fields as necessary from your Provider model & backend controller
    // e.g., hourlyRate, locationLatitude, locationLongitude, addressText, etc.
  }) async {
    final response = await http.post(
      Uri.parse('$_authBaseUrl/provider/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'password': password,
        'fullName': fullName,
        'companyName': companyName, // Added
        'serviceType': serviceType,
        'hourlyRate': hourlyRate, // Added hourlyRate to JSON body
        'city': city, // Add city to JSON body
        'addressText': addressText, // Add addressText to JSON body
        // Populate other fields here
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 201 && responseData['token'] != null) {
      await _saveAuthData(
          responseData['token'],
          'provider',
          UserInfo(
              id: responseData['provider']['_id'],
              email: email,
              fullName: fullName ?? ''));
      return responseData; // Contains provider and token
    } else {
      throw Exception(responseData['message'] ?? 'Failed to register provider');
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    String? fullName,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$_authBaseUrl/user/register'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'profilePictureUrl': profilePictureUrl,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 201 && responseData['token'] != null) {
      await _saveAuthData(
          responseData['token'],
          'user',
          UserInfo(
              id: responseData['user']['_id'],
              email: email,
              fullName: fullName ?? ''));
      return responseData; // Contains user and token
    } else {
      throw Exception(responseData['message'] ?? 'Failed to register user');
    }
  }

  Future<Map<String, dynamic>> loginUser(
      {required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$_authBaseUrl/user/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200 && responseData['token'] != null) {
      await _saveAuthData(
          responseData['token'],
          'user',
          UserInfo(
              id: responseData['user']['_id'],
              email: email,
              fullName: responseData['user']['fullName']));
      return responseData; // Contains user and token
    } else {
      throw Exception(responseData['message'] ?? 'Failed to login user');
    }
  }

  Future<Map<String, dynamic>> loginProvider(
      {required String email, required String password}) async {
    final response = await http.post(
      Uri.parse('$_authBaseUrl/provider/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    final responseData = json.decode(response.body);
    if (response.statusCode == 200 && responseData['token'] != null) {
      await _saveAuthData(
          responseData['token'],
          'provider',
          UserInfo(
              id: responseData['provider']['_id'],
              email: email,
              fullName: responseData['provider']['fullName']));
      return responseData; // Contains provider and token
    } else {
      throw Exception(responseData['message'] ?? 'Failed to login provider');
    }
  }

  Future<void> logout() async {
    await clearAuthData();
    // _isLoading and notifyListeners are handled in clearAuthData
  }
}
