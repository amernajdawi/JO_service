# System Patterns: JO Service Marketplace

## Architecture Overview

### High-Level Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Flutter App   │    │  React Native   │    │   Web Client    │
│   (Primary)     │    │   (Alternative) │    │   (Future)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Node.js API   │
                    │   (Express)     │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │    MongoDB      │
                    │   (Database)    │
                    └─────────────────┘
```

### Technology Stack

#### Backend (Node.js/Express)
- **Framework**: Express.js with REST API architecture
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT (JSON Web Tokens)
- **Real-time**: WebSocket (ws library)
- **File Upload**: Multer middleware
- **Documentation**: Swagger/OpenAPI
- **Environment**: Node.js with dotenv configuration

#### Frontend Applications
- **Primary**: Flutter app (iOS, Android, Web)
- **Alternative**: React Native app
- **State Management**: Provider pattern (Flutter) / Context API (React Native)
- **HTTP Client**: dart:http (Flutter) / Axios (React Native)
- **Storage**: FlutterSecureStorage / AsyncStorage

## Key Design Patterns

### 1. MVC Architecture (Backend)
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│    Routes       │    │   Controllers   │    │     Models      │
│  (API Endpoints)│    │ (Business Logic)│    │  (Data Schema)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │    Services     │
                    │ (Shared Logic)  │
                    └─────────────────┘
```

### 2. Provider Pattern (Flutter)
```dart
// State Management Pattern
class AuthService extends ChangeNotifier {
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  Future<void> login(String email, String password) async {
    // API call logic
    _currentUser = user;
    notifyListeners();
  }
}

// Usage in Widgets
Consumer<AuthService>(
  builder: (context, authService, child) {
    return authService.currentUser != null 
        ? HomeScreen() 
        : LoginScreen();
  },
)
```

### 3. Context API Pattern (React Native)
```javascript
// State Management Pattern
const AuthContext = createContext();

const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  
  const login = async (email, password) => {
    // API call logic
    setUser(user);
  };
  
  return (
    <AuthContext.Provider value={{ user, login }}>
      {children}
    </AuthContext.Provider>
  );
};

// Usage in Components
const { user, login } = useContext(AuthContext);
```

## Database Design Patterns

### 1. Document-Oriented Design (MongoDB)
```javascript
// User Document
{
  _id: ObjectId,
  email: String,
  password: String (hashed),
  fullName: String,
  phoneNumber: String,
  profilePictureUrl: String,
  createdAt: Date,
  updatedAt: Date
}

// Provider Document
{
  _id: ObjectId,
  email: String,
  password: String (hashed),
  fullName: String,
  businessName: String,
  serviceType: String,
  location: {
    type: "Point",
    coordinates: [longitude, latitude],
    address: String
  },
  availability: {
    monday: [String],
    tuesday: [String]
  },
  averageRating: Number,
  isVerified: Boolean
}
```

### 2. Referential Integrity Pattern
```javascript
// Booking with User and Provider References
{
  _id: ObjectId,
  user: ObjectId (ref: User),
  provider: ObjectId (ref: Provider),
  serviceDateTime: Date,
  status: String,
  createdAt: Date
}

// Rating with Booking Reference
{
  _id: ObjectId,
  booking: ObjectId (ref: Booking),
  user: ObjectId (ref: User),
  provider: ObjectId (ref: Provider),
  rating: Number,
  review: String
}
```

## API Design Patterns

### 1. RESTful API Structure
```
Authentication:
POST   /api/auth/user/register
POST   /api/auth/user/login
POST   /api/auth/provider/register
POST   /api/auth/provider/login

Users:
GET    /api/users/me
PUT    /api/users/me
PUT    /api/users/me/profile-picture

Providers:
GET    /api/providers
GET    /api/providers/:id
PUT    /api/providers/me
PUT    /api/providers/me/profile-picture

Bookings:
POST   /api/bookings
GET    /api/bookings/user
GET    /api/bookings/provider
GET    /api/bookings/:id
PATCH  /api/bookings/:id/status

Chat:
GET    /api/chats
POST   /api/chats/conversations/:conversationId/messages
POST   /api/chats/conversations/:conversationId/images

Ratings:
POST   /api/ratings/provider
GET    /api/ratings/provider/:providerId

Admin:
POST   /api/admin/login
GET    /api/admin/providers
PATCH  /api/admin/providers/:id/verify
PATCH  /api/admin/providers/:id/reject
```

### 2. Response Format Pattern
```javascript
// Success Response
{
  "success": true,
  "data": { /* response data */ },
  "message": "Operation successful"
}

// Error Response
{
  "success": false,
  "message": "Error description",
  "errors": [ /* validation errors */ ]
}
```

### 3. Middleware Chain Pattern
```javascript
// Authentication Middleware Chain
app.use('/api/providers', 
  protectRoute,    // Validate JWT token
  isProvider,      // Ensure provider type
  providerRoutes   // Route handlers
);

// File Upload Middleware
app.post('/api/bookings',
  protectRoute,    // Authentication
  upload.array('photos', 5),  // File upload
  validateBooking, // Validation
  createBooking    // Controller
);
```

## Real-time Communication Patterns

### 1. WebSocket Connection Pattern
```javascript
// Server-side WebSocket Service
class WebSocketService {
  constructor() {
    this.clients = new Map(); // userId -> WebSocket
  }
  
  handleConnection(ws, userId) {
    this.clients.set(userId, ws);
    
    ws.on('message', (data) => {
      this.handleMessage(userId, JSON.parse(data));
    });
    
    ws.on('close', () => {
      this.clients.delete(userId);
    });
  }
  
  broadcastToUser(userId, message) {
    const ws = this.clients.get(userId);
    if (ws) {
      ws.send(JSON.stringify(message));
    }
  }
}
```

