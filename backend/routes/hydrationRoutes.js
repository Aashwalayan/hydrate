const express = require("express");

const {
  getSettings,
  createOrUpdateSettings,
} = require("../controllers/hydrationController");

const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/settings", authMiddleware, getSettings);

router.post("/settings", authMiddleware, createOrUpdateSettings);

module.exports = router;