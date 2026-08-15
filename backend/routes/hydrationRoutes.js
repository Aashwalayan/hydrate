const express = require("express");

const {
  getSettings,
  createOrUpdateSettings,
  addWater,
  getToday,
  getHistory
} = require("../controllers/hydrationController");

const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/settings", authMiddleware, getSettings);

router.post("/settings", authMiddleware, createOrUpdateSettings);

router.get("/today", authMiddleware, getToday);

router.get("/history", authMiddleware, getHistory);

router.post("/water", authMiddleware, addWater);

module.exports = router;