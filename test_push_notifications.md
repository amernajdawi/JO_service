# Push Notification Implementation Test Guide

## Backend Implementation ✅

### 1. Firebase Admin SDK Setup
- ✅ Installed `firebase-admin` package
- ✅ Created notification service with FCM integration
- ✅ Added FCM token fields to User and Provider models
- ✅ Added notification settings to user profiles

### 2. API Endpoints
- ✅ `PUT /api/notifications/fcm-token` - Update FCM token
- ✅ `DELETE /api/notifications/fcm-token` - Remove FCM token
- ✅ `GET /api/notifications/settings` - Get notification settings
- ✅ `PUT /api/notifications/settings` - Update notification settings
- ✅ `POST /api/notifications/test` - Send test notification

### 3. Integration with Booking System
- ✅ Booking status changes trigger push notifications
- ✅ Notifications sent to appropriate users/providers
- ✅ Notification content includes booking details

## Flutter Implementation ✅

### 1. Dependencies
- ✅ Added `firebase_core` and `firebase_messaging`
- ✅ Added `flutter_local_notifications` for local notifications

### 2. Push Notification Service
- ✅ Firebase initialization
- ✅ FCM token management
- ✅ Foreground message handling
- ✅ Background message handling
- ✅ Local notification display
- ✅ Notification settings management

### 3. UI Components
- ✅ Notification settings screen
- ✅ Integration with user profile
- ✅ Internationalization support (English/Arabic)

## Testing Steps

### 1. Backend Testing
```bash
# Start the server
cd server && npm run dev

# Test FCM token update
curl -X PUT http://localhost:3000/api/notifications/fcm-token \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"fcmToken": "test_token_123"}'

# Test notification settings
curl -X GET http://localhost:3000/api/notifications/settings \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"

# Test sending notification
curl -X POST http://localhost:3000/api/notifications/test \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### 2. Flutter Testing
```bash
# Start the Flutter app
cd jo_service_app && flutter run

# Navigate to:
# 1. User Profile Screen
# 2. Notification Settings
# 3. Send Test Notification
```

### 3. Firebase Setup (Required for Production)

1. **Create Firebase Project**
   - Go to Firebase Console
   - Create new project
   - Enable Cloud Messaging

2. **Add Android App**
   - Package name: `com.example.jo_service_app`
   - Download `google-services.json`
   - Place in `android/app/`

3. **Add iOS App**
   - Bundle ID: `com.example.joServiceApp`
   - Download `GoogleService-Info.plist`
   - Place in `ios/Runner/`

4. **Update Backend**
   - Add Firebase service account key
   - Update environment variables

## Current Status

### ✅ Completed
- Backend notification service
- FCM token management
- Notification settings API
- Flutter notification service
- UI for notification settings
- Integration with booking system
- Internationalization support

### 🔄 In Progress
- Firebase project setup
- Production configuration
- Testing on real devices

### 📋 Next Steps
1. Set up Firebase project
2. Configure Android/iOS apps
3. Test on physical devices
4. Deploy to production
5. Monitor notification delivery

## Environment Variables Needed

```env
# Backend (.env)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY=your-private-key
FIREBASE_CLIENT_EMAIL=your-client-email
```

## File Structure

```
server/
├── src/
│   ├── models/
│   │   ├── user.model.js (updated with FCM fields)
│   │   └── provider.model.js (updated with FCM fields)
│   ├── services/
│   │   └── notification.service.js (new)
│   └── routes/
│       └── notification.routes.js (new)

jo_service_app/
├── lib/
│   ├── services/
│   │   └── push_notification_service.dart (new)
│   └── screens/
│       └── notification_settings_screen.dart (new)
```

## API Documentation

### Notification Endpoints

#### Update FCM Token
```http
PUT /api/notifications/fcm-token
Authorization: Bearer <token>
Content-Type: application/json

{
  "fcmToken": "device_fcm_token_here"
}
```

#### Get Notification Settings
```http
GET /api/notifications/settings
Authorization: Bearer <token>
```

#### Update Notification Settings
```http
PUT /api/notifications/settings
Authorization: Bearer <token>
Content-Type: application/json

{
  "notificationSettings": {
    "bookingUpdates": true,
    "chatMessages": true,
    "ratings": true,
    "promotions": false
  }
}
```

#### Send Test Notification
```http
POST /api/notifications/test
Authorization: Bearer <token>
```

## Notification Types

1. **Booking Updates**
   - Booking created
   - Booking accepted/declined
   - Service started/completed

2. **Chat Messages**
   - New message received

3. **Ratings**
   - New rating received

4. **Promotions**
   - Special offers
   - Discount notifications

## Error Handling

- ✅ FCM token validation
- ✅ Network error handling
- ✅ Permission request handling
- ✅ Background message processing
- ✅ Notification settings validation

## Performance Considerations

- ✅ Async notification sending
- ✅ Token refresh handling
- ✅ Local notification caching
- ✅ Background processing
- ✅ Memory management

The push notification implementation is now complete and ready for testing! 