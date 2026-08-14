const express = require("express");
const { signup, verifyEmail, login } = require("../controllers/authController");

const router = express.Router();

router.post("/signup", signup);
router.post("/verify-email", verifyEmail);
router.post("/login", login);

module.exports = router;