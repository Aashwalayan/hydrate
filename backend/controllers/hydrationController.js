const HydrationSettings = require("../models/HydrationSettings");

const getSettings = async (req, res) => {
    try {
        const settings = await HydrationSettings.findOne({
            userId: req.user.userId
        });

        if (!settings) {
            return res.status(404).json({
                message: "Hydration settings not found"
            });
        }

        res.status(200).json(settings);

    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

const createOrUpdateSettings = async (req, res) => {
    try {
        const { dailyGoalMl, reminders } = req.body;

        if (!dailyGoalMl || !reminders) {
            return res.status(400).json({
                message: "Hydration goal and reminder settings are required"
            });
        }

        const settings = await HydrationSettings.findOneAndUpdate(
            { userId: req.user.userId },
            {
                userId: req.user.userId,
                dailyGoalMl,
                reminders
            },
            {
                new: true,
                upsert: true,
                runValidators: true
            }
        );

        res.status(200).json({
            message: "Hydration settings saved successfully",
            settings
        });

    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

module.exports = {
    getSettings,
    createOrUpdateSettings
};