# Technical Context: JO Service Marketplace

## Technology Stack Overview

### Backend Technologies
- **Runtime**: Node.js (v18+)
- **Framework**: Express.js (v4.18+)
- **Database**: MongoDB (v6.0+) with Mongoose ODM
- **Authentication**: JWT (jsonwebtoken v9.0+)
- **Real-time**: WebSocket (ws v8.0+)
- **File Upload**: Multer (v1.4+)
- **Documentation**: Swagger/OpenAPI (swagger-jsdoc v6.2+)
- **Environment**: dotenv (v16.0+)

### Frontend Technologies

#### Flutter App (Primary)
- **Framework**: Flutter (v3.16+)
- **Language**: Dart (v3.0+)
- **State Management**: Provider pattern
- **HTTP Client**: dart:http
- **Storage**: FlutterSecureStorage
- **Real-time**: WebSocket (web_socket_channel)
- **Maps**: Google Maps Flutter
- **Animations**: Lottie animations
- **Internationalization**: flutter_localizations

#### React Native App (Alternative)
- **Framework**: React Native (v0.72+)
- **Language**: JavaScript/TypeScript
- **State Management**: Context API with useReducer
- **HTTP Client**: Axios (v1.4+)
- **Storage**: AsyncStorage
- **Navigation**: React Navigation (v6.0+)
- **Animations**: React Native Animatable + Lottie

### Development Tools
- **Version Control**: Git
- **Package Managers**: npm (Node.js), pub (Flutter), yarn (React Native)
- **Code Quality**: ESLint, Prettier, Flutter Analysis
- **Testing**: Jest (React Native), Flutter Test
- **Documentation**: Swagger UI, README files

## Development Environment Setup

### Prerequisites
```bash
# Node.js and npm
node --version  # v18.0.0 or higher
npm --version   # v9.0.0 or higher

# Flutter
flutter --version  # v3.16.0 or higher
flutter doctor     # All checks should pass

# MongoDB
mongod --version  # v6.0.0 or higher

# Git
git --version     # v2.30.0 or higher
```

### Backend Setup
```bash
# Navigate to server directory
cd server/

# Install dependencies
npm install

# Environment configuration
cp .env.example .env
# Edit .env with your configuration

# Start development server
npm run dev
```

### Flutter App Setup
```bash
# Navigate to Flutter app directory
cd jo_service_app/

# Get dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on mobile
flutter run
```

### React Native App Setup
```bash
# Navigate to React Native app directory
cd mobile-app/

# Install dependencies
npm install

# Run on Android
npm run android

# Run on iOS
npm run ios
```

## Environment Configuration

### Backend Environment Variables (.env)
```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
MONGODB_URI=mongodb://localhost:27017/jo_service

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_here
JWT_EXPIRES_IN=7d

# File Upload Configuration
MAX_FILE_SIZE=5242880  # 5MB in bytes
UPLOAD_PATH=public/uploads

# WebSocket Configuration
WS_PORT=3001

# Admin Configuration
ADMIN_EMAIL=admin@joservice.com
ADMIN_PASSWORD=admin123
```

### Flutter Environment Configuration
```dart
// lib/constants/api_config.dart
class ApiConfig {
  static const String baseUrl = 'http://localhost:3000/api';
  static const String wsUrl = 'ws://localhost:3000';
  
  // Development
  static const String devBaseUrl = 'http://localhost:3000/api';
  static const String devWsUrl = 'ws://localhost:3000';
  
  // Production
  static const String prodBaseUrl = 'https://api.joservice.com/api';
  static const String prodWsUrl = 'wss://api.joservice.com';
}
```

### React Native Environment Configuration
```javascript
// src/config/constants.js
export const API_CONFIG = {
  BASE_URL: __DEV__ 
    ? 'http://localhost:3000/api'
    : 'https://api.joservice.com/api',
  
  WS_URL: __DEV__
    ? 'ws://localhost:3000'
    : 'wss://api.joservice.com',
};
```

## Database Schema

### MongoDB Collections

#### Users Collection
```javascript
{
  _id: ObjectId,
  email: String (unique, required),
  password: String (hashed, min 6 chars),
  fullName: String (required),
  phoneNumber: String,
  profilePictureUrl: String,
  createdAt: Date,
  updatedAt: Date
}
```

