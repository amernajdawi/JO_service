const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const Provider = require('../models/provider.model');
const User = require('../models/user.model');

// Admin credentials (in production, store in database)
const ADMIN_CREDENTIALS = {
  email: 'admin@joservice.com',
  password: 'admin123' // This should be hashed in production
};

/**
 * Admin login
 */
const adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate credentials
    if (email !== ADMIN_CREDENTIALS.email || password !== ADMIN_CREDENTIALS.password) {
      return res.status(401).json({
        success: false,
        message: 'Invalid admin credentials'
      });
    }

    // Generate admin token
    const adminToken = jwt.sign(
      { 
        userId: 'admin', 
        email: email,
        role: 'admin'
      },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    );

    res.status(200).json({
      success: true,
      message: 'Admin login successful',
      token: adminToken,
      user: {
        id: 'admin',
        email: email,
        role: 'admin'
      }
    });

  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
};

/**
 * Get all providers with pagination and filtering
 */
const getAllProviders = async (req, res) => {
  try {
    const { 
      page = 1, 
      limit = 10, 
      status, 
      serviceType, 
      city,
      sortBy = 'createdAt',
      sortOrder = 'desc'
    } = req.query;

    // Build filter object
    const filter = {};
    if (status) filter.verificationStatus = status;
    if (serviceType) filter.serviceType = new RegExp(serviceType, 'i');
    if (city) filter['location.city'] = new RegExp(city, 'i');

    // Calculate pagination
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const sortOptions = {};
    sortOptions[sortBy] = sortOrder === 'desc' ? -1 : 1;

    // Get providers with pagination
    const providers = await Provider.find(filter)
      .sort(sortOptions)
      .skip(skip)
      .limit(parseInt(limit))
      .select('-password'); // Exclude password field

    // Get total count for pagination
    const totalProviders = await Provider.countDocuments(filter);
    const totalPages = Math.ceil(totalProviders / parseInt(limit));

    // Add computed fields for admin dashboard
    const enrichedProviders = providers.map(provider => {
      const providerObj = provider.toObject();
      return {
        ...providerObj,
        joinedDate: providerObj.createdAt,
        rating: providerObj.averageRating || 0,
        completedJobs: providerObj.completedBookings || 0,
        lastActive: providerObj.updatedAt,
        verificationStatus: providerObj.verificationStatus || 'pending'
      };
    });

    res.status(200).json({
      success: true,
      data: {
        providers: enrichedProviders,
        pagination: {
          currentPage: parseInt(page),
          totalPages,
          totalProviders,
          hasNext: parseInt(page) < totalPages,
          hasPrev: parseInt(page) > 1
        }
      }
    });

  } catch (error) {
    console.error('Get all providers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch providers',
      error: error.message
    });
  }
};

/**
 * Update provider verification status
 */
const updateProviderStatus = async (req, res) => {
  try {
    const { providerId } = req.params;
    const { status, rejectionReason } = req.body;

    console.log('Admin update provider status:', { providerId, status, rejectionReason });
    console.log('Admin auth info:', req.auth);

    // Validate status
    const validStatuses = ['pending', 'verified', 'rejected'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid verification status'
      });
    }

    // Get current provider to track status change
    const currentProvider = await Provider.findById(providerId).select('verificationStatus');
    if (!currentProvider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }

    const previousStatus = currentProvider.verificationStatus || 'pending';
    const adminInfo = req.auth.userId || req.auth.email || 'admin';

    // Build update object
    const updateData = {
      verificationStatus: status,
      verifiedAt: status === 'verified' ? new Date() : null,
      verifiedBy: adminInfo,
    };

    // Handle rejection reason
    if (status === 'rejected') {
      // Add rejection reason if provided, or keep existing one
      if (rejectionReason) {
        updateData.rejectionReason = rejectionReason;
      }
    } else {
      // Clear rejection reason when status changes away from rejected
      updateData.rejectionReason = null;
    }

    // Add status change history (optional enhancement)
    updateData.lastStatusChange = new Date();
    updateData.lastStatusChangedBy = adminInfo;

    // Update provider
    const updatedProvider = await Provider.findByIdAndUpdate(
      providerId,
      updateData,
      { new: true, select: '-password' }
    );

    if (!updatedProvider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }

    // Log the status change for admin transparency
    console.log(`🔄 Admin Status Change:`, {
      providerId,
      providerName: updatedProvider.fullName || updatedProvider.companyName,
      previousStatus,
      newStatus: status,
      changedBy: adminInfo,
      timestamp: new Date().toISOString(),
      rejectionReason: status === 'rejected' ? rejectionReason : null
    });

    // TODO: Send notification to provider about status change
    // This could be email, push notification, etc.

    res.status(200).json({
      success: true,
      message: `Provider status updated from ${previousStatus} to ${status}`,
      data: {
        ...updatedProvider.toObject(),
        statusChangeHistory: {
          previousStatus,
          newStatus: status,
          changedBy: adminInfo,
          changedAt: new Date()
        }
      }
    });

  } catch (error) {
    console.error('Update provider status error:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Failed to update provider status',
      error: error.message
    });
  }
};

