# Propofol Dreams App

Propofol Dreams is a Flutter application designed to help anesthetists minimize propofol wastage during Total Intravenous Anesthesia (TIVA) procedures.

## Overview

This medical calculator app provides anesthetists with tools to:
- Calculate optimal propofol dosing and infusion rates
- Manage pump settings and infusion parameters
- Track duration of anesthesia procedures
- Minimize medication waste through precise calculations

## Features

- **Volume Calculations**: Calculate propofol volumes based on patient parameters
- **Duration Tracking**: Monitor anesthesia duration and adjust dosing accordingly  
- **Ele-Marsh Integration**: Implements Ele-Marsh pharmacokinetic model for propofol
- **Multi-language Support**: Available in English, Japanese, and Chinese (Simplified & Traditional)
- **Dark/Light Theme**: Adaptive theming with system preference support
- **Cross-platform**: Runs on iOS, Android, web, macOS, Linux, and Windows

## Tech Stack

- **Framework**: Flutter 3.1.0+
- **Language**: Dart
- **State Management**: Provider pattern
- **Local Storage**: SharedPreferences
- **Internationalization**: Flutter's built-in l10n support
- **UI Components**: Material Design with custom components

## Project Structure

```
lib/
├── controllers/        # UI controllers and custom form fields
├── l10n/              # Internationalization files
├── models/            # Data models (Patient, Pump, Calculator, etc.)
├── providers/         # State management providers
├── screens/           # Main application screens
├── widgets/           # Reusable UI components
├── main.dart          # Application entry point
├── theme.dart         # Material theme configuration
└── constants.dart     # App-wide constants
```

## Getting Started

### Prerequisites

- Flutter SDK 3.1.0 or higher
- Dart SDK (included with Flutter)
- Platform-specific development tools (Xcode for iOS, Android Studio for Android)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd propofol_dreams_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate splash screen:
```bash
flutter pub run flutter_native_splash:create
```

4. Run the app:
```bash
flutter run
```

## Building for Production

### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web --release
```

## Medical Disclaimer

This application is designed as a clinical tool for qualified medical professionals. Users are responsible for verifying all calculations and maintaining appropriate medical standards. Always follow institutional protocols and guidelines when administering anesthesia.

## Version

Current version: 2.2.20 (Build 107)

## License

Private package - not published to pub.dev