const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const SALT_ROUNDS = 10;

// GeoJSON Point Schema for location
const pointSchema = new mongoose.Schema({
  type: {
    type: String,
    enum: ['Point'],
    required: true,
    default: 'Point'
  },
  coordinates: {
    type: [Number], // [longitude, latitude]
    required: true,
    index: '2dsphere' // Create a geospatial index for location-based queries
  }
});

const providerSchema = new mongoose.Schema({
    email: {
        type: String,
        required: [true, 'Email is required'],
        unique: true,
        trim: true,
        lowercase: true,
        match: [/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/, 'Please fill a valid email address']
    },
    password: {
        type: String,
        required: [true, 'Password is required'],
        minlength: [6, 'Password must be at least 6 characters long'],
        select: false // Exclude password by default when querying providers
    },
    fullName: {
        type: String,
        required: [true, 'Full name is required'],
        trim: true
    },
    companyName: {
        type: String,
        trim: true
    },
    serviceType: {
        type: String,
        required: [true, 'Service type is required'],
        trim: true,
        // Example: enum: ['Electrician', 'Plumber', 'Carpenter', 'Blacksmith', 'Other']
    },
    hourlyRate: {
        type: Number,
        min: [0, 'Hourly rate cannot be negative']
    },
    location: {
        point: pointSchema, // Embedded GeoJSON point
        addressText: { type: String, trim: true } // Full textual address
    },
    contactInfo: {
        phone: { type: String, trim: true }
    },
    availabilityDetails: { // e.g., "Mon-Fri 9am-5pm", or more structured if needed later
        type: String,
        trim: true
    },
    serviceDescription: {
        type: String,
        trim: true,
        maxlength: [1000, 'Service description cannot exceed 1000 characters']
    },
    profilePictureUrl: {
        type: String,
        trim: true,
        default: ''
    },
    isVerified: {
        type: Boolean,
        default: false
    },
    averageRating: {
        type: Number,
        default: 0,
        min: 0,
        max: 5
    },
    totalRatings: {
        type: Number,
        default: 0,
        min: 0
    }
}, { timestamps: true });

// Pre-save hook to hash password
providerSchema.pre('save', async function(next) {
    if (!this.isModified('password')) return next();
    try {
        const salt = await bcrypt.genSalt(SALT_ROUNDS);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error);
    }
});

// Method to compare input password with hashed password
providerSchema.methods.comparePassword = async function(inputPassword) {
    return await bcrypt.compare(inputPassword, this.password);
};

// Compound index for searching by serviceType and location (if needed frequently)
// providerSchema.index({ serviceType: 1, 'location.point': '2dsphere' });

const Provider = mongoose.model('Provider', providerSchema);

module.exports = Provider; 