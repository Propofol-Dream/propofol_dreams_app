# Claude Development Guide

This file contains development information for the Propofol Dreams Flutter app to help Claude understand the codebase structure and conventions.

## Project Overview

**Propofol Dreams** is a medical calculator app for anesthetists to minimize propofol wastage during TIVA (Total Intravenous Anesthesia). It's built with Flutter and supports multiple platforms.

## Key Commands

### Development
```bash
# Install dependencies
flutter pub get

# Clean build artifacts
flutter clean

# Generate splash screen
flutter pub run flutter_native_splash:create

# Run app (development)
flutter run

# Run tests
flutter test

# Analyze code
flutter analyze
```

### Building
```bash
# Android
flutter build apk --release
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Architecture & Patterns

- **State Management**: Provider pattern with ChangeNotifier
- **Navigation**: Basic MaterialApp navigation between screens
- **Theming**: Material 3 design with custom light/dark themes
- **Localization**: Flutter's built-in l10n with ARB files
- **Persistence**: SharedPreferences for simple key-value storage

## Key Files & Components

### Core Application
- `lib/main.dart`: App entry point with MultiProvider setup
- `lib/theme.dart`: Material theme definitions
- `lib/constants.dart`: App-wide constants

### Models
- `lib/models/patient.dart`: Patient data model
- `lib/models/pump.dart`: Pump configuration model
- `lib/models/calculator.dart`: Calculation logic
- `lib/models/elemarsh.dart`: Ele-Marsh pharmacokinetic model
- `lib/models/simulation.dart`: Simulation data structures

### Screens
- `lib/screens/home_screen.dart`: Main app with bottom navigation
- `lib/screens/volume_screen.dart`: Propofol volume calculations
- `lib/screens/duration_screen.dart`: Duration tracking
- `lib/screens/elemarsh_screen.dart`: Ele-Marsh model calculations
- `lib/screens/settings_screen.dart`: App settings

### Custom Components
- `lib/controllers/`: Custom form fields and controllers
- `lib/widgets/`: Reusable UI components with PD prefix

### State Management
- `lib/providers/settings.dart`: App settings provider

## Code Conventions

### Naming
- Classes: PascalCase (e.g., `HomeScreen`, `Patient`)
- Files: snake_case (e.g., `home_screen.dart`)
- Custom components: PD prefix (e.g., `PDTextField`, `PDLabel`)
- Variables/functions: camelCase

### File Organization
- Each screen in separate file under `screens/`
- Models grouped by domain in `models/`
- Reusable widgets in `widgets/` with PD prefix
- Controllers for complex UI logic in `controllers/`

## Dependencies

### Production
- `flutter`: Framework
- `provider`: State management
- `shared_preferences`: Local storage
- `flutter_localizations`: Internationalization
- `material_symbols_icons`: Material icons
- `url_launcher`: External URL handling
- `flutter_native_splash`: Splash screen generation

### Development
- `flutter_test`: Testing framework
- `flutter_lints`: Linting rules

## Testing

- Unit tests in `test/` directory
- Test files follow `*_test.dart` naming convention
- Key test files:
  - `test/calculator_test.dart`: Calculation logic tests
  - `test/elemarsh_test.dart`: Pharmacokinetic model tests
  - `test/simulation_test.dart`: Simulation logic tests

## Internationalization

- ARB files in `lib/l10n/`
- Generated files in `lib/l10n/generated/`
- Supported languages: English, Japanese, Chinese (Simplified & Traditional)
- Access via `AppLocalizations.of(context)`

## Platform Configuration

- **Android**: Configuration in `android/` directory
- **iOS**: Configuration in `ios/` directory  
- **Web**: Static assets in `web/`
- **macOS/Linux/Windows**: Desktop configurations in respective directories

## Medical Context

This is a **medical application** for qualified healthcare professionals. All calculations relate to propofol dosing and anesthesia management. Maintain high accuracy standards and include appropriate medical disclaimers.

## Version Info

- Current: v2.2.20 (Build 107)
- Flutter SDK: 3.1.0 - 3.10.0
- Private package (not published to pub.dev)