const mongoose = require("mongoose");

const hydrationAlarmSchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true,
            index: true
        },

        label: {
            type: String,
            required: true,
            trim: true,
            default: "Hydration reminders"
        },

        scheduleType: {
            type: String,
            enum: ["equalIntervals", "custom"],
            required: true
        },

        // The actual times that should fire.
        // Example: ["08:00", "09:00", "10:00"]
        reminderTimes: {
            type: [String],
            required: true,
            validate: {
                validator: function (times) {
                    return times.length >= 1 && times.length <= 12;
                },
                message: "An alarm must have between 1 and 12 reminder times."
            }
        },

        enabled: {
            type: Boolean,
            default: true
        },

        // Only relevant for equalIntervals schedules.
        startTime: {
            type: String,
            default: null
        },

        endTime: {
            type: String,
            default: null
        },

        intervalMinutes: {
            type: Number,
            default: null,
            min: 1
        },

        // Matches the current Flutter AlarmTone enum.
        tone: {
            type: String,
            enum: [
                "defaultTone",
                "chime",
                "droplet",
                "bell",
                "gentleWave",
                "silent"
            ],
            default: "defaultTone"
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("HydrationAlarm", hydrationAlarmSchema);