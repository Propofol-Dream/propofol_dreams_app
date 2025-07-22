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
  /// Based on analysis: initial high rate (~29 seconds) represents "bolus"
  static InfusionRegimeData fromSimulation({
    required List<Duration> times,
    required List<double> pumpInfs, // mg/hr
    required List<double> cumulativeInfusedVolumes, // mL
    required int density, // mg/mL
    Duration? totalDuration,
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

    // Find the end of high-rate "bolus" period (approximately first 30 seconds)
    final maxRate = pumpInfs.isNotEmpty ? pumpInfs.reduce((a, b) => a > b ? a : b) : 0.0;
    final bolusThreshold = maxRate * 0.9; // 90% of max rate
    int bolusEndIndex = 0;
    
    for (int i = 0; i < times.length && times[i].inSeconds <= 60; i++) {
      if (pumpInfs[i] >= bolusThreshold) {
        bolusEndIndex = i;
      } else {
        break;
      }
    }

    // Calculate bolus volume (volume delivered during high-rate period)
    final bolusVolume = bolusEndIndex < cumulativeInfusedVolumes.length 
        ? cumulativeInfusedVolumes[bolusEndIndex] 
        : 0.0;

    for (int interval = 0; interval < totalIntervals; interval++) {
      final intervalStart = Duration(minutes: interval * intervalMinutes);
      final intervalEnd = Duration(minutes: (interval + 1) * intervalMinutes);
      
      // Find simulation data points within this interval
      final intervalIndices = <int>[];
      for (int i = 0; i < times.length; i++) {
        if (times[i] >= intervalStart && times[i] < intervalEnd) {
          intervalIndices.add(i);
        }
      }

      // Calculate average infusion rate for this interval (convert mg/hr to mL/hr)
      double avgRate = 0.0;
      if (intervalIndices.isNotEmpty) {
        double totalRate = 0.0;
        for (final index in intervalIndices) {
          totalRate += pumpInfs[index] / density; // Convert to mL/hr
        }
        avgRate = totalRate / intervalIndices.length;
      }

      // Get accumulated volume at end of interval
      double accumVolume = 0.0;
      if (intervalIndices.isNotEmpty) {
        final lastIndex = intervalIndices.last;
        accumVolume = cumulativeInfusedVolumes[lastIndex];
      } else if (interval > 0 && rows.isNotEmpty) {
        // Use previous accumulated volume if no data in this interval
        accumVolume = rows.last.accumulatedVolume;
      }

      // Bolus is only shown at 0:00
      final bolus = interval == 0 ? bolusVolume : 0.0;

      rows.add(InfusionRegimeRow(
        time: intervalStart,
        bolus: bolus,
        infusionRate: avgRate,
        accumulatedVolume: accumVolume,
      ));
    }

    return InfusionRegimeData(
      rows: rows,
      intervalDuration: intervalDuration,
    );
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