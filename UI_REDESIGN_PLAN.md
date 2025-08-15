# Modern UI Redesign for Propofol Dreams - Implementation Plan

## 🎯 Design Philosophy
**"Collapse to Calculate"** - Collapsible input cards with compact summaries maximize result display space while maintaining quick input access.

## 🚀 Core UI Transformation

### 1. **Google Material Design 3 Foundation**
- **Typography**: Material Design typography scale with Roboto/Roboto Mono
- **Icons**: Material Symbols (existing `material_symbols_icons` package)
- **Colors**: Material You dynamic color system with medical-appropriate contrast
- **Components**: Material 3 cards, buttons, inputs with proper elevation and state layers

### 2. **Adaptive Layout System**
- **Mobile**: Single-column with collapsible input card + maximized results
- **Tablet**: 2-column layout (collapsible input left, results right) 
- **Web**: 3-column dashboard with navigation sidebar

### 3. **Navigation System**
- **Mobile**: Bottom navigation bar + floating calculate button
- **Tablet**: Navigation rail with labels
- **Web**: Navigation drawer with calculator descriptions

## 🎴 **Collapsible Input Card Architecture**

### **Core Concept:**
Each calculator has ONE smart input card that:
1. **Expanded**: Shows all input fields for editing
2. **Collapsed**: Shows compact summary of current values
3. **Auto-behavior**: Collapses after calculation to maximize result space

### **Collapsed State Design:**

#### **Visual Style: Icon + Text Summary**
```
┌─────────────────────────────────────────────────────────────┐
│ 👤 25y/Male/70kg/170cm  💊 Propofol 10mg  🧠 Eleveld       │
│ 🎯 3.0μg/mL  ⏱ 255min                               [▼]    │
└─────────────────────────────────────────────────────────────┘
```

#### **Responsive Adaptations:**
- **Mobile**: 2-row compact summary (68dp height)
- **Tablet**: Single row with more spacing (56dp height)  
- **Desktop**: Single row with full labels (48dp height)

### **Calculator-Specific Input Cards:**

#### **1. TCI Calculator (Primary)**
**Expanded Input Fields:**
- Patient: Age, Height, Weight, Sex (collapsible section)
- Drug: Visual selector with concentration display
- Model: Auto-paired with drug + validation
- Target: Drug-specific units with bounds
- Duration: Fixed 255min display

**Collapsed Summary:**
```
👤 25y/M/70kg/170cm  💊 Propofol 10mg  🧠 Eleveld  🎯 3.0μg/mL  ⏱ 255min [▼]
```

**Results Display:**
- **Mobile**: Bottom sheet with infusion table + fl_chart
- **Desktop**: Right panel with animated table

#### **2. Volume Calculator**
**Expanded Input Fields:**
- Patient: Age, Height, Weight, Sex (collapsible section)
- Model: Adult/Pediatric toggle + model selector
- Target: Concentration with units
- Duration: Time input with presets

**Collapsed Summary:**
```
👤 25y/M/70kg  🧠 Adult-Eleveld  🎯 3.0μg/mL  ⏱ 120min  📊 Volume [▼]
```

**Results Display:**
- Total volume needed with breakdown table

#### **3. Duration Calculator**
**Expanded Input Fields:**
- Weight: Single input
- Infusion Rate: With unit selector (mg/kg/hr, mcg/kg/min, mL/hr)

**Collapsed Summary:**
```
👤 70kg  💉 5.0 mg/kg/hr  📊 Duration Analysis [▼]
```

**Results Display:**
- Duration vs Volume table showing volumes needed at different time points

#### **4. EleMarsh Calculator**
**Expanded Input Fields:**
- Patient: Age, Height, Weight, Sex
- Target Ce: Concentration input
- Flow: Induce/Maintenance selector
- Model: Marsh/Eleveld toggle for wake-up
- Additional: Maintenance Ce, SE, Infusion Rate

