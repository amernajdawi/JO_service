const User = require('../models/user.model');
const Provider = require('../models/provider.model');
const { generateToken } = require('../utils/jwt.utils');

// Helper function to safely extract user/provider data for response
const getUserResponse = (user) => {
    if (!user) return null;
    return {
        _id: user._id,
        email: user.email,
        fullName: user.fullName,
        phoneNumber: user.phoneNumber,
        profilePictureUrl: user.profilePictureUrl,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt
    };
};

// Helper function to safely extract provider data for response
const getProviderResponse = (provider) => {
    if (!provider) return null;
    // Exclude password and potentially other sensitive fields if needed
    const { password, ...response } = provider.toObject(); // Use .toObject() for clean object
    return response;
};

const AuthController = {
    async registerUser(req, res) {
        const { email, password, fullName, phoneNumber, profilePictureUrl } = req.body;
        try {
            const existingUser = await User.findOne({ email: email.toLowerCase() });
            if (existingUser) {
                return res.status(400).json({ message: 'User already exists with this email' });
            }
            const newUser = new User({
                email,
                password,
                fullName,
                phoneNumber,
                profilePictureUrl
            });
            const savedUser = await newUser.save();
            const userResponse = getUserResponse(savedUser);
            const token = generateToken({ id: savedUser._id, type: 'user' });
            res.status(201).json({ message: 'User registered successfully', user: userResponse, token });
        } catch (error) {
            console.error('User registration error:', error);
            if (error.name === 'ValidationError') {
                const messages = Object.values(error.errors).map(val => val.message);
                return res.status(400).json({ message: 'Validation Error', errors: messages });
            }
             // Handle duplicate key error (code 11000 for MongoDB)
            if (error.code === 11000) {
                 return res.status(400).json({ message: 'Email already exists.' });
            }
            res.status(500).json({ message: 'Error registering user', error: error.message });
        }
    },

    async loginUser(req, res) {
        const { email, password } = req.body;
        try {
            const user = await User.findOne({ email: email.toLowerCase() }).select('+password');
            if (!user || !(await user.comparePassword(password))) {
                return res.status(401).json({ message: 'Invalid credentials' });
            }
            const userResponse = getUserResponse(user);
            const token = generateToken({ id: user._id, type: 'user' });
            res.status(200).json({ message: 'User logged in successfully', user: userResponse, token });
        } catch (error) {
            console.error('User login error:', error);
            res.status(500).json({ message: 'Error logging in user', error: error.message });
        }
    },

    // --- Provider Auth --- 

    async registerProvider(req, res) {
        const {
            email, password, fullName, serviceType, hourlyRate,
            locationLatitude, locationLongitude, addressText, // Expecting coordinates and address
            availabilityDetails, serviceDescription, profilePictureUrl
        } = req.body;

        try {
            const existingProvider = await Provider.findOne({ email: email.toLowerCase() });
            if (existingProvider) {
                return res.status(400).json({ message: 'Provider already exists with this email' });
            }

            // Construct location object
            let location = {};
            if (locationLongitude != null && locationLatitude != null) { // Use != null to allow 0
                location.point = {
                    type: 'Point',
                    coordinates: [parseFloat(locationLongitude), parseFloat(locationLatitude)]
                };
            }
            if (addressText) {
                location.addressText = addressText;
            }

            const newProvider = new Provider({
                email,
                password,
                fullName,
                serviceType,
                hourlyRate,
                location: Object.keys(location).length > 0 ? location : undefined, // Only add location if data exists
                availabilityDetails,
                serviceDescription,
                profilePictureUrl
                // isVerified, averageRating, totalRatings have defaults in the schema
            });

            const savedProvider = await newProvider.save();
            const providerResponse = getProviderResponse(savedProvider);
            const token = generateToken({ id: savedProvider._id, type: 'provider' });

            res.status(201).json({ 
                message: 'Provider registered successfully', 
                provider: providerResponse, 
                token 
            });
        } catch (error) {
            console.error('Provider registration error:', error);
            if (error.name === 'ValidationError') {
                const messages = Object.values(error.errors).map(val => val.message);
                return res.status(400).json({ message: 'Validation Error', errors: messages });
            }
             // Handle duplicate key error
            if (error.code === 11000) {
                 return res.status(400).json({ message: 'Email already exists.' });
            }
            res.status(500).json({ message: 'Error registering provider', error: error.message });
        }
    },

    async loginProvider(req, res) {
        const { email, password } = req.body;
        try {
            // Need to explicitly select password as it's excluded by default in the schema
            const provider = await Provider.findOne({ email: email.toLowerCase() }).select('+password');
            
            // Check if provider exists and password matches
            if (!provider || !(await provider.comparePassword(password))) {
                return res.status(401).json({ message: 'Invalid credentials' });
            }

            // Prepare response object (excluding password)
            const providerResponse = getProviderResponse(provider);
            const token = generateToken({ id: provider._id, type: 'provider' });
            
            res.status(200).json({ 
                message: 'Provider logged in successfully', 
                provider: providerResponse, 
                token 
            });
        } catch (error) {
            console.error('Provider login error:', error);
            res.status(500).json({ message: 'Error logging in provider', error: error.message });
        }
    }
};

module.exports = AuthController; 