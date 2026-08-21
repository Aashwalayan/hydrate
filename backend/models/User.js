const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: {
        type: String,
        required: true,
    },

    email: {
        type: String,
        required: true,
        unique: true
    },

    password: {
        type: String,
        required: true
    },

    profilePicture: {
        type: String,
        default: null
    },

    isVerified: {
        type: Boolean,
        default: false
    },

    verificationOtp: {
        type: String
    },

    verificationOtpExpires: {
        type: Date
    },

    resetOtp: {
        type: String
    },

    resetOtpExpires: {
        type: Date
    }

}, {
    timestamps: true
});

module.exports = mongoose.model('User', userSchema);