const { Resend } = require("resend");

const resend = new Resend(process.env.RESEND_API_KEY);

const sendVerificationEmail = async (email, otp) => {
    await resend.emails.send({
        from: process.env.EMAIL_FROM,
        to: email,
        subject: "Verify your Hydrate account",
        html: `
            <h2>Verify your Hydrate account</h2>
            <p>Your verification code is:</p>
            <h1>${otp}</h1>
            <p>This code expires in 10 minutes.</p>
        `
    });
};

const sendPasswordResetEmail = async (email, otp) => {
    await resend.emails.send({
        from: process.env.EMAIL_FROM,
        to: email,
        subject: "Reset your Hydrate password",
        html: `
            <h2>Password Reset</h2>
            <p>Your reset code is:</p>
            <h1>${otp}</h1>
            <p>This code expires in 10 minutes.</p>
        `
    });
};

module.exports = {
    sendVerificationEmail,
    sendPasswordResetEmail
};