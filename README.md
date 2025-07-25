# Propofol Dreams App

Propofol Dreams is a Flutter application designed to help anesthetists minimize propofol wastage during Total Intravenous Anesthesia (TIVA) procedures.

## Overview

This medical calculator app provides anesthetists with tools to:
- Calculate optimal propofol dosing and infusion rates
- Manage pump settings and infusion parameters
- Track duration of anesthesia procedures
- Minimize medication waste through precise calculations

## Features

- **Multi-Drug TCI Calculations**: Target-Controlled Infusion for multiple drug types:
  - Propofol (10mg/mL, 20mg/mL) - Yellow Accent coded
  - Remifentanil (20, 40 mcg/mL - Light Blue, 50 mcg/mL - Red) - Color coded by concentration  
  - Dexmedetomidine (4 mcg/mL) - Green coded
  - Remimazolam (1 mg/mL) - Purple coded
- **Advanced Pharmacokinetic Models**: Supports 8+ models with intelligent drug-model pairing
  - **Propofol**: Marsh (Plasma), Schnider (Effect-site), Eleveld (Universal)
  - **Remifentanil**: Minto, Eleveld models
  - **Dexmedetomidine**: Hannivoort model  
  - **Pediatric**: Paedfusor, Kataria models
- **Clinical Optimization**: MATLAB-based algorithms for practical pump programming
  - Smart bolus calculation with 15-minute averaging
  - Eliminates pump pauses for smoother TCI delivery
  - Conditional decimal formatting (1dp for <10mL, 0dp for ≥10mL)
- **Enhanced User Interface**:
  - Dynamic width drug selector (adapts to longest drug name)
  - Color-coded drug icons for instant visual identification
  - Real-time validation with detailed error messaging
  - Responsive design for all screen sizes
- **Comprehensive Testing**: 1,100+ lines of test coverage for pharmacokinetic calculations
- **Multi-language Support**: Available in English, Japanese, and Chinese
- **Cross-platform**: Runs on iOS, Android, web, macOS, Linux, and Windows

## Tech Stack

- **Framework**: Flutter 3.32.7
- **Language**: Dart
- **State Management**: Provider pattern
- **Local Storage**: SharedPreferences
- **Internationalization**: Flutter's built-in l10n support
- **UI Components**: Material Design with custom components

## Project Structure

```
lib/
├── components/        # Reusable UI components (tables, widgets)
├── controllers/       # UI controllers and custom form fields
├── l10n/             # Internationalization files
├── models/           # Data models (Patient, Pump, Drug, PK models, etc.)
├── providers/        # State management providers
├── screens/          # Main application screens
├── utils/            # Utility functions (text measurement, helpers)
├── widgets/          # Reusable UI widgets
├── main.dart         # Application entry point
├── theme.dart        # Material theme configuration
└── constants.dart    # App-wide constants
```

## Getting Started

### Prerequisites

- Flutter SDK 3.32.0 or higher
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

Current version: 2.2.21 (Build 108)

## Recent Updates (v2.2.21+)

### Core Framework
- **Flutter 3.32.7**: Updated to latest stable Flutter SDK with Dart 3.8.1
- **Enhanced Model Selection**: Redesigned modal interface for model selection
- **Improved Validation**: Added real-time error display for model constraints
- **Dependency Updates**: All packages updated to latest versions

### TCI Screen Enhancements
- **Multi-Drug Support**: Full TCI implementation for Propofol, Remifentanil, Dexmedetomidine, Remimazolam
- **Dynamic UI Width**: Drug selector automatically resizes to prevent text truncation
- **Color-Coded Icons**: Drug selector icon changes color based on selected drug
- **Duration Fix**: Table now properly displays up to 4:00 (255-minute duration)
- **Smart Bolus Formatting**: Conditional decimal places (1dp for <10mL, 0dp for ≥10mL)
- **Raw Bolus Access**: Unrounded bolus values available for debugging/research
- **Clinical Optimization**: MATLAB-based algorithms for practical pump programming

### Advanced Pharmacokinetics  
- **8+ PK Models**: Comprehensive model support with drug-specific pairing
- **Parameter System**: Centralized PKParameters with 1,100+ lines of calculations
- **Infusion Optimization**: 15-minute averaging with smart rounding for clinical usability
- **Test Coverage**: Comprehensive test suite for all pharmacokinetic calculations

### UI/UX Improvements
- **Responsive Design**: Dynamic layouts adapt to content and screen size
- **Visual Feedback**: Immediate color-coded drug identification
- **Enhanced Tables**: Animated infusion regime tables with bolus precision control
- **Error Handling**: Comprehensive validation with detailed error messaging

## License

Private package - not published to pub.dev