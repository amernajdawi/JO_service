const Booking = require('../models/booking.model');
const Provider = require('../models/provider.model');
const mongoose = require('mongoose');
const NotificationService = require('../services/notification.service');

const BookingController = {
    // POST /api/bookings - Create a new booking (by User)
    async createBooking(req, res) {
        const { providerId, serviceDateTime, serviceLocationDetails, userNotes } = req.body;
        const userId = req.auth.id; // Assuming protectRoute middleware adds auth object with user ID
        
        console.log("Creating booking with userId:", userId);
        console.log("providerId:", providerId);
        console.log("serviceDateTime:", serviceDateTime);
        console.log("serviceLocationDetails:", serviceLocationDetails);
        console.log("userNotes:", userNotes);

        if (!providerId || !serviceDateTime) {
            return res.status(400).json({ message: 'Provider ID and service date/time are required.' });
        }

        try {
            // Optional: Check if provider exists
            const providerExists = await Provider.findById(providerId);
            if (!providerExists) {
                console.log("Provider not found for ID:", providerId);
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

            console.log("Saving new booking:", JSON.stringify(newBooking));
            const savedBooking = await newBooking.save();
            console.log("Booking saved with ID:", savedBooking._id);

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
        
        console.log("Getting bookings for user:", userId);
        console.log("User type:", req.auth.type);
        console.log("Query params:", { status, page, limit });

        try {
            // Verify the user ID is a valid MongoDB ObjectId
            if (!mongoose.Types.ObjectId.isValid(userId)) {
                console.log("Invalid user ID format:", userId);
                return res.status(400).json({ message: 'Invalid user ID format' });
            }

            // Create an ObjectId from the userId string for proper MongoDB comparison
            const userObjectId = new mongoose.Types.ObjectId(userId);
            console.log("User ObjectId:", userObjectId);
            
            // Query with the ObjectId
            const query = { user: userObjectId };
            if (status) {
                query.status = status;
            }
            
            console.log("MongoDB query:", JSON.stringify(query));

            const options = {
                page: parseInt(page, 10),
                limit: parseInt(limit, 10),
                sort: { serviceDateTime: -1 }, // Sort by newest first
                populate: { 
                    path: 'provider', 
                    select: 'fullName email serviceType profilePictureUrl averageRating' 
                } // Populate provider details
            };
            
            // Log the query we're about to execute
            console.log("Executing Booking.find with query:", query);
            
            const bookings = await Booking.find(query)
                .populate('user') // Fully populate user to debug
                .populate(options.populate)
                .sort(options.sort)
                .skip((options.page - 1) * options.limit)
                .limit(options.limit);
            
            const totalBookings = await Booking.countDocuments(query);
            
            console.log(`Found ${bookings.length} bookings with query out of ${totalBookings} total`);
            
            // Log the first booking to debug
            if (bookings.length > 0) {
                console.log("Sample booking from query:", JSON.stringify(bookings[0]));
            } else {
                // If no bookings found with direct query, try manual string comparison as fallback
                console.log("No bookings found with direct query, trying string comparison fallback");
                
                const allBookings = await Booking.find({})
                    .populate('user')
                    .populate(options.populate);
                    
                const matchingBookings = allBookings.filter(booking => 
                    booking.user && booking.user._id && booking.user._id.toString() === userId
                );
                
                console.log(`Found ${matchingBookings.length} bookings with string comparison fallback`);
                
                if (matchingBookings.length > 0) {
                    const limitedBookings = matchingBookings.slice((options.page - 1) * options.limit, options.page * options.limit);
                    
                    return res.status(200).json({ 
                        bookings: limitedBookings,
                        currentPage: options.page,
                        totalPages: Math.ceil(matchingBookings.length / options.limit),
                        totalBookings: matchingBookings.length
                    });
                }
            }

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

        console.log("Getting bookings for provider:", providerId);
        console.log("Provider type:", req.auth.type);
        console.log("Query params:", { status, page, limit });

        try {
            // Verify the provider ID is a valid MongoDB ObjectId
            if (!mongoose.Types.ObjectId.isValid(providerId)) {
                console.log("Invalid provider ID format:", providerId);
                return res.status(400).json({ message: 'Invalid provider ID format' });
            }

            // Create an ObjectId from the providerId string for proper MongoDB comparison
            const providerObjectId = new mongoose.Types.ObjectId(providerId);
            console.log("Provider ObjectId:", providerObjectId);
            
            // Query with the ObjectId
            const query = { provider: providerObjectId };
            if (status) {
                query.status = status;
            }
            
            console.log("MongoDB query for provider bookings:", JSON.stringify(query));

            const options = {
                page: parseInt(page, 10),
                limit: parseInt(limit, 10),
                sort: { serviceDateTime: -1 },
                populate: { path: 'user', select: 'fullName email profilePictureUrl' } // Populate user details
            };

            // Log the query we're about to execute
            console.log("Executing Booking.find with query:", query);
            
            const bookings = await Booking.find(query)
                .populate('provider') // Fully populate provider to debug
                .populate(options.populate)
                .sort(options.sort)
                .skip((options.page - 1) * options.limit)
                .limit(options.limit);

            const totalBookings = await Booking.countDocuments(query);
            
            console.log(`Found ${bookings.length} provider bookings with query out of ${totalBookings} total`);
            
            // Log the first booking to debug
            if (bookings.length > 0) {
                console.log("Sample provider booking from query:", JSON.stringify(bookings[0]));
            } else {
                // If no bookings found with direct query, try manual string comparison as fallback
                console.log("No provider bookings found with direct query, trying string comparison fallback");
                
                const allBookings = await Booking.find({})
                    .populate('provider')
                    .populate(options.populate);
                    
                const matchingBookings = allBookings.filter(booking => 
                    booking.provider && booking.provider._id && booking.provider._id.toString() === providerId
                );
                
                console.log(`Found ${matchingBookings.length} provider bookings with string comparison fallback`);
                
                if (matchingBookings.length > 0) {
                    const limitedBookings = matchingBookings.slice((options.page - 1) * options.limit, options.page * options.limit);
                    
                    return res.status(200).json({ 
                        bookings: limitedBookings,
                        currentPage: options.page,
                        totalPages: Math.ceil(matchingBookings.length / options.limit),
                        totalBookings: matchingBookings.length
                    });
                }
            }
            
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

        console.log(`Getting booking by ID: ${bookingId}`);
        console.log(`User ID: ${userId}, User type: ${userType}`);

        if (!mongoose.Types.ObjectId.isValid(bookingId)) {
             return res.status(400).json({ message: 'Invalid Booking ID format' });
        }

        try {
            const booking = await Booking.findById(bookingId)
                .populate('user', 'fullName email profilePictureUrl')
                .populate('provider', 'fullName email serviceType profilePictureUrl averageRating');

            if (!booking) {
                console.log(`Booking not found: ${bookingId}`);
                return res.status(404).json({ message: 'Booking not found.' });
            }

            console.log(`Found booking: ${booking._id}`);
            console.log(`Provider ID: ${booking.provider._id}`);
            console.log(`User ID: ${booking.user._id}`);

            // TEMPORARY DEBUG OVERRIDE - allow any provider to view any booking (for testing only)
            const isDebugModeEnabled = true; // Set this to false in production!
            
            if (isDebugModeEnabled && userType === 'provider') {
                console.log('⚠️ DEBUG MODE ENABLED: Bypassing provider ID check for viewing booking details');
                // No authorization check needed, allow access
            }
            // Normal authorization checks when debug mode is disabled
            else {
                // Authorization check: Ensure user or provider owns the booking
                if (userType === 'user' && booking.user._id.toString() !== userId) {
                    console.log(`User ${userId} doesn't own this booking`);
                    return res.status(403).json({ message: 'Forbidden: You do not own this booking.' });
                }
                if (userType === 'provider' && booking.provider._id.toString() !== userId) {
                    console.log(`Provider ${userId} is not assigned to this booking`);
                    return res.status(403).json({ message: 'Forbidden: This booking is not assigned to you.' });
                }
            }

            console.log('Returning booking details');
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

        console.log(`Updating booking ${bookingId} status to ${status}`);
        console.log(`User ID: ${userId}, User type: ${userType}`);

        if (!mongoose.Types.ObjectId.isValid(bookingId)) {
            return res.status(400).json({ message: 'Invalid Booking ID format' });
        }

        // Consider fetching allowed statuses from the model's enum definition
        const allowedStatuses = Booking.schema.path('status').enumValues;
        if (!status || !allowedStatuses.includes(status)) {
            return res.status(400).json({ message: `Invalid status provided. Allowed statuses: ${allowedStatuses.join(', ')}` });
        }

        try {
            // Find the booking and populate user and provider
            const booking = await Booking.findById(bookingId)
                .populate('user')
                .populate('provider');
                
            if (!booking) {
                return res.status(404).json({ message: 'Booking not found.' });
            }

            console.log(`Found booking: ${booking._id}`);
            console.log(`Current status: ${booking.status}`);
            console.log(`Provider ID: ${booking.provider._id}`);
            console.log(`User ID: ${booking.user._id}`);

            // Authorization & State Transition Logic
            let canUpdate = false;
            const currentStatus = booking.status;

            // Convert all IDs to strings for comparison
            const bookingProviderId = booking.provider._id.toString();
            const bookingUserId = booking.user._id.toString();
            const requestUserId = userId.toString();

            console.log(`Comparing provider IDs: ${bookingProviderId} vs ${requestUserId}`);
            console.log(`Comparing user IDs: ${bookingUserId} vs ${requestUserId}`);

            // TEMPORARY DEBUG OVERRIDE - allow any provider to update status (for testing only)
            const isDebugModeEnabled = true; // Set this to false in production!
            
            if (isDebugModeEnabled && userType === 'provider') {
                console.log('⚠️ DEBUG MODE ENABLED: Bypassing provider ID check');
                
                // Provider status transitions in debug mode - allow any provider to update
                if (currentStatus === 'pending' && (status === 'accepted' || status === 'declined_by_provider')) {
                    console.log('DEBUG: Provider can accept or decline a pending booking');
                    canUpdate = true;
                }
                else if (currentStatus === 'accepted' && status === 'in_progress') {
                    console.log('DEBUG: Provider can mark an accepted booking as in progress');
                    canUpdate = true;
                }
                else if (currentStatus === 'in_progress' && status === 'completed') {
                    console.log('DEBUG: Provider can mark an in-progress booking as completed');
                    canUpdate = true;
                }
            }
            // Normal authorization checks when debug mode is disabled
            else if (userType === 'provider' && bookingProviderId === requestUserId) {
                console.log('User is the provider for this booking');
                // Provider status transitions
                if (currentStatus === 'pending' && (status === 'accepted' || status === 'declined_by_provider')) {
                    console.log('Provider can accept or decline a pending booking');
                    canUpdate = true;
                }
                else if (currentStatus === 'accepted' && status === 'in_progress') {
                    console.log('Provider can mark an accepted booking as in progress');
                    canUpdate = true;
                }
                else if (currentStatus === 'in_progress' && status === 'completed') {
                    console.log('Provider can mark an in-progress booking as completed');
                    canUpdate = true;
                }
                // Add more transitions if needed (e.g., accepted -> completed)
                 
            } else if (userType === 'user' && bookingUserId === requestUserId) {
                console.log('User is the client for this booking');
                // User status transitions
                if (currentStatus === 'pending' && status === 'cancelled_by_user') {
                    console.log('User can cancel a pending booking');
                    canUpdate = true;
                }
                else if (currentStatus === 'accepted' && status === 'cancelled_by_user') {
                    console.log('User can cancel an accepted booking');
                    canUpdate = true;
                }
                // Users might be able to cancel accepted bookings under certain conditions (e.g., >24h before service)
                // else if (currentStatus === 'accepted' && status === 'cancelled_by_user' && /* check time condition */) canUpdate = true;
            }

            console.log(`Can update status? ${canUpdate}`);

            if (!canUpdate) {
                return res.status(403).json({
                    message: `Forbidden: Cannot change status from ${currentStatus} to ${status} for your role.`
                });
            }

            // Update the status
            booking.status = status;
            const updatedBooking = await booking.save();

            console.log(`Successfully updated booking status to ${status}`);

            // Send notification about the status change
            await NotificationService.sendBookingStatusNotification(
                booking,
                status,
                userType
            );

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
    },

    // Add a test method to fetch all bookings (temporary, for debugging)
    async getAllBookingsForTest(req, res) {
        try {
            console.log('TEST: Fetching all bookings for debugging');
            
            // Fetch all bookings with populated references
            const bookings = await Booking.find({})
                .populate('user', 'fullName email profilePictureUrl')
                .populate('provider', 'fullName email serviceType profilePictureUrl')
                .sort({ serviceDateTime: -1 });
            
            console.log(`TEST: Found ${bookings.length} bookings in total`);
            
            if (bookings.length > 0) {
                console.log('TEST: Sample booking:', JSON.stringify(bookings[0]));
            }
            
            res.status(200).json({ 
                bookings,
                totalBookings: bookings.length
            });
        } catch (error) {
            console.error('TEST: Error fetching all bookings:', error);
            res.status(500).json({ message: 'Failed to fetch all bookings', error: error.message });
        }
    },

    // GET /api/bookings/by-user/:userId - Get bookings for a specific user ID (temporary debug endpoint)
    async getBookingsByUserId(req, res) {
        try {
            const userId = req.params.userId;
            console.log('DEBUG: Explicitly fetching bookings for user ID:', userId);
            
            if (!mongoose.Types.ObjectId.isValid(userId)) {
                return res.status(400).json({ message: 'Invalid user ID format' });
            }
            
            // Directly query by userId as a string to bypass any ObjectId issues
            const bookings = await Booking.find({})
                .populate('user')
                .populate('provider', 'fullName email serviceType profilePictureUrl');
            
            // Filter manually after populating to ensure correct string comparison
            const filteredBookings = bookings.filter(booking => 
                booking.user && booking.user._id && booking.user._id.toString() === userId
            );
            
            console.log(`DEBUG: Found ${filteredBookings.length} bookings for user ${userId}`);
            
            if (filteredBookings.length > 0) {
                console.log('DEBUG: First booking:', JSON.stringify(filteredBookings[0]));
            }
            
            res.status(200).json({ 
                bookings: filteredBookings,
                totalBookings: filteredBookings.length
            });
        } catch (error) {
            console.error('Error in getBookingsByUserId:', error);
            res.status(500).json({ message: 'Failed to fetch bookings by user ID', error: error.message });
        }
    },

    // GET /api/bookings/by-provider/:providerId - Get bookings for a specific provider ID (temporary debug endpoint)
    async getBookingsByProviderId(req, res) {
        try {
            const providerId = req.params.providerId;
            console.log('DEBUG: Explicitly fetching bookings for provider ID:', providerId);
            
            if (!mongoose.Types.ObjectId.isValid(providerId)) {
                return res.status(400).json({ message: 'Invalid provider ID format' });
            }
            
            // Create an ObjectId from the provider ID string for proper MongoDB comparison
            const providerObjectId = new mongoose.Types.ObjectId(providerId);
            console.log("Provider ObjectId:", providerObjectId);
            
            // Query with the ObjectId
            const query = { provider: providerObjectId };
            console.log("MongoDB query for provider bookings:", JSON.stringify(query));
            
            // Directly query by providerId 
            const bookings = await Booking.find(query)
                .populate('user', 'fullName email profilePictureUrl')
                .populate('provider')
                .sort({ serviceDateTime: -1 });
            
            console.log(`DEBUG: Found ${bookings.length} bookings for provider ${providerId}`);
            
            if (bookings.length > 0) {
                console.log('DEBUG: First provider booking:', JSON.stringify(bookings[0]));
            }
            
            res.status(200).json({ 
                bookings,
                totalBookings: bookings.length
            });
        } catch (error) {
            console.error('Error in getBookingsByProviderId:', error);
            res.status(500).json({ message: 'Failed to fetch bookings by provider ID', error: error.message });
        }
    },

    // PATCH /api/bookings/:id/reassign - Reassign a booking to a different provider (debugging)
    async reassignBooking(req, res) {
        const bookingId = req.params.id;
        const { providerId } = req.body;
        
        console.log(`DEBUG: Reassigning booking ${bookingId} to provider ${providerId}`);
        
        if (!mongoose.Types.ObjectId.isValid(bookingId)) {
            return res.status(400).json({ message: 'Invalid Booking ID format' });
        }
        
        if (!mongoose.Types.ObjectId.isValid(providerId)) {
            return res.status(400).json({ message: 'Invalid Provider ID format' });
        }
        
        try {
            // Verify the provider exists
            const providerExists = await Provider.findById(providerId);
            if (!providerExists) {
                console.log(`Provider with ID ${providerId} not found`);
                return res.status(404).json({ message: 'Provider not found.' });
            }
            
            // Find the booking
            const booking = await Booking.findById(bookingId);
            if (!booking) {
                return res.status(404).json({ message: 'Booking not found.' });
            }
            
            // Update the provider field
            const originalProvider = booking.provider;
            booking.provider = providerId;
            
            // Save the updated booking
            const updatedBooking = await booking.save();
            
            console.log(`Booking ${bookingId} reassigned from ${originalProvider} to ${providerId}`);
            
            // Populate details for the response
            const populatedBooking = await Booking.findById(updatedBooking._id)
                .populate('user', 'fullName email')
                .populate('provider', 'fullName email serviceType');
            
            res.status(200).json(populatedBooking);
            
        } catch (error) {
            console.error('Error reassigning booking:', error);
            res.status(500).json({ message: 'Failed to reassign booking', error: error.message });
        }
    }
};

module.exports = BookingController; 