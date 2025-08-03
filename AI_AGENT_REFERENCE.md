# AI Agent Reference: JO Service Marketplace

## Project Overview

**JO Service** is a comprehensive on-demand service marketplace that connects users who need services with service providers. The platform supports multiple client types (users, providers, and administrators) with real-time communication, booking management, and rating systems.

### Key Business Features:
- User registration and authentication for customers and service providers
- Service provider profiles with ratings, availability, and service details
- Booking system with multiple status states (pending → accepted → in_progress → completed)
- Real-time chat between users and providers
- Multi-criteria rating system for service quality assessment
- Admin dashboard for provider verification and system management
- Geolocation-based provider search and mapping
- Push notifications for booking updates
- File upload capabilities for profiles and service photos

---

## Architecture & Technology Stack

### Backend (Node.js/Express)
- **Framework**: Express.js with REST API architecture
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (JSON Web Tokens)
- **Real-time Communication**: WebSocket (ws library)
- **File Upload**: Multer middleware
- **Documentation**: Swagger/OpenAPI
- **Environment**: Node.js with dotenv configuration

### Frontend Applications

#### 1. Flutter App (`jo_service_app/`)
- **Primary mobile application** (iOS, Android, Web support)
- **State Management**: Provider pattern
- **HTTP Client**: dart:http
- **Real-time**: WebSocket connections
- **Storage**: FlutterSecureStorage for tokens
- **Maps**: Google Maps Flutter integration
- **Animations**: Lottie animations

#### 2. React Native App (`mobile-app/`)
- **Alternative mobile implementation**
- **Navigation**: React Navigation
- **State Management**: Context API with reducers
- **HTTP Client**: Axios
- **Storage**: AsyncStorage
- **Animations**: React Native Animatable + Lottie

---

## Database Models & Structure

### 1. User Model (`server/src/models/user.model.js`)
```javascript
{
  email: String (unique, required),
  password: String (hashed, min 6 chars),
  fullName: String (required),
  phoneNumber: String,
  profilePictureUrl: String,
  createdAt: Date,
  updatedAt: Date
}
```

### 2. Provider Model (`server/src/models/provider.model.js`)
```javascript
{
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
    // ... for each day
  },
  averageRating: Number (0-5),
  totalRatings: Number,
  completedBookings: Number,
  isVerified: Boolean,
  verificationStatus: String (pending/verified/rejected),
  accountStatus: String (active/suspended/deactivated)
}
```

