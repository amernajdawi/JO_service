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
        console.log("===== getMyProfile DEBUG =====");
        console.log("req.auth:", req.auth);
        
        const rawProviderId = req.auth.id; // Get the ID from the token
        console.log('[getMyProfile] Raw ID from token:', rawProviderId);
        console.log('[getMyProfile] Type of raw ID from token:', typeof rawProviderId);
        
        // Check if the token is actually present and formatted correctly
        if (!req.headers.authorization) {
            console.error('[getMyProfile] Error: Missing authorization header');
            return res.status(401).json({ message: 'Missing authorization header' });
        }

        if (!rawProviderId) {
            console.error('[getMyProfile] Error: Provider ID not found in token payload (req.auth.id).');
            return res.status(400).json({ message: 'Provider ID not found in authentication token.' });
        }

        // Ensure it's a valid ObjectId
        console.log('[getMyProfile] Checking if ID is valid ObjectId:', rawProviderId);
        console.log('[getMyProfile] ObjectId.isValid result:', mongoose.Types.ObjectId.isValid(rawProviderId));
        
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

    // POST /api/providers/me/profile-picture - Upload profile picture
    async uploadProfilePicture(req, res) {
        const providerId = req.auth.id;

        if (!req.file) {
            return res.status(400).json({ message: 'No file uploaded' });
        }

        try {
            // Generate the URL for the uploaded file
            const baseUrl = `${req.protocol}://${req.get('host')}`;
            const fileUrl = `${baseUrl}/uploads/profile-pictures/${req.file.filename}`;

            // Update the provider's profile with the new picture URL
            const provider = await Provider.findByIdAndUpdate(
                providerId,
                { $set: { profilePictureUrl: fileUrl } },
                { new: true, runValidators: true }
            ).select('-password');

            if (!provider) {
                return res.status(404).json({ message: 'Provider not found.' });
            }

            res.status(200).json({ 
                message: 'Profile picture uploaded successfully', 
                profilePictureUrl: fileUrl,
                provider 
            });
        } catch (error) {
            console.error('Error uploading profile picture:', error);
            res.status(500).json({ message: 'Failed to upload profile picture', error: error.message });
        }
    },

    // GET /api/providers/search - Search providers with filtering
    async searchProviders(req, res) {
        try {
            const {
                query,             // Text search query
                category,          // Service category
                minRating,         // Minimum rating
                maxPrice,          // Maximum hourly rate
                tags,              // Comma-separated service tags
                sort = 'rating',   // Sort field (rating, price)
                order = 'desc',    // Sort order (asc, desc)
                page = 1,          // Page number
                limit = 10,        // Results per page
                verified = false   // Whether to only show verified providers
            } = req.query;
            
            console.log('Searching providers with params:', req.query);
            
            // Build the query object
            const queryObj = {};
            
            // Only include active providers
            queryObj.accountStatus = 'active';
            
            // Apply text search if query is provided
            if (query && query.trim()) {
                queryObj.$text = { $search: query };
            }
            
            // Filter by category
            if (category) {
                queryObj.serviceCategory = category;
            }
            
            // Filter by minimum rating
            if (minRating) {
                queryObj.averageRating = { $gte: parseFloat(minRating) };
            }
            
            // Filter by maximum price
            if (maxPrice) {
                queryObj.hourlyRate = { $lte: parseFloat(maxPrice) };
            }
            
            // Filter by service tags
            if (tags) {
                const tagArray = tags.split(',').map(tag => tag.trim());
                queryObj.serviceTags = { $in: tagArray };
            }
            
            // Only show verified providers if requested
            if (verified === 'true') {
                queryObj.isVerified = true;
            }
            
            console.log('MongoDB query:', JSON.stringify(queryObj));
            
            // Set up sorting
            let sortObj = {};
            if (sort === 'rating') {
                sortObj.averageRating = order === 'asc' ? 1 : -1;
            } else if (sort === 'price') {
                sortObj.hourlyRate = order === 'asc' ? 1 : -1;
            }
            // Add secondary sort by totalRatings when sorting by rating
            if (sort === 'rating') {
                sortObj.totalRatings = order === 'asc' ? 1 : -1;
            }
            // Always add _id as final sort to ensure consistent pagination
            sortObj._id = 1;
            
            console.log('Sort options:', sortObj);
            
            // Calculate pagination
            const pageNum = parseInt(page, 10);
            const limitNum = parseInt(limit, 10);
            const skip = (pageNum - 1) * limitNum;
            
            // Execute the query with pagination
            const [providers, total] = await Promise.all([
                Provider.find(queryObj)
                    .select('-password') // Exclude sensitive data
                    .sort(sortObj)
                    .skip(skip)
                    .limit(limitNum),
                Provider.countDocuments(queryObj)
            ]);
            
            // Calculate total pages
            const totalPages = Math.ceil(total / limitNum);
            
            console.log(`Found ${providers.length} providers out of ${total} total`);
            
            res.status(200).json({
                providers,
                currentPage: pageNum,
                totalPages,
                totalProviders: total,
                hasMore: pageNum < totalPages
            });
        } catch (error) {
            console.error('Error searching providers:', error);
            res.status(500).json({ message: 'Failed to search providers', error: error.message });
        }
    },

    // GET /api/providers/nearby - Find providers near a location
    async findNearbyProviders(req, res) {
        try {
            const {
                latitude,      // User's latitude
                longitude,     // User's longitude
                distance = 10, // Search radius in kilometers
                category,      // Service category
                page = 1,      // Page number
                limit = 10     // Results per page
            } = req.query;
            
            console.log('Finding nearby providers:', req.query);
            
            // Validate required parameters
            if (!latitude || !longitude) {
                return res.status(400).json({ message: 'Latitude and longitude are required' });
            }
            
            // Build the query object
            const queryObj = {
                accountStatus: 'active',
                'location.coordinates': {
                    $nearSphere: {
                        $geometry: {
                            type: 'Point',
                            coordinates: [parseFloat(longitude), parseFloat(latitude)]
                        },
                        $maxDistance: parseFloat(distance) * 1000 // Convert km to meters
                    }
                }
            };
            
            // Filter by category if provided
            if (category) {
                queryObj.serviceCategory = category;
            }
            
            console.log('MongoDB geospatial query:', JSON.stringify(queryObj));
            
            // Calculate pagination
            const pageNum = parseInt(page, 10);
            const limitNum = parseInt(limit, 10);
            const skip = (pageNum - 1) * limitNum;
            
            // Execute the query with pagination
            const [providers, total] = await Promise.all([
                Provider.find(queryObj)
                    .select('-password') // Exclude sensitive data
                    .skip(skip)
                    .limit(limitNum),
                Provider.countDocuments(queryObj)
            ]);
            
            // Calculate total pages
            const totalPages = Math.ceil(total / limitNum);
            
            console.log(`Found ${providers.length} nearby providers out of ${total} total`);
            
            res.status(200).json({
                providers,
                currentPage: pageNum,
                totalPages,
                totalProviders: total,
                hasMore: pageNum < totalPages
            });
        } catch (error) {
            console.error('Error finding nearby providers:', error);
            res.status(500).json({ message: 'Failed to find nearby providers', error: error.message });
        }
    },

    // GET /api/providers/categories - Get all service categories
    async getServiceCategories(req, res) {
        try {
            // This list should match the enum in the Provider model
            const categories = [
                { id: 'cleaning', name: 'Cleaning Services' },
                { id: 'home_repair', name: 'Home Repair & Maintenance' },
                { id: 'plumbing', name: 'Plumbing Services' },
                { id: 'electrical', name: 'Electrical Services' },
                { id: 'gardening', name: 'Gardening & Landscaping' },
                { id: 'moving', name: 'Moving & Delivery' },
                { id: 'tutoring', name: 'Tutoring & Education' },
                { id: 'pet_care', name: 'Pet Care Services' },
                { id: 'beauty', name: 'Beauty & Spa Services' },
                { id: 'wellness', name: 'Health & Wellness' },
                { id: 'photography', name: 'Photography & Videography' },
                { id: 'graphic_design', name: 'Graphic Design' },
                { id: 'web_development', name: 'Web Development' },
                { id: 'legal', name: 'Legal Services' },
                { id: 'automotive', name: 'Automotive Services' },
                { id: 'event_planning', name: 'Event Planning' },
                { id: 'personal_training', name: 'Personal Training' },
                { id: 'cooking', name: 'Cooking & Catering' },
                { id: 'delivery', name: 'Delivery Services' },
                { id: 'other', name: 'Other Services' }
            ];
            
            // Get count of providers in each category
            const categoryCounts = await Promise.all(
                categories.map(async (category) => {
                    const count = await Provider.countDocuments({
                        serviceCategory: category.id,
                        accountStatus: 'active'
                    });
                    return {
                        ...category,
                        providerCount: count
                    };
                })
            );
            
            res.status(200).json(categoryCounts);
        } catch (error) {
            console.error('Error getting service categories:', error);
            res.status(500).json({ message: 'Failed to get service categories', error: error.message });
        }
    },

    // PATCH /api/providers/update-location - Update provider location
    async updateLocation(req, res) {
        try {
            const providerId = req.auth.id;
            const { coordinates, address, city, state, zipCode, country } = req.body;
            
            console.log(`Updating location for provider ${providerId}:`, req.body);
            
            // Validate the coordinates
            if (!coordinates || coordinates.length !== 2 || 
                !Array.isArray(coordinates) || 
                typeof coordinates[0] !== 'number' || 
                typeof coordinates[1] !== 'number') {
                return res.status(400).json({ 
                    message: 'Invalid coordinates. Expected [longitude, latitude] as numbers.' 
                });
            }
            
            const provider = await Provider.findById(providerId);
            if (!provider) {
                return res.status(404).json({ message: 'Provider not found' });
            }
            
            // Update location data
            provider.location = {
                type: 'Point',
                coordinates,
                address,
                city,
                state,
                zipCode,
                country: country || 'US'
            };
            
            const updatedProvider = await provider.save();
            
            res.status(200).json({ 
                message: 'Location updated successfully',
                location: updatedProvider.location
            });
        } catch (error) {
            console.error('Error updating provider location:', error);
            res.status(500).json({ message: 'Failed to update location', error: error.message });
        }
    },

    // PATCH /api/providers/update-services - Update provider services
    async updateServices(req, res) {
        try {
            const providerId = req.auth.id;
            const { 
                serviceType, 
                serviceDescription, 
                serviceCategory, 
                serviceTags,
                hourlyRate
            } = req.body;
            
            console.log(`Updating services for provider ${providerId}:`, req.body);
            
            const updateData = {};
            
            // Only update fields that are provided
            if (serviceType !== undefined) updateData.serviceType = serviceType;
            if (serviceDescription !== undefined) updateData.serviceDescription = serviceDescription;
            if (serviceCategory !== undefined) updateData.serviceCategory = serviceCategory;
            if (serviceTags !== undefined) updateData.serviceTags = serviceTags;
            if (hourlyRate !== undefined) updateData.hourlyRate = hourlyRate;
            
            // Perform the update
            const updatedProvider = await Provider.findByIdAndUpdate(
                providerId,
                { $set: updateData },
                { new: true, runValidators: true }
            ).select('-password');
            
            if (!updatedProvider) {
                return res.status(404).json({ message: 'Provider not found' });
            }
            
            res.status(200).json({ 
                message: 'Services updated successfully',
                provider: updatedProvider
            });
        } catch (error) {
            console.error('Error updating provider services:', error);
            if (error.name === 'ValidationError') {
                return res.status(400).json({ message: 'Validation error', errors: error.errors });
            }
            res.status(500).json({ message: 'Failed to update services', error: error.message });
        }
    }
};

module.exports = ProviderController;