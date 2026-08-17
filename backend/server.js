const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
require("dotenv").config();

const authRoutes = require("./routes/authRoutes");
const hydrationRoutes = require("./routes/hydrationRoutes");
const hydrationAlarmRoutes = require("./routes/hydrationAlarmRoutes");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/auth", authRoutes);
app.use("/api/hydration", hydrationRoutes);
app.use("/api/hydration/alarms", hydrationAlarmRoutes);

app.get("/", (req, res) => {
    res.json({
        message: "Hydrate API is running"
    });
});

const PORT = process.env.PORT || 4000;

mongoose
    .connect(process.env.MONGODB_URI)
    .then(() => {
        console.log("MongoDB connected");

        app.listen(PORT, "0.0.0.0", () => {
            console.log(`Server running on port ${PORT}`);
        });
    })
    .catch((error) => {
        console.error("MongoDB connection failed:", error);
    });