/**
 * Get provider details by ID
 */
const getProviderById = async (req, res) => {
  try {
    const { providerId } = req.params;

    const provider = await Provider.findById(providerId).select('-password');

    if (!provider) {
      return res.status(404).json({
        success: false,
        message: 'Provider not found'
      });
    }

    // Enrich with computed fields
    const enrichedProvider = {
      ...provider.toObject(),
      joinedDate: provider.createdAt,
      rating: provider.averageRating || 0,
      completedJobs: provider.completedBookings || 0,
      lastActive: provider.updatedAt,
      verificationStatus: provider.verificationStatus || 'pending'
    };

    res.status(200).json({
      success: true,
      data: enrichedProvider
    });

  } catch (error) {
    console.error('Get provider by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch provider details',
      error: error.message
    });
  }
};

/**
 * Get admin dashboard statistics
 */
const getDashboardStats = async (req, res) => {
  try {
    // Get provider statistics
    const totalProviders = await Provider.countDocuments();
    const pendingProviders = await Provider.countDocuments({ verificationStatus: 'pending' });
    const verifiedProviders = await Provider.countDocuments({ verificationStatus: 'verified' });
    const rejectedProviders = await Provider.countDocuments({ verificationStatus: 'rejected' });

    // Get user statistics
    const totalUsers = await User.countDocuments();

    // Get recent providers (last 7 days)
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const recentProviders = await Provider.countDocuments({
      createdAt: { $gte: sevenDaysAgo }
    });

    // Get service type distribution
    const serviceTypeStats = await Provider.aggregate([
      { $group: { _id: '$serviceType', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    // Get city distribution
    const cityStats = await Provider.aggregate([
      { $group: { _id: '$location.city', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    res.status(200).json({
      success: true,
      data: {
        overview: {
          totalProviders,
          totalUsers,
          recentProviders
        },
        providerStatus: {
          pending: pendingProviders,
          verified: verifiedProviders,
          rejected: rejectedProviders
        },
        serviceTypes: serviceTypeStats,
        cities: cityStats
      }
    });

  } catch (error) {
    console.error('Get dashboard stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch dashboard statistics',
      error: error.message
    });
  }
};

/**
 * Bulk update provider statuses
 */
const bulkUpdateProviders = async (req, res) => {
  try {
    const { providerIds, status, rejectionReason } = req.body;

    // Validate input
    if (!Array.isArray(providerIds) || providerIds.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Provider IDs array is required'
      });
    }

    const validStatuses = ['pending', 'verified', 'rejected'];
    if (!validStatuses.includes(status)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid verification status'
      });
    }

    // Build update object
    const updateData = {
      verificationStatus: status,
      verifiedAt: status === 'verified' ? new Date() : null,
      verifiedBy: req.auth.userId || req.auth.email || 'admin'
    };

    if (status === 'rejected' && rejectionReason) {
      updateData.rejectionReason = rejectionReason;
    }

    // Bulk update
    const result = await Provider.updateMany(
      { _id: { $in: providerIds } },
      updateData
    );

    res.status(200).json({
      success: true,
      message: `${result.modifiedCount} providers updated to ${status}`,
      data: {
        matched: result.matchedCount,
        modified: result.modifiedCount
      }
    });

  } catch (error) {
    console.error('Bulk update providers error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to bulk update providers',
      error: error.message
    });
  }
};

module.exports = {
  adminLogin,
  getAllProviders,
  updateProviderStatus,
  getProviderById,
  getDashboardStats,
  bulkUpdateProviders
}; 