**Collapsed Summary:**
```
👤 25y/M/70kg  🎯 3.0Ce  🔄 Induce  🧠 Marsh  📊 EleMarsh [▼]
```

**Results Display:**
- Best guess weight, BMI, predicted BIS, adjustment bolus

#### **5. Settings Screen**
**Card Groups (Non-collapsible):**
- Theme, Language, Defaults, About cards

### **Animation & Interaction Design:**

#### **Smooth Expansion Animation**
```dart
AnimatedContainer(
  duration: Duration(milliseconds: 300),
  curve: Curves.easeInOutCubic,
  height: isExpanded ? null : collapsedHeight,
  child: AnimatedSwitcher(
    duration: Duration(milliseconds: 200),
    child: isExpanded ? ExpandedInputs() : CollapsedSummary(),
  ),
)
```

#### **Interaction Patterns:**
- **Auto-collapse**: After successful calculation
- **Tap summary**: Expands for editing
- **Calculate button**: Triggers calculation + auto-collapse
- **Validation errors**: Forces expansion to show error fields

### **Responsive Behavior:**

#### **Mobile (< 600dp)**
- Collapsed card: 68dp height (2 rows)
- Maximum result space below
- Bottom sheet for complex results

#### **Tablet (600-840dp)**
- Collapsed card: 56dp height (single row)
- Side-by-side input/results layout
- Navigation rail

#### **Desktop (840dp+)**
- Collapsed card: 48dp height (compact single row)
- Three-column layout with navigation drawer
- Keyboard shortcuts for expand/collapse (Space/Enter)

## 📱 **Dependencies to Add**

### **Chart Visualization**
```yaml
dependencies:
  fl_chart: ^0.69.0  # Flutter-native charts for infusion curves
```

### **Enhanced Responsive Layout**
```yaml
dependencies:
  flutter_staggered_grid_view: ^0.7.0  # Advanced grid layouts
  responsive_framework: ^1.1.1  # Responsive breakpoints
```

## 🛠 **Implementation Strategy**

### **Phase 1**: Collapsible Foundation (Week 1)
- [ ] Create `CollapsibleInputCard` component
- [ ] Build summary display system with Material icons
- [ ] Implement smooth expand/collapse animations
- [ ] Add auto-collapse after calculation

#### **Files to Create:**
- `lib/components/collapsible_input_card.dart`
- `lib/components/input_summary_display.dart`
- `lib/utils/responsive_breakpoints.dart`

### **Phase 2**: Calculator Migration (Week 2)
- [ ] **TCI**: Full collapsible card + fl_chart results
- [ ] **Volume**: Streamlined card + volume display  
- [ ] **Duration**: Simple card + duration table
- [ ] **EleMarsh**: Complete card + results panel

#### **Files to Modify:**
- `lib/screens/tci_screen.dart`
- `lib/screens/volume_screen.dart`
- `lib/screens/duration_screen.dart`
- `lib/screens/elemarsh_screen.dart`

### **Phase 3**: Polish & Responsive (Week 3)
- [ ] Responsive summary layouts (mobile/tablet/desktop)
- [ ] Enhanced micro-interactions
- [ ] Validation error handling with forced expansion
- [ ] Accessibility compliance (screen readers, keyboard nav)

#### **Files to Create:**
- `lib/components/responsive_layout.dart`
- `lib/components/adaptive_navigation.dart`

### **Phase 4**: Advanced Features (Week 4)
- [ ] fl_chart integration for infusion curves
- [ ] Quick-edit functionality (tap chips to edit specific values)
- [ ] Smart defaults and input memory
- [ ] Performance optimization

#### **Files to Create:**
- `lib/components/infusion_chart.dart`
- `lib/utils/chart_helpers.dart`

## 🎨 **Visual Design Specifications**

