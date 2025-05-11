const Booking = require('../models/booking.model');
const Provider = require('../models/provider.model');
const mongoose = require('mongoose');

const BookingController = {
    // POST /api/bookings - Create a new booking (by User)
    async createBooking(req, res) {
        const { providerId, serviceDateTime, serviceLocationDetails, userNotes } = req.body;
        const userId = req.auth.id; // Assuming protectRoute middleware adds auth object with user ID

        if (!providerId || !serviceDateTime) {
            return res.status(400).json({ message: 'Provider ID and service date/time are required.' });
        }

        try {
            // Optional: Check if provider exists
            const providerExists = await Provider.findById(providerId);
            if (!providerExists) {
                return res.status(404).json({ message: 'Provider not found.' });
            }

            const newBooking = new Booking({
                user: userId,
                provider: providerId,
                serviceDateTime,
                serviceLocationDetails,
                userNotes,
                status: 'pending' // Initial status
            });

            const savedBooking = await newBooking.save();

            // Populate user and provider details before sending response
            const populatedBooking = await Booking.findById(savedBooking._id)
                .populate('user', 'fullName email profilePictureUrl') // Select specific user fields
                .populate('provider', 'fullName email serviceType profilePictureUrl'); // Select provider fields

            res.status(201).json(populatedBooking);

        } catch (error) {
            console.error('Error creating booking:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation Error', errors: error.errors });
            }
            res.status(500).json({ message: 'Failed to create booking', error: error.message });
        }
    },

    // GET /api/bookings/user - Get bookings for the logged-in user
    async getBookingsForUser(req, res) {
        const userId = req.auth.id;
        const { status, page = 1, limit = 10 } = req.query; // Allow filtering by status

        try {
            const query = { user: userId };
            if (status) {
                query.status = status;
            }

            const options = {
                page: parseInt(page, 10),
                limit: parseInt(limit, 10),
                sort: { serviceDateTime: -1 }, // Sort by newest first
                populate: { 
                    path: 'provider', 
                    select: 'fullName email serviceType profilePictureUrl averageRating' 
                } // Populate provider details
            };
            
            // Mongoose-paginate-v2 or manual pagination
            // Manual example:
            const skip = (options.page - 1) * options.limit;
            const bookings = await Booking.find(query)
                .populate(options.populate)
                .sort(options.sort)
                .skip(skip)
                .limit(options.limit);
            
            const totalBookings = await Booking.countDocuments(query);

            res.status(200).json({ 
                bookings,
                currentPage: options.page,
                totalPages: Math.ceil(totalBookings / options.limit),
                totalBookings
            });

        } catch (error) {
            console.error('Error fetching user bookings:', error);
            res.status(500).json({ message: 'Failed to fetch bookings', error: error.message });
        }
    },

    // GET /api/bookings/provider - Get bookings for the logged-in provider
    async getBookingsForProvider(req, res) {
        const providerId = req.auth.id;
        const { status, page = 1, limit = 10 } = req.query;

        try {
            const query = { provider: providerId };
            if (status) {
                query.status = status;
            }

            const options = {
                page: parseInt(page, 10),
                limit: parseInt(limit, 10),
                sort: { serviceDateTime: -1 },
                populate: { path: 'user', select: 'fullName email profilePictureUrl' } // Populate user details
            };

            const skip = (options.page - 1) * options.limit;
            const bookings = await Booking.find(query)
                .populate(options.populate)
                .sort(options.sort)
                .skip(skip)
                .limit(options.limit);

            const totalBookings = await Booking.countDocuments(query);
            
            res.status(200).json({ 
                bookings,
                currentPage: options.page,
                totalPages: Math.ceil(totalBookings / options.limit),
                totalBookings
             });

        } catch (error) {
            console.error('Error fetching provider bookings:', error);
            res.status(500).json({ message: 'Failed to fetch bookings', error: error.message });
        }
    },

    // GET /api/bookings/:id - Get a single booking by ID
    async getBookingById(req, res) {
        const bookingId = req.params.id;
        const userId = req.auth.id;
        const userType = req.auth.type;

        if (!mongoose.Types.ObjectId.isValid(bookingId)) {
             return res.status(400).json({ message: 'Invalid Booking ID format' });
        }

        try {
            const booking = await Booking.findById(bookingId)
                .populate('user', 'fullName email')
                .populate('provider', 'fullName email serviceType');

            if (!booking) {
                return res.status(404).json({ message: 'Booking not found.' });
            }

            // Authorization check: Ensure user or provider owns the booking
            if (userType === 'user' && booking.user._id.toString() !== userId) {
                return res.status(403).json({ message: 'Forbidden: You do not own this booking.' });
            }
            if (userType === 'provider' && booking.provider._id.toString() !== userId) {
                 return res.status(403).json({ message: 'Forbidden: This booking is not assigned to you.' });
            }

            res.status(200).json(booking);

        } catch (error) {
            console.error('Error fetching booking by ID:', error);
            res.status(500).json({ message: 'Failed to fetch booking', error: error.message });
        }
    },

    // PATCH /api/bookings/:id/status - Update booking status
    async updateBookingStatus(req, res) {
        const bookingId = req.params.id;
        const { status } = req.body;
        const userId = req.auth.id;
        const userType = req.auth.type;

        if (!mongoose.Types.ObjectId.isValid(bookingId)) {
            return res.status(400).json({ message: 'Invalid Booking ID format' });
        }

        // Consider fetching allowed statuses from the model's enum definition
        const allowedStatuses = Booking.schema.path('status').enumValues;
        if (!status || !allowedStatuses.includes(status)) {
            return res.status(400).json({ message: `Invalid status provided. Allowed statuses: ${allowedStatuses.join(', ')}` });
        }

        try {
            // Find the booking first
            const booking = await Booking.findById(bookingId);
            if (!booking) {
                return res.status(404).json({ message: 'Booking not found.' });
            }

            // Authorization & State Transition Logic
            let canUpdate = false;
            const currentStatus = booking.status;

            if (userType === 'provider' && booking.provider.toString() === userId) {
                // Provider status transitions
                if (currentStatus === 'pending' && (status === 'accepted' || status === 'declined_by_provider')) canUpdate = true;
                else if (currentStatus === 'accepted' && status === 'in_progress') canUpdate = true;
                else if (currentStatus === 'in_progress' && status === 'completed') canUpdate = true;
                // Add more transitions if needed (e.g., accepted -> completed)
                 
            } else if (userType === 'user' && booking.user.toString() === userId) {
                // User status transitions
                if (currentStatus === 'pending' && status === 'cancelled_by_user') canUpdate = true;
                // Users might be able to cancel accepted bookings under certain conditions (e.g., >24h before service)
                // else if (currentStatus === 'accepted' && status === 'cancelled_by_user' && /* check time condition */) canUpdate = true;
            }

            if (!canUpdate) {
                return res.status(403).json({
                    message: `Forbidden: Cannot change status from ${currentStatus} to ${status} for your role.`
                });
            }

            // Update the status
            booking.status = status;
            const updatedBooking = await booking.save();

            // Populate details for the response
            const populatedBooking = await Booking.findById(updatedBooking._id)
                .populate('user', 'fullName email')
                .populate('provider', 'fullName email serviceType');

            res.status(200).json(populatedBooking);

        } catch (error) {
            console.error('Error updating booking status:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation Error', errors: error.errors });
            }
            res.status(500).json({ message: 'Failed to update booking status', error: error.message });
        }
    }
};

module.exports = BookingController; 