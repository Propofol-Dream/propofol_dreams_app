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

# Update dependencies
flutter pub upgrade
flutter pub upgrade --major-versions  # For major version updates

# Check outdated packages
flutter pub outdated
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
- `lib/models/model.dart`: Pharmacokinetic model definitions with ValidationResult pattern
- `lib/models/parameters.dart`: **NEW** - Pharmacokinetic parameter calculations for all models
- `lib/models/sex.dart`: Sex enumeration for calculations
- `lib/models/elemarsh.dart`: Ele-Marsh pharmacokinetic model
- `lib/models/simulation.dart`: Simulation data structures

### Screens
- `lib/screens/home_screen.dart`: Main app with bottom navigation (5 tabs)
- `lib/screens/tci_screen.dart`: **PRIMARY** - Multi-drug TCI calculations with dynamic UI
- `lib/screens/volume_screen.dart`: Volume calculations for different scenarios
- `lib/screens/duration_screen.dart`: Duration tracking and time-based calculations
- `lib/screens/elemarsh_screen.dart`: Ele-Marsh model calculations and wake-up estimation
- `lib/screens/settings_screen.dart`: App settings and preferences

### Custom Components
- `lib/components/infusion_regime_table.dart`: **CORE** - Advanced animated tables with conditional formatting
- `lib/controllers/PDAdvancedSegmentedController.dart`: Controller for model selection with validation
- `lib/controllers/PDModelSelectorModal.dart`: Modal for enhanced model selection UI
- `lib/controllers/PDTextField.dart`: Custom text input with validation
- `lib/controllers/PDSwitchField.dart`: Custom switch component
- `lib/controllers/`: Other custom form fields and controllers
- `lib/utils/text_measurement.dart`: **NEW** - Dynamic width calculation utilities
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
- `provider ^6.1.5`: State management
- `shared_preferences ^2.5.3`: Local storage
- `flutter_localizations`: Internationalization
- `material_symbols_icons ^4.2815.1`: Material icons
- `url_launcher ^6.3.2`: External URL handling
- `flutter_native_splash ^2.4.6`: Splash screen generation
- `intl ^0.20.2`: Internationalization support
- `cupertino_icons ^1.0.8`: iOS-style icons
- `rename ^3.1.0`: Asset renaming utility

### Development
- `flutter_test`: Testing framework
- `flutter_lints ^6.0.0`: Enhanced linting rules

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

- Current: v2.2.21 (Build 108)
- Flutter SDK: 3.32.7 (Dart 3.8.1)
- SDK Constraint: '>=3.1.0 <4.0.0'
- Private package (not published to pub.dev)

## Recent Changes (v2.2.21)

### Flutter & Dependencies
- **Upgraded Flutter**: 3.29.3 → 3.32.7 with Dart 3.8.1
- **Updated Dependencies**: All packages upgraded to latest compatible versions
- **Fixed Deprecations**: Replaced `withOpacity()` with `withValues(alpha:)` for color operations
- **Enhanced Error Handling**: Added proper async context checks with `context.mounted`

### Model Selection Enhancement
- **Redesigned Modal UI**: Created `PDModelSelectorModal` with bottom-sheet interface
- **Improved UX**: Positioned modal at bottom for better one-handed mobile usage
- **Smart Filtering**: Models automatically filter based on adult/pediatric view
- **Real-time Validation**: Displays error messages for unavailable models with explanations
- **Enhanced Styling**: Modal buttons match app's UI height and border radius standards
- **Removed EleMarsh**: Excluded from available model options per requirements

### Validation System Improvements
- **ValidationResult Pattern**: Replaced Map returns with structured ValidationResult class
- **Controller-based Validation**: Moved validation logic from UI to PDAdvancedSegmentedController
- **Error Text Display**: Added consistent error messaging on main volume screen
- **Reserved Error Space**: Prevents UI layout shifts when errors appear/disappear

### UI/UX Enhancements
- **Consistent Styling**: Modal components match existing control dimensions (56px height, 5px border radius)
- **Error Messaging**: Follows PDTextField pattern for consistent error display
- **Direct Selection**: Tap-to-select model behavior without separate confirm step
- **Responsive Design**: Handle bar and title positioning optimized for various screen sizes