### **Color Scheme (Material 3)**
```dart
// Primary colors for drug types (existing system)
Drug.propofol: Colors.yellowAccent
Drug.remifentanil: Colors.blue / Colors.lightBlueAccent / Colors.red
Drug.dexmedetomidine: Colors.green  
Drug.remimazolam: Colors.purple

// UI State colors
success: Theme.of(context).colorScheme.primary
warning: Theme.of(context).colorScheme.tertiary
error: Theme.of(context).colorScheme.error
```

### **Typography Scale**
```dart
// Headers
headlineLarge: 32sp, Regular
headlineMedium: 28sp, Regular  
headlineSmall: 24sp, Regular

// Body text
bodyLarge: 16sp, Regular
bodyMedium: 14sp, Regular
bodySmall: 12sp, Regular

// Data display (monospace for precision)
Roboto Mono: 14sp, Medium (for numerical values)
```

### **Spacing System**
```dart
// Material Design 3 spacing
xs: 4dp
sm: 8dp  
md: 16dp
lg: 24dp
xl: 32dp

// Card specifications
Collapsed height: 48dp (desktop), 56dp (tablet), 68dp (mobile)
Card elevation: 1dp (collapsed), 3dp (expanded)
Border radius: 12dp (Material 3 standard)
```

### **Icon Usage**
```dart
// Patient demographics
Icons.person_outline: Patient info
Icons.cake_outlined: Age
Icons.height: Height  
Icons.monitor_weight_outlined: Weight

// Medical
Icons.medication_outlined: Drug selection
Icons.psychology_outlined: Model selection  
Icons.gps_fixed_outlined: Target concentration
Icons.schedule_outlined: Duration/Time

// Actions  
Icons.calculate_outlined: Calculate button
Icons.expand_more / expand_less: Collapse toggle
Icons.copy_outlined: Copy results
Icons.share_outlined: Share results
```

## 🔧 **Technical Implementation Notes**

### **State Management Pattern**
- Continue using Provider for settings and global state
- Add local state for collapse/expand within cards
- Maintain existing settings persistence

### **Performance Considerations**
- Lazy loading for large result tables
- Efficient chart rendering with fl_chart
- Minimize rebuilds during animations
- Proper controller disposal

### **Accessibility Requirements**
- Semantic labels for all interactive elements
- Keyboard navigation support
- Screen reader announcements for state changes
- Sufficient color contrast for medical environments
- Touch targets minimum 48dp

## ✅ **Success Criteria**

### **Functionality**
- [ ] All existing calculations work identically
- [ ] No regression in calculation accuracy
- [ ] Settings persistence maintained
- [ ] All localizations preserved

### **Usability**
- [ ] Faster calculation workflow (fewer taps)
- [ ] More result display space when collapsed
- [ ] Smooth, intuitive animations
- [ ] Consistent behavior across all screens

### **Responsive Design**
- [ ] Perfect mobile experience (320px width)
- [ ] Optimal tablet layout (768px+ width)
- [ ] Desktop-class interface (1200px+ width)
- [ ] Seamless transitions between breakpoints

### **Performance**
- [ ] Smooth 60fps animations
- [ ] Fast chart rendering
- [ ] Efficient memory usage
- [ ] Quick app startup time

## 📋 **Testing Checklist**

### **Cross-Platform Testing**
- [ ] iOS (iPhone SE to iPhone 14 Pro Max)
- [ ] Android (various screen sizes and densities)
- [ ] iPad (portrait and landscape)
- [ ] Web browsers (Chrome, Safari, Firefox)
- [ ] macOS/Windows desktop

### **Accessibility Testing**
- [ ] VoiceOver (iOS) navigation
- [ ] TalkBack (Android) navigation  
- [ ] Keyboard-only navigation (web)
- [ ] High contrast mode compatibility
- [ ] Large text scaling support

### **Medical Workflow Testing**
- [ ] Rapid calculation scenarios
- [ ] Multi-patient workflow
- [ ] Emergency use cases
- [ ] Data accuracy verification
- [ ] Clinical printout formatting

This plan maintains all existing functionality while creating a modern, efficient, and beautiful interface optimized for medical professionals across all device types.