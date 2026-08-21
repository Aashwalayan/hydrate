const HydrationSettings = require("../models/HydrationSettings");
const HydrationDaily = require("../models/HydrationDaily");

const getLevel = (percentage) => {
    if (percentage < 20) return 0;
    if (percentage < 40) return 1;
    if (percentage < 60) return 2;
    if (percentage < 75) return 3;
    if (percentage < 90) return 4;
    return 5;
};

// Returns YYYY-MM-DD using the server's local calendar date.
const getDateString = (date = new Date()) => {
    return (
        `${date.getFullYear()}-` +
        `${String(date.getMonth() + 1).padStart(2, "0")}-` +
        `${String(date.getDate()).padStart(2, "0")}`
    );
};

// Creates missing daily records between the user's last record
// and the requested date.
//
// Example:
// Last record = 2026-08-16
// Requested date = 2026-08-21
//
// Creates:
// 2026-08-17 → 0 ml
// 2026-08-18 → 0 ml
// 2026-08-19 → 0 ml
// 2026-08-20 → 0 ml
// 2026-08-21 → 0 ml
const ensureDailyRecords = async (userId, targetDate) => {
    const settings = await HydrationSettings.findOne({
        userId
    });

    if (!settings) {
        throw new Error("Hydration settings not found");
    }

    // Find the most recent daily record before the target date.
    const latest = await HydrationDaily.findOne({
        userId,
        date: { $lt: targetDate }
    }).sort({ date: -1 });

    let startDate;

    if (latest) {
        startDate = new Date(`${latest.date}T00:00:00`);
        startDate.setDate(startDate.getDate() + 1);
    } else {
        // No previous history.
        // Only create the requested day.
        startDate = new Date(`${targetDate}T00:00:00`);
    }

    const target = new Date(`${targetDate}T00:00:00`);

    const records = [];

    while (startDate <= target) {
        const date = getDateString(startDate);

        records.push({
            userId,
            date,
            goalMl: settings.dailyGoalMl,
            intakeMl: 0,
            completionPercent: 0,
            level: 0,
            entries: []
        });

        startDate.setDate(startDate.getDate() + 1);
    }

    if (records.length > 0) {
        try {
            await HydrationDaily.insertMany(records, {
                ordered: false
            });
        } catch (error) {
            // If two requests happen at nearly the same time,
            // the unique index may cause a duplicate-key error.
            // That's okay because the records already exist.
            if (error.code !== 11000) {
                throw error;
            }
        }
    }

    return HydrationDaily.findOne({
        userId,
        date: targetDate
    });
};

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

const addWater = async (req, res) => {
    try {
        const { amountMl, date } = req.body;

        if (!amountMl || amountMl <= 0) {
            return res.status(400).json({
                message: "Invalid water intake amount is required"
            });
        }

        if (!date) {
            return res.status(400).json({
                message: "Date is required"
            });
        }

        const settings = await HydrationSettings.findOne({
            userId: req.user.userId
        });

        if (!settings) {
            return res.status(404).json({
                message: "Hydration settings not found"
            });
        }

        // Make sure all missing days up to this date exist.
        let daily = await ensureDailyRecords(
            req.user.userId,
            date
        );

        if (!daily) {
            return res.status(404).json({
                message: "Unable to create daily hydration record"
            });
        }

        daily.entries.push({
            amountMl,
            timestamp: new Date()
        });

        daily.intakeMl += amountMl;

        daily.completionPercent = Math.round(
            (daily.intakeMl / daily.goalMl) * 100
        );

        daily.level = getLevel(
            daily.completionPercent
        );

        await daily.save();

        res.status(201).json({
            message: "Water intake added successfully",
            daily
        });

    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

const getToday = async (req, res) => {
    try {
        const today = getDateString();

        // This also backfills any days that were missed
        // while the app wasn't being used.
        const daily = await ensureDailyRecords(
            req.user.userId,
            today
        );

        if (!daily) {
            return res.status(404).json({
                message: "Unable to create today's hydration record"
            });
        }

        res.status(200).json(daily);

    } catch (error) {
        console.error(error);

        if (error.message === "Hydration settings not found") {
            return res.status(404).json({
                message: "Hydration settings not found"
            });
        }

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

const getHistory = async (req, res) => {
    try {
        const history = await HydrationDaily.find({
            userId: req.user.userId
        })
            .sort({ date: -1 })
            .select(
                "date goalMl intakeMl completionPercent level"
            );

        res.status(200).json(history);

    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

const updateGoal = async (req, res) => {
    try {
        const { dailyGoalMl } = req.body;

        if (!dailyGoalMl || dailyGoalMl <= 0) {
            return res.status(400).json({
                message: "A valid hydration goal is required"
            });
        }

        // Update the user's current hydration settings.
        const settings = await HydrationSettings.findOneAndUpdate(
            { userId: req.user.userId },
            { dailyGoalMl },
            {
                new: true,
                runValidators: true
            }
        );

        if (!settings) {
            return res.status(404).json({
                message: "Hydration settings not found"
            });
        }

        // Update today's daily record if it already exists.
        const today = getDateString();

        const daily = await HydrationDaily.findOne({
            userId: req.user.userId,
            date: today
        });

        if (daily) {
            daily.goalMl = dailyGoalMl;

            daily.completionPercent = Math.round(
                (daily.intakeMl / daily.goalMl) * 100
            );

            daily.level = getLevel(
                daily.completionPercent
            );

            await daily.save();
        }

        res.status(200).json({
            message: "Hydration goal updated successfully",
            settings,
            daily
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
    createOrUpdateSettings,
    updateGoal,
    addWater,
    getToday,
    getHistory
};