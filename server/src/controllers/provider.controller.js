const Provider = require('../models/provider.model');
const mongoose = require('mongoose');

const ProviderController = {

    // GET /api/providers - Get list of providers with filtering and pagination
    async getAllProviders(req, res) {
        const { serviceType, page = 1, limit = 10, // Basic filters
                minRating, // Optional filters
                // Geospatial filter params (example)
                longitude, latitude, maxDistance // distance in meters
              } = req.query;
        
        try {
            const query = {};
            const options = {
                page: parseInt(page, 10),
                limit: parseInt(limit, 10),
                sort: { averageRating: -1, totalRatings: -1 }, // Sort by rating, then number of ratings
                // Exclude sensitive fields like password (already excluded by select: false in schema)
                select: '-password' // Double ensure password isn't selected
                // We can add .populate() here later if needed (e.g., recent reviews)
            };

            // Apply Filters
            if (serviceType) {
                // Case-insensitive search for service type
                query.serviceType = { $regex: new RegExp(`^${serviceType}$`, 'i') };
            }
            if (minRating) {
                const rating = parseFloat(minRating);
                if (!isNaN(rating)) {
                    query.averageRating = { $gte: rating };
                }
            }

            // Geospatial Filter (if coordinates provided)
            if (longitude != null && latitude != null) {
                const lon = parseFloat(longitude);
                const lat = parseFloat(latitude);
                const dist = maxDistance ? parseFloat(maxDistance) : 10000; // Default 10km

                if (!isNaN(lon) && !isNaN(lat)) {
                    query['location.point'] = {
                        $nearSphere: {
                            $geometry: {
                                type: "Point",
                                coordinates: [lon, lat]
                            },
                            $maxDistance: dist // in meters
                        }
                    };
                    // Note: Sorting by distance might override the rating sort.
                    // If sorting by distance is desired, adjust the `sort` option or handle separately.
                }
            }

            // TODO: Add filter for availability (more complex, depends on availabilityDetails format)

            // Query using pagination (manual approach shown, mongoose-paginate-v2 is an alternative)
            const skip = (options.page - 1) * options.limit;
            const providers = await Provider.find(query)
                                      .sort(options.sort)
                                      .select(options.select)
                                      .skip(skip)
                                      .limit(options.limit);

            const totalProviders = await Provider.countDocuments(query);
            
            res.status(200).json({
                providers,
                currentPage: options.page,
                totalPages: Math.ceil(totalProviders / options.limit),
                totalProviders
            });

        } catch (error) {
            console.error('Error fetching providers:', error);
            res.status(500).json({ message: 'Failed to fetch providers', error: error.message });
        }
    },

    // GET /api/providers/:id - Get a single provider's public profile
    async getProviderById(req, res) {
        const { id } = req.params;

        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({ message: 'Invalid Provider ID format' });
        }

        try {
            // Exclude password explicitly if not done by schema
            const provider = await Provider.findById(id).select('-password'); 
            
            if (!provider) {
                return res.status(404).json({ message: 'Provider not found.' });
            }

            // Return public profile data
            res.status(200).json(provider);

        } catch (error) {
            console.error('Error fetching provider by ID:', error);
            res.status(500).json({ message: 'Failed to fetch provider profile', error: error.message });
        }
    },

    // PUT /api/providers/me - Update authenticated provider's profile
    async updateMyProfile(req, res) {
        const providerId = req.auth.id; // Corrected from req.user.id to req.auth.id
        const updateData = req.body;

        // Fields that a provider can update (whitelist to prevent unwanted updates)
        const allowedUpdates = [
            'fullName',
            'companyName', 
            'contactInfo', 
            'location',
            'serviceType', 
            'serviceDescription',
            'availabilityDetails',
            'operationalHours',
            'serviceAreas', // Assuming this is an array of strings or objects
            'profilePictureUrl',
            'bannerImage',
            'hourlyRate',
            // 'location' can be complex, might need separate handling or more specific fields
        ];

        const updates = {};
        for (const key of Object.keys(updateData)) {
            if (allowedUpdates.includes(key)) {
                // Ensure hourlyRate is stored as a number if provided
                if (key === 'hourlyRate') {
                    const rate = parseFloat(updateData[key]);
                    if (!isNaN(rate)) {
                        updates[key] = rate;
                    }
                } else {
                    updates[key] = updateData[key];
                }
            }
        }
        
        // Prevent password updates through this route
        if (updates.password) {
            delete updates.password;
        }
        // Location updates require specific handling if using GeoJSON
        // For now, we'll assume 'location.coordinates' and 'location.addressText' might be passed
        // and need to be structured correctly if we are to update 'location.point'
        if (updateData.location) {
            updates.location = {}; // Clear existing location to rebuild it carefully
            if (updateData.location.addressText) {
                updates.location.addressText = updateData.location.addressText;
            }
            // IMPORTANT: If coordinates are provided, they must be in [longitude, latitude] order
            if (Array.isArray(updateData.location.coordinates) && 
                updateData.location.coordinates.length === 2 &&
                typeof updateData.location.coordinates[0] === 'number' &&
                typeof updateData.location.coordinates[1] === 'number'
            ) {
                updates.location.point = {
                    type: 'Point',
                    coordinates: [updateData.location.coordinates[0], updateData.location.coordinates[1]]
                };
            } else if (updateData.location.coordinates) {
                // Handle case where coordinates are provided but not in the correct format
                return res.status(400).json({ message: "Invalid location.coordinates format. Expected [longitude, latitude]." });
            }
        }


        if (Object.keys(updates).length === 0 && !updateData.location) { // Also check updateData.location because it's handled separately
            return res.status(400).json({ message: 'No valid update fields provided.' });
        }
        
        console.log('[DEBUG Server] Raw updateData (req.body):', JSON.stringify(updateData, null, 2));
        console.log('[DEBUG Server] Constructed updates object:', JSON.stringify(updates, null, 2));

        try {
            const provider = await Provider.findByIdAndUpdate(
                providerId,
                { $set: updates },
                { new: true, runValidators: true, context: 'query' }
            ).select('-password');

            if (!provider) {
                return res.status(404).json({ message: 'Provider not found.' });
            }

            console.log('[DEBUG Server] Provider object being sent back to client:', JSON.stringify(provider, null, 2));
            res.status(200).json({ message: 'Profile updated successfully', provider });
        } catch (error) {
            console.error('Error updating provider profile:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation failed', errors: error.errors });
            }
            res.status(500).json({ message: 'Failed to update profile', error: error.message });
        }
    },

    // GET /api/providers/me - Get authenticated provider's own profile
    async getMyProfile(req, res) {
        const rawProviderId = req.auth.id; // Get the ID from the token
        console.log('[getMyProfile] Raw ID from token:', rawProviderId);
        console.log('[getMyProfile] Type of raw ID from token:', typeof rawProviderId);

        if (!rawProviderId) {
            console.error('[getMyProfile] Error: Provider ID not found in token payload (req.auth.id).');
            return res.status(400).json({ message: 'Provider ID not found in authentication token.' });
        }

        // Ensure it's a valid ObjectId
        if (!mongoose.Types.ObjectId.isValid(rawProviderId)) {
            console.error('[getMyProfile] Error: Invalid Provider ID format received from token:', rawProviderId);
            return res.status(400).json({ message: 'Invalid Provider ID format in token.' });
        }

        const providerObjectId = new mongoose.Types.ObjectId(rawProviderId);
        console.log('[getMyProfile] Attempting to fetch profile for provider ObjectId:', providerObjectId);

        try {
            const provider = await Provider.findById(providerObjectId).select('-password');
            
            if (!provider) {
                console.warn('[getMyProfile] Provider not found in DB for ID:', providerObjectId);
                return res.status(404).json({ message: 'Provider profile not found.' });
            }

            console.log('[getMyProfile] Successfully fetched profile for ID:', providerObjectId);
            res.status(200).json(provider);
        } catch (error) {
            console.error('[getMyProfile] Error fetching own provider profile for ID:', providerObjectId, 'Error:', error);
            if (error.name === 'CastError') {
                return res.status(400).json({ message: 'Invalid Provider ID format during database query.', details: error.message });
            }
            res.status(500).json({ message: 'Failed to fetch provider profile', error: error.message });
        }
    },

    // TODO: Add endpoints for provider to update their own profile
    // PUT /api/providers/me
    // async updateMyProfile(req, res) { ... } -> This comment block is now replaced by the method above
};

module.exports = ProviderController;