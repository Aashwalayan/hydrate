const express = require("express");

const {
    getAlarms,
    createAlarm,
    updateAlarm,
    deleteAlarm,
    toggleAlarm
} = require("../controllers/hydrationAlarmController");

const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/", authMiddleware, getAlarms);

router.post("/", authMiddleware, createAlarm);

router.patch("/:id", authMiddleware, updateAlarm);

router.patch("/:id/toggle", authMiddleware, toggleAlarm);

router.delete("/:id", authMiddleware, deleteAlarm);

module.exports = router;