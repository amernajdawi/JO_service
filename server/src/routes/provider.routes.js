const express = require('express');
const ProviderController = require('../controllers/provider.controller');
const { protectRoute, isProvider } = require('../middlewares/auth.middleware');

const router = express.Router();

// GET /api/providers - List providers (accessible to any logged-in user or public)
// For now, it's public as protectRoute was removed for UI testing
router.get('/', ProviderController.getAllProviders);

// GET /api/providers/me - Authenticated provider gets their own profile
router.get('/me', protectRoute, isProvider, ProviderController.getMyProfile);

// GET /api/providers/:id - Get specific provider profile (accessible to any logged-in user)
// Consider if this also needs protectRoute or if it should be public
router.get('/:id', protectRoute, ProviderController.getProviderById);

// PUT /api/providers/me - Provider updates their own profile
router.put('/me', protectRoute, isProvider, ProviderController.updateMyProfile);

module.exports = router; 