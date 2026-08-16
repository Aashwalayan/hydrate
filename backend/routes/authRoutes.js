const express = require("express");
const { signup, verifyEmail, login, updateName, changePassword, deleteAccount } = require("../controllers/authController");

const authMiddleware = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/signup", signup);
router.post("/verify-email", verifyEmail);
router.post("/login", login);

router.put("/me",authMiddleware, updateName);
router.put("/change-password", authMiddleware, changePassword);
router.delete("/me", authMiddleware, deleteAccount);

module.exports = router;