### 2. Client-side WebSocket Pattern (Flutter)
```dart
class ChatService {
  WebSocketChannel? _channel;
  
  void connect(String token) {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://localhost:3000?token=$token'),
    );
    
    _channel!.stream.listen(
      (data) => handleMessage(data),
      onError: (error) => handleError(error),
      onDone: () => handleDisconnect(),
    );
  }
  
  void sendMessage(String message) {
    _channel?.sink.add(jsonEncode({
      'type': 'message',
      'content': message,
    }));
  }
}
```

## Authentication Patterns

### 1. JWT Token Pattern
```javascript
// Token Structure
{
  id: user_or_provider_id,
  type: 'user' | 'provider' | 'admin',
  email: user_email,
  iat: issued_at,
  exp: expiration
}

// Token Generation
const generateToken = (user, type) => {
  return jwt.sign(
    { id: user._id, type, email: user.email },
    process.env.JWT_SECRET,
    { expiresIn: '7d' }
  );
};

// Token Verification
const protectRoute = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ message: 'No token provided' });
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ message: 'Invalid token' });
  }
};
```

### 2. Role-Based Access Control
```javascript
// Role Middleware
const isUser = (req, res, next) => {
  if (req.user.type !== 'user') {
    return res.status(403).json({ message: 'User access required' });
  }
  next();
};

const isProvider = (req, res, next) => {
  if (req.user.type !== 'provider') {
    return res.status(403).json({ message: 'Provider access required' });
  }
  next();
};

const isAdmin = (req, res, next) => {
  if (req.user.type !== 'admin') {
    return res.status(403).json({ message: 'Admin access required' });
  }
  next();
};
```

## File Upload Patterns

### 1. Multer Configuration Pattern
```javascript
// File Upload Configuration
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, 'public/uploads/');
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, uniqueSuffix + '-' + file.originalname);
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Only image files are allowed'));
    }
  }
});
```

### 2. File Upload Route Pattern
```javascript
// Profile Picture Upload
app.put('/api/users/me/profile-picture',
  protectRoute,
  upload.single('profilePicture'),
  async (req, res) => {
    try {
      const user = await User.findByIdAndUpdate(
        req.user.id,
        { profilePictureUrl: `/uploads/${req.file.filename}` },
        { new: true }
      );
      
      res.json({
        success: true,
        data: user,
        message: 'Profile picture updated'
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        message: 'Failed to update profile picture'
      });
    }
  }
);
```

## Error Handling Patterns

### 1. Global Error Handler
```javascript
// Express Error Handler
app.use((error, req, res, next) => {
  console.error(error.stack);
  
  if (error.name === 'ValidationError') {
    return res.status(400).json({
      success: false,
      message: 'Validation error',
      errors: Object.values(error.errors).map(err => err.message)
    });
  }
  
  if (error.name === 'CastError') {
    return res.status(400).json({
      success: false,
      message: 'Invalid ID format'
    });
  }
  
  res.status(500).json({
    success: false,
    message: 'Internal server error'
  });
});
```

### 2. Async Error Wrapper
```javascript
// Async Error Handler
const asyncHandler = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};

// Usage
app.get('/api/providers', asyncHandler(async (req, res) => {
  const providers = await Provider.find();
  res.json({ success: true, data: providers });
}));
```

## Component Relationships

### 1. Service Layer Pattern
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Controllers   │    │     Services    │    │     Models      │
│  (Route Logic)  │    │ (Business Logic)│    │  (Data Access)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Utilities     │
                    │ (Shared Tools)  │
                    └─────────────────┘
```

### 2. Frontend Service Pattern (Flutter)
```dart
// Service Layer Structure
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  Future<Map<String, dynamic>> get(String endpoint) async {
    // HTTP GET logic
  }
  
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data) async {
    // HTTP POST logic
  }
}

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  Future<void> login(String email, String password) async {
    final response = await _apiService.post('/auth/user/login', {
      'email': email,
      'password': password
    });
    // Handle response
  }
}
```

## Database Query Patterns

### 1. Geospatial Queries
```javascript
// Find providers near location
const findNearbyProviders = async (longitude, latitude, maxDistance = 10000) => {
  return await Provider.find({
    location: {
      $near: {
        $geometry: {
          type: "Point",
          coordinates: [longitude, latitude]
        },
        $maxDistance: maxDistance
      }
    }
  });
};
```

### 2. Aggregation Patterns
```javascript
// Calculate average rating for provider
const calculateAverageRating = async (providerId) => {
  const result = await Rating.aggregate([
    { $match: { provider: ObjectId(providerId) } },
    { $group: {
      _id: null,
      averageRating: { $avg: "$rating" },
      totalRatings: { $sum: 1 }
    }}
  ]);
  
  return result[0] || { averageRating: 0, totalRatings: 0 };
};
```

### 3. Population Patterns
```javascript
// Get booking with populated user and provider
const getBookingWithDetails = async (bookingId) => {
  return await Booking.findById(bookingId)
    .populate('user', 'fullName email phoneNumber')
    .populate('provider', 'fullName businessName serviceType averageRating');
};
```

These system patterns provide the foundation for scalable, maintainable, and robust application development across the entire JO Service marketplace platform. 