### Pharmacokinetic Parameters Consolidation
- **New parameters.dart**: Comprehensive PK parameter calculation system
- **Model Support**: Implemented calculations for Marsh, Schnider, Eleveld, Paedfusor, Kataria models
- **Extension Methods**: Added `calculatePKParameters()` method to Model enum
- **Record Types**: Used Dart 3 record types for clean data structures
- **Future Models**: Framework for remifentanil, dexmedetomidine, and remimazolam models
- **BIS Parameters**: Added baseline BIS, CE50, and delay BIS calculations for propofol models
- **Consolidation**: Refactored simulation.dart to use PKParameters class, eliminating 150+ lines of duplicate code
- **Improved Eleveld Model**: More accurate calculations matching MATLAB equations exactly
- **Created operation.dart**: Added missing Operation class to fix compilation errors
- **Backward Compatibility**: Maintained existing API while improving code organization

### App-Wide Performance Optimization
- **Centralized Settings Initialization**: Added `initializeFromDisk()` to Settings provider
- **Eliminated Double-Initialization**: Removed async `load()` functions from all 6 screens
- **Synchronous initState()**: All screens now initialize controllers synchronously
- **Preloaded Settings**: Settings loaded once in main.dart before UI renders
- **Performance Benefits**: Eliminated UI flicker, double renders, and async delays across entire app
- **Code Reduction**: Removed 300+ lines of duplicate SharedPreferences loading code

### Code Quality
- **Lint Compliance**: Fixed async context warnings and unnecessary assertions
- **Type Safety**: Enhanced null safety with proper validation patterns
- **Documentation**: Updated README.md and CLAUDE.md with latest changes

## Latest Development Session (2024)

### TCI Screen Complete Redesign
- **Multi-Drug Support**: Full implementation for Propofol, Remifentanil, Dexmedetomidine, Remimazolam
- **Drug-Model Pairing**: Intelligent automatic model selection based on drug choice
- **Enhanced Output**: Comprehensive TCI print output with first 15-minute details and raw bolus values

### Advanced UI Enhancements
- **Dynamic Width Calculation**: `lib/utils/text_measurement.dart` for responsive drug selector sizing
- **Conditional Bolus Formatting**: Smart decimal places (1dp for <10mL, 0dp for ≥10mL) in tables
- **Color-Coded Drug Icons**: Drug selector icon dynamically changes color based on selected drug
- **Duration Fix**: Corrected 255-minute duration to properly display table up to 4:00

### Clinical Algorithm Implementation
- **Raw Bolus Storage**: Added `rawBolus` field to `InfusionRegimeRow` for unrounded values
- **MATLAB-Based Optimization**: Implemented clinical optimization algorithms for pump programming
- **15-Minute Averaging**: Smart averaging with clinical rounding for practical usability
- **Parameter Analysis**: Comprehensive test coverage for pharmacokinetic parameter validation

### Technical Improvements
- **Responsive Design**: Dynamic layouts adapt to content width and screen sizes
- **Enhanced Error Handling**: Comprehensive validation with detailed error messaging  
- **Test Coverage**: 1,000+ lines of test files for pharmacokinetic calculations
- **Code Organization**: New `components/` and `utils/` directories for better structure
- **Event-Driven Architecture**: Migrated from `addListener` to `onPressed` pattern for predictable calculation timing

### Drug Color System
Current color assignments (as updated by user):
- **Propofol**: Both concentrations use `Colors.yellowAccent`
- **Remifentanil**: 20mcg - `Colors.blue`, 40mcg - `Colors.lightBlueAccent`, 50mcg - `Colors.red`
- **Dexmedetomidine**: `Colors.green`
- **Remimazolam**: `Colors.purple`

### Key Development Notes
- TCI screen is now the **PRIMARY** interface (main medical functionality)
- All drug selector icons change color dynamically based on selection
- Bolus calculations include both rounded and raw values for clinical analysis
- Duration and width calculations are responsive and content-aware
- Comprehensive pharmacokinetic model support with clinical optimization

## Event-Driven vs Listener Architecture

### Current Pattern: onPressed (Event-Driven)
**Used in:** Both TCI and Volume screens
- **Triggers:** Only on explicit user actions (button presses, model/drug selection)
- **Advantages:** Predictable timing, no duplicate calculations, better performance
- **Use Case:** Medical apps where calculations should only happen on deliberate user input

### Deprecated Pattern: addListener (Reactive)
**Previously used in:** TCI screen (now removed)
- **Triggers:** Any text controller change (typing, programmatic updates)
- **Problems:** Caused duplicate print outputs, unexpected calculations during drug switching
- **Why Removed:** When `controller.text = newValue` occurred (e.g., drug switching), listeners fired causing double calculations

### Implementation Details
- **PDTextField Components:** Use `onPressed` callback for +/- button interactions
- **Text Field Listeners:** Removed from `initState()` to prevent automatic triggering
- **Model/Drug Selection:** Direct `calculate()` calls after state changes, no listener manipulation
- **Pattern Consistency:** Both TCI and Volume screens now follow identical event-driven architecture