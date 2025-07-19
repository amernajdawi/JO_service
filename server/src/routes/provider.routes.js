const express = require('express');
const ProviderController = require('../controllers/provider.controller');
const { protectRoute, isProvider } = require('../middlewares/auth.middleware');
const upload = require('../middlewares/upload.middleware');

const router = express.Router();

// Public routes (no authentication required)
// GET /api/providers - Get all providers (with pagination)
router.get('/', ProviderController.getAllProviders);

// GET /api/providers/search - Search providers with filters
router.get('/search', ProviderController.searchProviders);

// GET /api/providers/nearby - Find providers near a location
router.get('/nearby', ProviderController.findNearbyProviders);

// GET /api/providers/categories - Get all service categories
router.get('/categories', ProviderController.getServiceCategories);

// Protected routes (authentication required)
// GET /api/providers/profile/me - Get the logged-in provider's profile
router.get('/profile/me', protectRoute, isProvider, ProviderController.getMyProfile);

// PATCH /api/providers/profile - Update the logged-in provider's profile
router.patch('/profile', protectRoute, isProvider, ProviderController.updateMyProfile);

// PATCH /api/providers/update-location - Update provider location
router.patch('/update-location', protectRoute, isProvider, ProviderController.updateLocation);

// PATCH /api/providers/update-services - Update provider services
router.patch('/update-services', protectRoute, isProvider, ProviderController.updateServices);

// POST /api/providers/profile-picture - Upload profile picture
router.post('/profile-picture', protectRoute, isProvider, upload.single('profilePicture'), ProviderController.uploadProfilePicture);

// GET /api/providers/:id - Get a specific provider by ID (must be last to avoid conflicts with specific routes)
router.get('/:id', ProviderController.getProviderById);

module.exports = router; 