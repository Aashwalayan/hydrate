const HydrationSettings = require("../models/HydrationSettings");
const HydrationDaily = require("../models/HydrationDaily");

const getLevel = (percentage) => {
    if (percentage < 20) return 0;
    if (percentage < 40) return 1;
    if (percentage < 60) return 2;
    if (percentage < 75) return 3;
    if (percentage < 90) return 4;
    return 5;
}

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
    try{
        const {amountMl, date} = req.body;

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

        let daily = await HydrationDaily.findOne({
            userId: req.user.userId,
            date
        });

        if (!daily) {
            daily = new HydrationDaily({
                userId: req.user.userId,
                date,
                goalMl: settings.dailyGoalMl,
                intakeMl: 0,
                completionPercent: 0,
                level: 0,
                entries: []
            });
        }

        daily.entries.push({
            amountMl,
            timestamp: new Date()
        });

        daily.intakeMl += amountMl;

        daily.completionPercent = Math.round((daily.intakeMl / daily.goalMl) * 100);

        daily.level = getLevel(daily.completionPercent);

        await daily.save();

        res.status(201).json({
            message: "Water intake added successfully",
            daily
        });

    }catch(error){

        console.error(error);
        res.status(500).json({
            message: "Something went wrong"
        });

    }
};

const getToday = async (req, res) => {
    try {
        const { date } = req.query;

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

        let daily = await HydrationDaily.findOne({
            userId: req.user.userId,
            date
        });

        if (!daily) {
            return res.status(200).json({
                date,
                goalMl: settings.dailyGoalMl,
                intakeMl: 0,
                completionPercent: 0,
                level: 0,
                entries: []
            });
        }

        res.status(200).json(daily);

    } catch (error) {
        console.error(error);

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


module.exports = {
    getSettings,
    createOrUpdateSettings,
    addWater,
    getToday,
    getHistory
};