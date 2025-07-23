class InfusionRegimeRow {
  final Duration time;
  final double bolus; // mL (only non-zero at 0:00)
  final double infusionRate; // mL/hr (average for this 15-min interval)
  final double accumulatedVolume; // mL (total volume delivered)

  const InfusionRegimeRow({
    required this.time,
    required this.bolus,
    required this.infusionRate,
    required this.accumulatedVolume,
  });

  String get timeString {
    final hours = time.inHours;
    final minutes = time.inMinutes.remainder(60);
    return '${hours.toString().padLeft(1, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

class InfusionRegimeData {
  final List<InfusionRegimeRow> rows;
  final Duration intervalDuration;

  const InfusionRegimeData({
    required this.rows,
    this.intervalDuration = const Duration(minutes: 15),
  });

  /// Create infusion regime data from simulation results
  /// OPTIMIZED ALGORITHM: Implements clinical optimization from MATLAB code
  /// 
  /// This algorithm optimizes the infusion regime for practical pump programming:
  /// 1. First 15 minutes: Calculates augmented bolus + continuous infusion to eliminate pump pauses
  /// 2. Subsequent intervals: Uses averaging with smart rounding for clinical usability
  /// 3. Smart rounding: 1 decimal place if <10 mL/hr, integer if ≥10 mL/hr
  /// 
  /// Based on MATLAB optimization algorithm that eliminates the need to pause pumps
  /// during Ce targeting, making TCI procedures smoother for clinicians.
  static InfusionRegimeData fromSimulation({
    required List<Duration> times,
    required List<double> pumpInfs, // mg/hr
    required List<double> cumulativeInfusedVolumes, // mL
    required int density, // mg/mL - LEGACY: kept for backward compatibility
    Duration? totalDuration,
    bool isEffectSiteTargeting = true, // New parameter to handle targeting type
    double? drugConcentrationMgMl, // NEW: Standardized drug concentration
  }) {
    if (times.isEmpty || pumpInfs.isEmpty || cumulativeInfusedVolumes.isEmpty) {
      return const InfusionRegimeData(rows: []);
    }

    // Use provided duration or simulation duration
    final maxDuration = totalDuration ?? times.last;
    final intervalMinutes = 15;
    final intervalDuration = Duration(minutes: intervalMinutes);
    
    // Calculate number of 15-minute intervals needed
    final totalIntervals = (maxDuration.inMinutes / intervalMinutes).ceil();
    final rows = <InfusionRegimeRow>[];

    // Use new drug concentration if provided, otherwise fall back to legacy density
    final effectiveConcentration = drugConcentrationMgMl ?? density.toDouble();

    // STEP 1: OPTIMIZED FIRST 15 MINUTES
    // Calculate total dose for first 15 minutes (900 seconds)
    final first15MinIndex = times.indexWhere((time) => time.inSeconds >= 900);
    final validFirst15Index = first15MinIndex != -1 ? first15MinIndex : times.length - 1;
    
    // Calculate total dose in first 900 seconds (convert mg/hr to mg total)
    double totalDoseFirst15Min = 0.0;
    for (int i = 0; i < validFirst15Index && i < pumpInfs.length; i++) {
      totalDoseFirst15Min += pumpInfs[i] / 3600.0; // Convert mg/hr to mg/second, sum over seconds
    }

    // STEP 2: Find infusion restart time (when bolus+pause finishes)
    int infusionRestartIndex = 0;
    if (isEffectSiteTargeting) {
      // For effect site targeting: find when infusion rate drops to zero (end of pause)
      for (int i = 0; i < validFirst15Index && i < pumpInfs.length; i++) {
        if (pumpInfs[i] == 0.0) {
          infusionRestartIndex = i;
        } else if (pumpInfs[i] > 0.0 && infusionRestartIndex > 0) {
          break; // Found restart after pause
        }
      }
    } else {
      // For plasma targeting: calculate based on bolus duration
      final maxRate = pumpInfs.isNotEmpty ? pumpInfs.reduce((a, b) => a > b ? a : b) : 0.0;
      if (maxRate > 0) {
        final bolusVolume = cumulativeInfusedVolumes.isNotEmpty ? cumulativeInfusedVolumes.first : 0.0;
        final bolusDurationSeconds = (bolusVolume * density / maxRate * 3600).round();
        infusionRestartIndex = bolusDurationSeconds + 1; // +1 like MATLAB code
      }
    }

    // STEP 3: Calculate average infusion rate for non-bolus section
    double totalDoseAfterBolus = 0.0;
    for (int i = infusionRestartIndex; i < validFirst15Index && i < pumpInfs.length; i++) {
      totalDoseAfterBolus += pumpInfs[i] / 3600.0;
    }
    
    final remainingSeconds = 900 - infusionRestartIndex;
    double avgInfusionRate = remainingSeconds > 0 
        ? (totalDoseAfterBolus / remainingSeconds) * 3600.0 // Convert back to mg/hr
        : 0.0;

    // STEP 4: Apply smart rounding to average infusion rate
    avgInfusionRate = _applySmartRounding(avgInfusionRate, effectiveConcentration);

    // STEP 5: Calculate augmented bolus (eliminates pump pauses)
    final continuousInfusionDose = 900 * avgInfusionRate / 3600.0; // mg for 15 min
    double augmentedBolus = totalDoseFirst15Min - continuousInfusionDose;
    augmentedBolus = augmentedBolus / effectiveConcentration; // Convert to mL
    
    // Round bolus to practical values
    if (augmentedBolus < 1.0 && augmentedBolus > 0) {
      augmentedBolus = (augmentedBolus * 10).round() / 10.0; // Round to 0.1 mL
    } else {
      augmentedBolus = augmentedBolus.round().toDouble(); // Round to nearest mL
    }
    if (augmentedBolus < 0) augmentedBolus = 0.0;

    // Add first 15-minute interval with optimized values
    rows.add(InfusionRegimeRow(
      time: const Duration(minutes: 0),
      bolus: augmentedBolus,
      infusionRate: avgInfusionRate / effectiveConcentration, // Convert to mL/hr for display
      accumulatedVolume: augmentedBolus + (avgInfusionRate / effectiveConcentration * 0.25), // Bolus + 15min infusion
    ));

    // STEP 6: AVERAGING ALGORITHM FOR SUBSEQUENT INTERVALS
    for (int interval = 1; interval < totalIntervals; interval++) {
      final intervalStart = Duration(minutes: interval * intervalMinutes);
      final intervalEnd = Duration(minutes: (interval + 1) * intervalMinutes);
      
      // Find simulation data points within this interval
      final intervalIndices = <int>[];
      for (int i = 0; i < times.length; i++) {
        if (times[i] >= intervalStart && times[i] < intervalEnd) {
          intervalIndices.add(i);
        }
      }

      // Calculate average infusion rate for this interval
      double avgRate = 0.0;
      if (intervalIndices.isNotEmpty) {
        double totalRate = 0.0;
        for (final index in intervalIndices) {
          totalRate += pumpInfs[index]; // Keep in mg/hr for calculation
        }
        avgRate = totalRate / intervalIndices.length;
        
        // Apply smart rounding
        avgRate = _applySmartRounding(avgRate, effectiveConcentration);
      }

      // Calculate accumulated volume
      double accumVolume = 0.0;
      if (rows.isNotEmpty) {
        // Previous accumulated volume + this interval's contribution
        accumVolume = rows.last.accumulatedVolume + (avgRate / effectiveConcentration * 0.25); // 0.25 hr = 15 min
      }

      rows.add(InfusionRegimeRow(
        time: intervalStart,
        bolus: 0.0, // No bolus after first interval
        infusionRate: avgRate / effectiveConcentration, // Convert to mL/hr for display
        accumulatedVolume: accumVolume,
      ));
    }

    return InfusionRegimeData(
      rows: rows,
      intervalDuration: intervalDuration,
    );
  }

  /// Apply smart rounding based on MATLAB algorithm
  /// If rate < 10 mL/hr: round to 1 decimal place
  /// If rate >= 10 mL/hr: round to integer
  static double _applySmartRounding(double rateMgHr, double concentrationMgMl) {
    final rateMlHr = rateMgHr / concentrationMgMl;
    
    if (rateMlHr < 10.0) {
      // Round to 1 decimal place, then convert back to mg/hr
      return (rateMlHr * 10).round() / 10.0 * concentrationMgMl;
    } else {
      // Round to integer, then convert back to mg/hr
      return rateMlHr.round().toDouble() * concentrationMgMl;
    }
  }

  /// Get total estimated bolus volume (volume at 0:00)
  double get totalBolus => rows.isNotEmpty ? rows.first.bolus : 0.0;

  /// Get final accumulated volume
  double get totalVolume => rows.isNotEmpty ? rows.last.accumulatedVolume : 0.0;

  /// Get maximum infusion rate
  double get maxInfusionRate => rows.isEmpty 
      ? 0.0 
      : rows.map((r) => r.infusionRate).reduce((a, b) => a > b ? a : b);
}