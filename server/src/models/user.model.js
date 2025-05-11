const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const SALT_ROUNDS = 10;

const userSchema = new mongoose.Schema({
    email: {
        type: String,
        required: [true, 'Email is required'],
        unique: true,
        trim: true, // Removes whitespace from both ends of a string
        lowercase: true, // Converts email to lowercase before saving
        match: [/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/, 'Please fill a valid email address']
    },
    password: { // Renamed from password_hash for Mongoose convention, actual hashing happens pre-save
        type: String,
        required: [true, 'Password is required'],
        minlength: [6, 'Password must be at least 6 characters long']
    },
    fullName: {
        type: String,
        required: [true, 'Full name is required'],
        trim: true
    },
    phoneNumber: {
        type: String,
        trim: true,
        // Example validation (can be more specific based on requirements)
        // match: [/^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$/, 'Please fill a valid phone number']
    },
    profilePictureUrl: {
        type: String,
        trim: true,
        default: '' // Default to an empty string or a path to a default avatar
    },
    // Timestamps are automatically managed by Mongoose if { timestamps: true } is added to schema options
}, { timestamps: true }); // Adds createdAt and updatedAt fields automatically

// Pre-save hook to hash password
userSchema.pre('save', async function(next) {
    // Only hash the password if it has been modified (or is new)
    if (!this.isModified('password')) return next();

    try {
        const salt = await bcrypt.genSalt(SALT_ROUNDS);
        this.password = await bcrypt.hash(this.password, salt);
        next();
    } catch (error) {
        next(error); // Pass errors to the next middleware
    }
});

// Method to compare input password with hashed password in DB
userSchema.methods.comparePassword = async function(inputPassword) {
    return await bcrypt.compare(inputPassword, this.password);
};

// For Mongoose, the first argument to mongoose.model is the singular name of your collection.
// Mongoose automatically looks for the plural, lowercased version of your model name.
// Thus, for the model 'User', Mongoose will create/use the collection 'users'.
const User = mongoose.model('User', userSchema);

module.exports = User;
