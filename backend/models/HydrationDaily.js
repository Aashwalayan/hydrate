const mongoose = require("mongoose");

const hydrationEntrySchema = new mongoose.Schema(
    {
        amountMl: {
            type: Number,
            required: true,
            min: 1
        },

        timestamp: {
            type: Date,
            required: true,
            default: Date.now
        }
    },
    {
        _id: true
    }
);

const hydrationDailySchema = new mongoose.Schema(
    {
        userId: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        date: {
            type: String,
            required: true
        },

        goalMl: {
            type: Number,
            required: true
        },

        intakeMl: {
            type: Number,
            default: 0
        },

        completionPercent: {
            type: Number,
            default: 0
        },

        level: {
            type: Number,
            default: 0,
            min: 0,
            max: 5
        },

        entries: {
            type: [hydrationEntrySchema],
            default: []
        }
    },
    {
        timestamps: true
    }
);

hydrationDailySchema.index(
    { userId: 1, date: 1 },
    { unique: true }
);

module.exports = mongoose.model(
    "HydrationDaily",
    hydrationDailySchema
);