#### Providers Collection
```javascript
{
  _id: ObjectId,
  email: String (unique, required),
  password: String (hashed, min 6 chars),
  fullName: String (required),
  phoneNumber: String,
  profilePictureUrl: String,
  businessName: String,
  serviceType: String (required),
  serviceDescription: String,
  serviceCategory: String (enum),
  serviceTags: [String],
  hourlyRate: Number,
  location: {
    type: "Point",
    coordinates: [longitude, latitude],
    address: String,
    city: String,
    state: String,
    country: String,
    zipCode: String
  },
  serviceAreas: [String],
  availability: {
    monday: [String],
    tuesday: [String],
    wednesday: [String],
    thursday: [String],
    friday: [String],
    saturday: [String],
    sunday: [String]
  },
  averageRating: Number (0-5),
  totalRatings: Number,
  completedBookings: Number,
  isVerified: Boolean,
  verificationStatus: String (pending/verified/rejected),
  accountStatus: String (active/suspended/deactivated)
}
```

#### Bookings Collection
```javascript
{
  _id: ObjectId,
  user: ObjectId (ref: User),
  provider: ObjectId (ref: Provider),
  serviceDateTime: Date (required),
  serviceLocationDetails: String,
  userNotes: String,
  photos: [String], // URLs
  status: String (enum: pending/accepted/declined_by_provider/cancelled_by_user/in_progress/completed/payment_due/paid),
  createdAt: Date,
  updatedAt: Date
}
```

#### Messages Collection
```javascript
{
  _id: ObjectId,
  conversationId: String (composite key: sorted participant IDs),
  senderId: ObjectId (dynamic ref),
  senderType: String (User/Provider),
  recipientId: ObjectId (dynamic ref),
  recipientType: String (User/Provider),
  messageType: String (text/image/booking_images),
  text: String,
  images: [String],
  timestamp: Date,
  isRead: Boolean,
  readAt: Date
}
```

#### Ratings Collection
```javascript
{
  _id: ObjectId,
  booking: ObjectId (ref: Booking),
  user: ObjectId (ref: User),
  provider: ObjectId (ref: Provider),
  rating: Number (1-5),
  review: String,
  punctuality: Number (1-5),
  workQuality: Number (1-5),
  speedAndEfficiency: Number (1-5),
  cleanliness: Number (1-5),
  overallRating: Number (calculated from criteria)
}
```

#### Notifications Collection
```javascript
{
  _id: ObjectId,
  recipient: ObjectId (dynamic ref),
  recipientModel: String (User/Provider),
  type: String (booking_created/booking_accepted/etc),
  title: String,
  message: String,
  relatedBooking: ObjectId (optional),
  relatedMessage: ObjectId (optional),
  isRead: Boolean,
  createdAt: Date
}
```

## API Endpoints

### Authentication Routes
```
POST /api/auth/user/register     - User registration
POST /api/auth/user/login        - User login
POST /api/auth/provider/register - Provider registration
POST /api/auth/provider/login    - Provider login
```

### User Routes
```
GET  /api/users/me               - Get authenticated user profile
PUT  /api/users/me               - Update user profile
PUT  /api/users/me/profile-picture - Update profile picture
```

### Provider Routes
```
GET  /api/providers              - Get all providers (with filters)
GET  /api/providers/:id          - Get provider by ID
PUT  /api/providers/me           - Update provider profile
PUT  /api/providers/me/profile-picture - Update profile picture
```

### Booking Routes
```
POST   /api/bookings             - Create booking
GET    /api/bookings/user        - Get user's bookings
GET    /api/bookings/provider    - Get provider's bookings
GET    /api/bookings/:id         - Get booking details
PATCH  /api/bookings/:id/status  - Update booking status
```

### Chat Routes
```
GET  /api/chats                                  - Get user's conversations
POST /api/chats/conversations/:conversationId/messages - Send message
POST /api/chats/conversations/:conversationId/images   - Send image message
```

### Rating Routes
```
POST /api/ratings/provider              - Rate a provider
GET  /api/ratings/provider/:providerId  - Get provider ratings
```

### Notification Routes
```
GET    /api/notifications        - Get user notifications
PATCH  /api/notifications/:id/read - Mark notification as read
```

### Admin Routes
```
POST   /api/admin/login          - Admin login
GET    /api/admin/providers      - Get all providers for admin
PATCH  /api/admin/providers/:id/verify - Verify provider
PATCH  /api/admin/providers/:id/reject - Reject provider
GET    /api/admin/dashboard/stats - Get dashboard statistics
```

## Dependencies

