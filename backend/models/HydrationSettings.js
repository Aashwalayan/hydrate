const mongoose = require("mongoose");

const hydrationSettingsSchema = new mongoose.Schema({
    userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        required: true,
        unique: true
    },

    dailyGoalMl: {
        type: Number,
        required: true,
        min: 1000,
        max: 5000,
        default: 2500
    },

    reminders: {
        enabled: {
            type: Boolean,
            default: true
        },

        intervalMinutes: {
            type: Number,
            enum: [30, 60, 90, 120],
            default: 60
        },

        startTime: {
            type: String,
            default: "08:00"
        },

        endTime: {
            type: String,
            default: "22:00"
        }
    }

}, {
    timestamps: true
});

module.exports = mongoose.model("HydrationSettings", hydrationSettingsSchema);