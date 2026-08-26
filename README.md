# Hydrate

> A smart hydration reminder app that helps you drink enough water, build healthier habits, and never miss a reminder.

Hydrate is a Flutter-based mobile application designed to make staying hydrated simple and consistent. It combines customizable hydration schedules with reliable alarm-style reminders, personalization, and hydration tracking.

## Features

* **Custom hydration reminders** — Create reminders that fit your daily routine.
* **Flexible schedules** — Use equal-interval schedules or define custom reminder times.
* **Reliable alarm system** — Reminders can behave like real alarms rather than ordinary notifications.
* **Full-screen alarm experience** — Hydration alarms can interrupt the current activity and appear over the lock screen on supported Android devices.
* **Snooze & dismiss** — Control an active reminder directly from the alarm screen.
* **Custom alarm sounds** — Choose the sound used when a hydration reminder rings.
* **Volume-aware alarms** — Alarm playback respects the device's alarm-volume behavior.
* **Hydration tracking** — Keep track of your water intake and build consistent habits.
* **Personalization** — Customize your experience with profile and appearance settings.
* **Authentication** — Secure user accounts and synchronized hydration data.
* **Cross-platform Flutter architecture** — Built with Flutter for a modern mobile experience.

## Tech Stack

### Mobile

* Flutter
* Dart
* Android Alarm / Notification APIs

### Backend

* Node.js
* Express.js
* MongoDB
* Mongoose

### Development

* Android Studio
* VS Code
* Git & GitHub

## Architecture

```text
┌─────────────────────┐
│      Flutter App    │
│                     │
│  UI • Auth • Alarms │
│  Hydration Tracking │
└──────────┬──────────┘
           │ REST API
           ▼
┌─────────────────────┐
│    Node.js Backend  │
│      Express.js     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│      MongoDB        │
│                     │
│ Users • Alarms      │
│ Hydration Data      │
└─────────────────────┘
```

## Getting Started

### Prerequisites

Make sure you have:

* Flutter SDK
* Dart SDK
* Android Studio / Android SDK
* Node.js
* MongoDB

### Clone the repository

```bash
git clone https://github.com/Aashwalayan/hydrate.git
cd hydrate
```

### Install Flutter dependencies

```bash
flutter pub get
```

### Configure the backend

Navigate to the backend directory:

```bash
cd backend
npm install
```

Create your environment configuration with the required MongoDB connection string and authentication settings.

Then start the backend:

```bash
npm start
```

### Run the Flutter application

From the project root:

```bash
flutter run
```

For Android development, make sure the required notification, alarm, and full-screen permissions are granted on the device.

## Alarm System

Hydrate's alarm system is designed specifically for hydration reminders that should not be easily missed.

Depending on Android version and device manufacturer, the app may require permissions for:

* Notifications
* Exact alarms
* Full-screen notifications
* Battery/background operation

Android manufacturers may apply additional battery-saving restrictions that can affect alarm behavior.

## Project Structure

```text
hydrate/
├── android/          # Android platform configuration
├── assets/           # Application assets
├── backend/          # Node.js / Express backend
├── ios/              # iOS platform configuration
├── lib/              # Flutter application source
├── test/             # Flutter tests
├── web/              # Web platform configuration
├── windows/          # Windows platform configuration
├── macos/            # macOS platform configuration
├── pubspec.yaml      # Flutter dependencies
└── README.md
```

## Version

**v1.0.1**

Hydrate v1.0.1 is the first stable release of the application.

## Roadmap

Future improvements may include:

* Improved hydration analytics
* More alarm customization
* Additional reminder types
* Smarter hydration recommendations
* Expanded iOS alarm support
* Better background reliability across manufacturers
* More personalization options

## Contributing

Contributions, suggestions, and bug reports are welcome.

If you find an issue, please open a GitHub issue with:

1. A description of the problem
2. Steps to reproduce it
3. Device and Android/iOS version
4. Relevant screenshots or logs

Built with Flutter by **Aashwalayan**.