### 3. Booking Model (`server/src/models/booking.model.js`)
```javascript
{
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

### 4. Message Model (`server/src/models/message.model.js`)
```javascript
{
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

### 5. Rating Model (`server/src/models/rating.model.js`)
```javascript
{
  booking: ObjectId (ref: Booking),
  user: ObjectId (ref: User),
  provider: ObjectId (ref: Provider),
  rating: Number (1-5),
  review: String,
  punctuality: Number (1-5),      // Multi-criteria ratings
  workQuality: Number (1-5),
  speedAndEfficiency: Number (1-5),
  cleanliness: Number (1-5),
  overallRating: Number (calculated from criteria)
}
```

### 6. Notification Model (`server/src/models/notification.model.js`)
```javascript
{
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

---

## API Endpoints & Routes

### Authentication Routes (`/api/auth`)
- `POST /user/register` - User registration
- `POST /user/login` - User login
- `POST /provider/register` - Provider registration
- `POST /provider/login` - Provider login

### User Routes (`/api/users`)
- `GET /me` - Get authenticated user profile
- `PUT /me` - Update user profile
- `PUT /me/profile-picture` - Update profile picture

### Provider Routes (`/api/providers`)
- `GET /` - Get all providers (with pagination, search, filters)
- `GET /:id` - Get provider by ID
- `PUT /me` - Update provider profile (provider auth)
- `PUT /me/profile-picture` - Update provider profile picture

### Booking Routes (`/api/bookings`)
- `POST /` - Create booking (user auth, with photo upload)
- `GET /user` - Get user's bookings
- `GET /provider` - Get provider's bookings
- `GET /:id` - Get booking details
- `PATCH /:id/status` - Update booking status

### Chat Routes (`/api/chats`)
- `GET /` - Get user's conversations
- `POST /conversations/:conversationId/messages` - Send message
- `POST /conversations/:conversationId/images` - Send image message

### Rating Routes (`/api/ratings`)
- `POST /provider` - Rate a provider after service completion
- `GET /provider/:providerId` - Get provider ratings

### Notification Routes (`/api/notifications`)
- `GET /` - Get user notifications
- `PATCH /:id/read` - Mark notification as read

### Admin Routes (`/api/admin`)
- `POST /login` - Admin login
- `GET /providers` - Get all providers for admin review
- `PATCH /providers/:id/verify` - Verify provider
- `PATCH /providers/:id/reject` - Reject provider
- `GET /dashboard/stats` - Get dashboard statistics

---

## Authentication & Authorization

### JWT Token Structure
```javascript
{
  id: user_or_provider_id,
  type: 'user' | 'provider' | 'admin',
  email: user_email,
  iat: issued_at,
  exp: expiration
}
```

### Middleware Chain
1. **`protectRoute`** - Validates JWT token
2. **`isUser`** - Ensures user type authentication
3. **`isProvider`** - Ensures provider type authentication

### Token Storage
- **Flutter**: FlutterSecureStorage
- **React Native**: AsyncStorage
- **Web**: LocalStorage (via secure storage wrapper)

---

## Key Features & Functionality

### 1. Booking System Workflow
```
User creates booking → Status: 'pending'
↓
Provider accepts/declines → Status: 'accepted' | 'declined_by_provider'
↓
Provider starts service → Status: 'in_progress'
↓
Provider completes → Status: 'completed'
↓
User can rate provider
```

### 2. Real-time Chat System
- WebSocket connections authenticated via JWT
- Conversation IDs generated from sorted participant IDs
- Support for text and image messages
- Real-time delivery to connected clients
- Message persistence in MongoDB

### 3. Provider Search & Filtering
- Geospatial queries using MongoDB 2dsphere indexes
- Filter by service category, rating, availability
- Search by name, service type, or location
- Pagination support for large datasets

### 4. Multi-criteria Rating System
- Punctuality (1-5 stars)
- Work Quality (1-5 stars)
- Speed & Efficiency (1-5 stars)
- Cleanliness (1-5 stars)
- Overall rating calculated as average
- Updates provider's average rating automatically

### 5. File Upload System
- Profile pictures stored in `/public/uploads/profile-pictures/`
- Service photos stored in `/public/uploads/`
- Multer middleware handles multipart/form-data
- File validation and size limits implemented

---

## Real-time Features (WebSocket)

### WebSocket Service (`server/src/services/websocket.service.js`)

#### Connection Flow:
1. Client connects with JWT token as query parameter
2. Server validates token and extracts user info
3. Connection stored with user ID and type mapping
4. Real-time message broadcasting enabled

#### Message Broadcasting:
- **Chat messages**: Sent to specific recipient if connected
- **Notifications**: Pushed to users for booking updates
- **Status updates**: Real-time booking status changes

#### Client Implementations:
- **Flutter**: `WebSocketChannel` with automatic reconnection
- **React Native**: WebSocket API with connection management

---

## Frontend Structure

### Flutter App Structure (`jo_service_app/`)

#### Key Directories:
- **`lib/screens/`** - UI screens for different user flows
- **`lib/services/`** - Business logic and API communication
- **`lib/models/`** - Data models for API responses
- **`lib/widgets/`** - Reusable UI components
- **`lib/constants/`** - Theme and configuration constants

#### Core Services:
- **`AuthService`** - Authentication state management
- **`ApiService`** - HTTP client configuration
- **`BookingService`** - Booking operations
- **`ChatService`** - WebSocket chat functionality
- **`BackgroundService`** - Push notifications
- **`ThemeService`** - UI theme management

#### Screen Categories:
- **Auth Screens**: Login, signup, role selection
- **User Screens**: Home, bookings, profile, chat
- **Provider Screens**: Dashboard, bookings, messages
- **Admin Screens**: Dashboard, provider management
- **Shared Screens**: Chat, booking details, rating

### React Native App Structure (`mobile-app/`)
- **`src/screens/`** - Screen components
- **`src/components/`** - Reusable UI components
- **`src/services/`** - API and business logic
- **`src/context/`** - React Context for state management
- **`src/navigation/`** - Navigation configuration

---

## Admin Dashboard

### Admin Authentication
- **Hardcoded credentials** (should be moved to database in production)
- **Email**: `admin@joservice.com`
- **Password**: `admin123`

### Admin Features:
1. **Provider Verification**
   - Review pending provider applications
   - Accept or reject with reasons
   - View provider details and documentation

2. **Dashboard Statistics**
   - Total users and providers
   - Provider status distribution
   - Service type analytics
   - Recent registrations tracking

3. **User Management**
   - View user statistics
   - Monitor system usage
   - Access user and provider data

---

## Development Setup

### Backend Setup
```bash
cd server/
npm install
npm run dev  # Starts with nodemon
```

### Flutter App Setup
```bash
cd jo_service_app/
flutter pub get
flutter run -d chrome  # For web
flutter run             # For mobile
```

### React Native Setup
```bash
cd mobile-app/
npm install
npm run android  # Android
npm run ios      # iOS
```

### Environment Variables (.env)
```
MONGODB_URI=mongodb://localhost:27017/jo_service
JWT_SECRET=your_jwt_secret_key
PORT=3000
```

---

## File Structure Overview

```
JO_service/
├── server/                 # Node.js backend
│   ├── src/
│   │   ├── controllers/    # Route handlers
│   │   ├── models/         # MongoDB schemas
│   │   ├── routes/         # API route definitions
│   │   ├── services/       # Business logic
│   │   ├── middlewares/    # Authentication, upload
│   │   └── config/         # Database, Swagger config
│   └── public/uploads/     # Static file storage
├── jo_service_app/         # Flutter app (primary)
│   ├── lib/
│   │   ├── screens/        # UI screens
│   │   ├── services/       # API and business logic
│   │   ├── models/         # Data models
│   │   └── widgets/        # Reusable components
│   └── assets/             # Images, animations
├── mobile-app/             # React Native app (alternative)
│   └── src/
│       ├── screens/        # Screen components
│       ├── services/       # API services
│       └── components/     # UI components
└── README.md              # Project documentation
```

---

## Critical Implementation Notes

### 1. Booking Status Flow
- Only users can create bookings (`pending` status)
- Only providers can accept/decline (`accepted`/`declined_by_provider`)
- Only providers can mark `in_progress` and `completed`
- Users can cancel only `pending` bookings

### 2. Chat System
- Conversation IDs are deterministic (sorted participant IDs)
- Messages support text and images
- WebSocket connections require authentication
- Message persistence ensures delivery reliability

### 3. Rating System
- Only completed bookings can be rated
- One rating per booking per user
- Multi-criteria ratings with overall calculation
- Provider averages updated automatically

### 4. File Upload Security
- File size limits enforced
- File type validation
- Secure file naming with timestamps
- Static file serving from public directory

### 5. Real-time Updates
- WebSocket for instant messaging
- Notification system for booking updates
- Background services for push notifications
- Automatic reconnection handling

---

## Common Development Patterns

### API Response Format
```javascript
// Success
{
  "success": true,
  "data": { /* response data */ },
  "message": "Operation successful"
}

// Error
{
  "success": false,
  "message": "Error description",
  "errors": [ /* validation errors */ ]
}
```

### Error Handling
- Try-catch blocks in all async operations
- Specific error messages for validation failures
- HTTP status codes following REST conventions
- Client-side error boundary implementations

### State Management
- **Flutter**: Provider pattern with ChangeNotifier
- **React Native**: Context API with useReducer
- **Backend**: Stateless design with JWT tokens

This reference document provides comprehensive coverage of the JO Service marketplace codebase. Use it to understand the system architecture, implement new features, debug issues, and maintain code consistency across the project. 