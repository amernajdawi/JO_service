const express = require('express');
const router = express.Router();
const AdminController = require('../controllers/admin.controller');
const { protectRoute } = require('../middlewares/auth.middleware');

// Admin authentication routes
router.post('/login', AdminController.adminLogin);

// Admin dashboard routes (protected)
router.get('/dashboard/stats', protectRoute, AdminController.getDashboardStats);

// Provider management routes (protected)
router.get('/providers', protectRoute, AdminController.getAllProviders);
router.get('/providers/:providerId', protectRoute, AdminController.getProviderById);
router.put('/providers/:providerId/status', protectRoute, AdminController.updateProviderStatus);
router.put('/providers/bulk-update', protectRoute, AdminController.bulkUpdateProviders);

module.exports = router; 