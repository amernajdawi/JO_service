const express = require('express');
const BookingController = require('../controllers/booking.controller');
const { protectRoute, isUser, isProvider } = require('../middlewares/auth.middleware');

const router = express.Router();

// POST /api/bookings - User creates a booking request
router.post('/', protectRoute, isUser, BookingController.createBooking);

// GET /api/bookings/user - Get bookings for the logged-in user
router.get('/user', protectRoute, isUser, BookingController.getBookingsForUser);

// GET /api/bookings/provider - Get bookings for the logged-in provider
router.get('/provider', protectRoute, isProvider, BookingController.getBookingsForProvider);

// GET /api/bookings/:id - Get a specific booking (user or provider)
// protectRoute ensures logged in, controller logic verifies ownership
router.get('/:id', protectRoute, BookingController.getBookingById);

// PATCH /api/bookings/:id/status - Update booking status (user or provider)
// protectRoute ensures logged in, controller logic verifies ownership and transition rules
router.patch('/:id/status', protectRoute, BookingController.updateBookingStatus);

module.exports = router; 