### Backend Dependencies (package.json)
```json
{
  "dependencies": {
    "express": "^4.18.2",
    "mongoose": "^7.5.0",
    "jsonwebtoken": "^9.0.2",
    "bcryptjs": "^2.4.3",
    "multer": "^1.4.5-lts.1",
    "ws": "^8.13.0",
    "cors": "^2.8.5",
    "dotenv": "^16.3.1",
    "swagger-jsdoc": "^6.2.8",
    "swagger-ui-express": "^5.0.0",
    "express-rate-limit": "^6.10.0",
    "helmet": "^7.0.0"
  },
  "devDependencies": {
    "nodemon": "^3.0.1",
    "jest": "^29.6.2",
    "supertest": "^6.3.3"
  }
}
```

### Flutter Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  # State Management
  provider: ^6.0.5
  
  # HTTP and WebSocket
  http: ^1.1.0
  web_socket_channel: ^2.4.0
  
  # Storage
  flutter_secure_storage: ^8.0.0
  shared_preferences: ^2.2.0
  
  # UI Components
  google_maps_flutter: ^2.4.0
  lottie: ^2.6.0
  image_picker: ^1.0.2
  cached_network_image: ^3.2.3
  
  # Utilities
  intl: ^0.18.1
  geolocator: ^10.0.0
  permission_handler: ^10.4.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

### React Native Dependencies (package.json)
```json
{
  "dependencies": {
    "react": "18.2.0",
    "react-native": "0.72.4",
    "@react-navigation/native": "^6.1.7",
    "@react-navigation/stack": "^6.3.17",
    "axios": "^1.4.0",
    "react-native-vector-icons": "^10.0.0",
    "@react-native-async-storage/async-storage": "^1.19.3",
    "react-native-animatable": "^1.3.3",
    "lottie-react-native": "^5.1.6",
    "react-native-image-picker": "^5.6.0",
    "react-native-maps": "^1.7.1"
  },
  "devDependencies": {
    "@babel/core": "^7.20.0",
    "@babel/preset-env": "^7.20.0",
    "@babel/runtime": "^7.20.0",
    "@react-native/eslint-config": "^0.72.2",
    "@react-native/metro-config": "^0.72.11",
    "@tsconfig/react-native": "^3.0.0",
    "@types/react": "^18.0.24",
    "@types/react-test-renderer": "^18.0.0",
    "babel-jest": "^29.2.1",
    "eslint": "^8.19.0",
    "jest": "^29.2.1",
    "metro-react-native-babel-preset": "0.76.8",
    "prettier": "^2.4.1",
    "react-test-renderer": "18.2.0",
    "typescript": "4.8.4"
  }
}
```

## Technical Constraints

### Performance Constraints
- **API Response Time**: < 2 seconds for all endpoints
- **File Upload Size**: Maximum 5MB per file
- **Concurrent Users**: Support for 1000+ concurrent users
- **Database Queries**: Optimized with proper indexing

### Security Constraints
- **JWT Token Expiry**: 7 days with refresh mechanism
- **Password Requirements**: Minimum 6 characters, hashed with bcrypt
- **File Upload Validation**: Only image files allowed
- **Rate Limiting**: 100 requests per minute per IP
- **CORS Configuration**: Restricted to specific origins

### Scalability Constraints
- **Database**: MongoDB with proper indexing for geospatial queries
- **File Storage**: Local storage with potential for cloud migration
- **WebSocket Connections**: Connection pooling and cleanup
- **Caching**: No caching implemented (future enhancement)

### Platform Constraints
- **Flutter**: iOS 12+, Android API 21+
- **React Native**: iOS 12+, Android API 21+
- **Web**: Modern browsers with WebSocket support
- **Backend**: Node.js 18+ with Express 4.18+

## Development Workflow

### Code Quality Standards
- **Backend**: ESLint + Prettier configuration
- **Flutter**: Flutter Analysis with custom rules
- **React Native**: ESLint + Prettier configuration
- **Git Hooks**: Pre-commit hooks for code formatting

### Testing Strategy
- **Unit Tests**: Jest for backend, Flutter Test for Flutter
- **Integration Tests**: API endpoint testing with Supertest
- **UI Tests**: Widget tests for Flutter, Component tests for React Native
- **Manual Testing**: Cross-platform testing on real devices

### Deployment Strategy
- **Backend**: Node.js deployment with PM2 or Docker
- **Database**: MongoDB Atlas or self-hosted MongoDB
- **Frontend**: Flutter Web deployment, React Native app store deployment
- **File Storage**: Local storage with backup strategy

This technical context provides the foundation for understanding the technology stack, development environment, and technical constraints of the JO Service marketplace platform. 