const HydrationAlarm = require("../models/hydrationAlarm");

const getAlarms = async (req, res) => {
    try {
        const alarms = await HydrationAlarm.find({
            userId: req.user.userId
        }).sort({ createdAt: 1 });

        res.status(200).json(alarms);
    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

const createAlarm = async (req, res) => {
    try {
        const {
            label,
            scheduleType,
            reminderTimes,
            enabled,
            startTime,
            endTime,
            intervalMinutes,
            tone
        } = req.body;

        if (!label || !scheduleType || !reminderTimes) {
            return res.status(400).json({
                message: "Label, schedule type and reminder times are required"
            });
        }

        const alarm = await HydrationAlarm.create({
            userId: req.user.userId,
            label,
            scheduleType,
            reminderTimes,
            enabled,
            startTime,
            endTime,
            intervalMinutes,
            tone
        });

        res.status(201).json({
            message: "Hydration alarm created successfully",
            alarm
        });
    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

const updateAlarm = async (req, res) => {
    try {
        const { id } = req.params;

        const alarm = await HydrationAlarm.findOneAndUpdate(
            {
                _id: id,
                userId: req.user.userId
            },
            req.body,
            {
                new: true,
                runValidators: true
            }
        );

        if (!alarm) {
            return res.status(404).json({
                message: "Hydration alarm not found"
            });
        }

        res.status(200).json({
            message: "Hydration alarm updated successfully",
            alarm
        });
    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

const deleteAlarm = async (req, res) => {
    try {
        const { id } = req.params;

        const alarm = await HydrationAlarm.findOneAndDelete({
            _id: id,
            userId: req.user.userId
        });

        if (!alarm) {
            return res.status(404).json({
                message: "Hydration alarm not found"
            });
        }

        res.status(200).json({
            message: "Hydration alarm deleted successfully"
        });
    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

const toggleAlarm = async (req, res) => {
    try {
        const { id } = req.params;

        const alarm = await HydrationAlarm.findOne({
            _id: id,
            userId: req.user.userId
        });

        if (!alarm) {
            return res.status(404).json({
                message: "Hydration alarm not found"
            });
        }

        alarm.enabled = !alarm.enabled;

        await alarm.save();

        res.status(200).json({
            message: `Hydration alarm ${alarm.enabled ? "enabled" : "disabled"} successfully`,
            alarm
        });
    } catch (error) {
        console.error(error);

        res.status(500).json({
            message: "Something went wrong"
        });
    }
};

module.exports = {
    getAlarms,
    createAlarm,
    updateAlarm,
    deleteAlarm,
    toggleAlarm
};