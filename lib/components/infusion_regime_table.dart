import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/infusion_regime_data.dart';
import '../l10n/generated/app_localizations.dart';

/// Helper function to format bolus values with conditional decimal places
/// Matches the rounding logic from InfusionRegimeData:
/// - Values < 10.0 mL are rounded to 0.1 mL precision → show 1 decimal place
/// - Values ≥ 10.0 mL are rounded to integers → show 0 decimal places
/// Display logic: Values <10mL: 1dp, Values ≥10mL: 0dp
String formatBolusValue(double bolus) {
  if (bolus >= 10.0) {
    // Double digit or more: show no decimal places (values are already integers)
    return bolus.toStringAsFixed(0);
  } else {
    // Single digit: show 1 decimal place (preserves 0.1 mL precision for small values)
    return bolus.toStringAsFixed(1);
  }
}

/// Helper function to format infusion rate values with conditional decimal places
/// Matches the same logic as formatBolusValue for consistency
/// - Values < 10.0 mL/hr are rounded to 0.1 mL/hr precision → show 1 decimal place
/// - Values ≥ 10.0 mL/hr are rounded to integers → show 0 decimal places
String formatInfusionRateValue(double infusionRate) {
  if (infusionRate >= 10.0) {
    // Double digit or more: show no decimal places (values are already integers)
    return infusionRate.toStringAsFixed(0);
  } else {
    // Single digit: show 1 decimal place (preserves 0.1 mL/hr precision for small values)
    return infusionRate.toStringAsFixed(1);
  }
}

String formatDurationAsHoursMinutes(double durationMinutes) {
  final int totalMinutes = durationMinutes.round();
  final int hours = totalMinutes ~/ 60;
  final int minutes = totalMinutes % 60;
  return '$hours:${minutes.toString().padLeft(2, '0')}';
}

// Generic table row data structure
abstract class TableRowData {
  String get timeString;
  List<String> get values;
  bool get isHighlighted => false;
  String? get highlightedValue => null;
}

// Implementation for InfusionRegimeRow
class InfusionTableRowData extends TableRowData {
  final InfusionRegimeRow row;
  final bool _isHighlighted;

  InfusionTableRowData(this.row, this._isHighlighted);

  @override
  String get timeString => row.timeString;

  @override
  List<String> get values => [
    formatBolusValue(row.bolus),
    formatInfusionRateValue(row.infusionRate),
    row.accumulatedVolume.toStringAsFixed(1),
  ];

  @override
  bool get isHighlighted => _isHighlighted;

  @override
  String? get highlightedValue => null;
}

// Implementation for confidence interval data (used in volume screen)
class ConfidenceIntervalRowData extends TableRowData {
  final List<String> _values;
  final String? _highlightValue;

  ConfidenceIntervalRowData(this._values, {String? highlightValue}) 
      : _highlightValue = highlightValue;

  @override
  String get timeString => _values.isNotEmpty ? _values[0] : '';

  @override
  List<String> get values => _values.length > 1 ? _values.sublist(1) : [];

  @override
  bool get isHighlighted => false;

  @override
  String? get highlightedValue => _highlightValue;
}

class DurationTableRowData extends TableRowData {
  final String volume;
  final String duration;
  @override
  final bool isHighlighted;

  DurationTableRowData(this.volume, this.duration, {this.isHighlighted = false});

  @override
  String get timeString => volume;

  @override
  List<String> get values => [duration];

  @override
  String? get highlightedValue => null;
}

// Generic animated data table (used by volume screen)
class AnimatedDataTable extends StatefulWidget {
  final List<TableRowData> data;
  final List<String> headers;
  final bool isExpanded;
  final bool animate;
  final int maxVisibleRows;
  final int? selectedRowIndex;
  final Function(int)? onRowTap;
  final ScrollController? scrollController;

  const AnimatedDataTable({
    super.key,
    required this.data,
    required this.headers,
    required this.isExpanded,
    this.animate = true,
    this.maxVisibleRows = 8,
    this.selectedRowIndex,
    this.onRowTap,
    this.scrollController,
  });

  @override
  State<AnimatedDataTable> createState() => _AnimatedDataTableState();
}

class _AnimatedDataTableState extends State<AnimatedDataTable>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _contentController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.fastOutSlowIn,
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(_contentAnimation);

    // Set initial state without animation
    if (widget.isExpanded) {
      if (widget.animate) {
        // Only animate if specifically requested (button tap)
        _mainController.forward();
        _contentController.forward();
      } else {
        // Jump to final state immediately (screen restoration)
        _mainController.value = 1.0;
        _contentController.value = 1.0;
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Skip animation logic on first build
    if (_isFirstBuild) {
      _isFirstBuild = false;
      return;
    }
    
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.animate) {
        // Play animation when animate is true (button tap)
        if (widget.isExpanded) {
          _mainController.forward();
          Future.delayed(const Duration(milliseconds: 25), () {
            if (mounted) _contentController.forward();
          });
        } else {
          _contentController.reverse();
          _mainController.reverse();
        }
      } else {
        // Jump to final state without animation (screen restoration)
        if (widget.isExpanded) {
          _mainController.value = 1.0;
          _contentController.value = 1.0;
        } else {
          _mainController.value = 0.0;
          _contentController.value = 0.0;
        }
      }
    } else if (widget.animate != oldWidget.animate && !widget.animate) {
      // If animate flag changes from true to false, ensure we're in the correct final state
      if (widget.isExpanded) {
        _mainController.value = 1.0;
        _contentController.value = 1.0;
      } else {
        _mainController.value = 0.0;
        _contentController.value = 0.0;
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _headerAnimation,
      child: FadeTransition(
        opacity: _headerAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(_contentAnimation),
            child: DataTable(
              data: widget.data,
              headers: widget.headers,
              maxVisibleRows: widget.maxVisibleRows,
              selectedRowIndex: widget.selectedRowIndex,
              onRowTap: widget.onRowTap,
              scrollController: widget.scrollController,
            ),
          ),
        ),
      ),
    );
  }
}

// Animated infusion regime table
class AnimatedInfusionRegimeTable extends StatefulWidget {
  final InfusionRegimeData data;
  final bool isExpanded;
  final int maxVisibleRows;
  final int? selectedRowIndex;
  final Function(int)? onRowTap;
  final ScrollController? scrollController;

  const AnimatedInfusionRegimeTable({
    super.key,
    required this.data,
    required this.isExpanded,
    this.maxVisibleRows = 8,
    this.selectedRowIndex,
    this.onRowTap,
    this.scrollController,
  });

  @override
  State<AnimatedInfusionRegimeTable> createState() => _AnimatedInfusionRegimeTableState();
}

class _AnimatedInfusionRegimeTableState extends State<AnimatedInfusionRegimeTable>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _contentController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 200), // More snappy: 350 → 200
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 150), // More snappy: 300 → 150
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.fastOutSlowIn,
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(_contentAnimation);

    if (widget.isExpanded) {
      _mainController.forward();
      _contentController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedInfusionRegimeTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _mainController.forward();
        // Delay content animation slightly for staggered effect
        Future.delayed(const Duration(milliseconds: 25), () { // Reduced: 50 → 25
          if (mounted) _contentController.forward();
        });
      } else {
        _contentController.reverse();
        _mainController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Convert InfusionRegimeData to generic TableRowData
    final tableData = widget.data.rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      return InfusionTableRowData(row, index == 0);
    }).toList();

    return SizeTransition(
      sizeFactor: _headerAnimation,
      child: FadeTransition(
        opacity: _headerAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(_contentAnimation),
            child: DataTable(
              data: tableData,
              headers: [
                '${AppLocalizations.of(context)!.bolus} (mL)', 
                '${AppLocalizations.of(context)!.rate} (mL/hr)', 
                'Total (mL)'
              ],
              maxVisibleRows: widget.maxVisibleRows,
              selectedRowIndex: widget.selectedRowIndex,
              onRowTap: widget.onRowTap,
              scrollController: widget.scrollController,
            ),
          ),
        ),
      ),
    );
  }
}

class DataTable extends StatelessWidget {
  final List<TableRowData> data;
  final List<String> headers;
  final int maxVisibleRows;
  final int? selectedRowIndex;
  final Function(int)? onRowTap;
  final ScrollController? scrollController;

  const DataTable({
    super.key,
    required this.data,
    required this.headers,
    this.maxVisibleRows = 8,
    this.selectedRowIndex,
    this.onRowTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (maxVisibleRows == 0) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final visibleRows = data; // Show all data, let scrolling handle the rest

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxVisibleRows * 41.0), // More precise row height calculation
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: visibleRows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      final isFirstRow = index == 0;
                      final isSelected = selectedRowIndex == index;
                      return _buildDataRow(context, row, isFirstRow, isSelected, index);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.primary, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Time column (20%)
          Expanded(
            flex: 20,
            child: Text(AppLocalizations.of(context)!.time, style: headerStyle),
          ),
          // Data columns - dynamically generate based on headers
          ...headers.asMap().entries.map((entry) {
            final index = entry.key;
            final header = entry.value;
            
            return Expanded(
              flex: headers.length == 3 ? [25, 30, 25][index] : 100 ~/ headers.length,
              child: Text(
                header, 
                style: headerStyle, 
                textAlign: TextAlign.end,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, TableRowData row, bool isFirstRow, bool isSelected, int index) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    
    // Highlight selected row or special rows based on row data
    final backgroundColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : row.isHighlighted 
            ? theme.colorScheme.primary.withValues(alpha: 0.04)
            : Colors.transparent;

    return GestureDetector(
      onTap: () {
        if (onRowTap != null) {
          onRowTap!(index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.3), 
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            // Time column (20%)
            Expanded(
              flex: 20,
              child: Text(
                row.timeString,
                style: bodyStyle?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            // Data columns - dynamically generate based on values
            ...row.values.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              final isHighlighted = row.highlightedValue != null && row.highlightedValue == value;
              
              return Expanded(
                flex: headers.length == 3 ? [25, 30, 25][index] : 100 ~/ headers.length,
                child: isHighlighted 
                    ? Text(
                        value,
                        style: bodyStyle?.copyWith(
                          color: theme.colorScheme.primary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        textAlign: TextAlign.end,
                      )
                    : Text(
                        value,
                        style: bodyStyle?.copyWith(
                          fontWeight: FontWeight.normal,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        textAlign: TextAlign.end,
                       ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Compact version for smaller spaces
class InfusionRegimeTableCompact extends StatelessWidget {
  final InfusionRegimeData data;
  final int maxRows;

  const InfusionRegimeTableCompact({
    super.key,
    required this.data,
    this.maxRows = 6,
  });

  @override
  Widget build(BuildContext context) {
    // Convert InfusionRegimeData to generic TableRowData
    final tableData = data.rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      return InfusionTableRowData(row, index == 0);
    }).toList();

    return DataTable(
      data: tableData,
      headers: [
        '${AppLocalizations.of(context)!.bolus} (mL)', 
        '${AppLocalizations.of(context)!.rate} (mL/hr)', 
        'Total (mL)'
      ],
      maxVisibleRows: maxRows,
    );
  }
}

// Custom table for dosage screen - only shows Rate column
class AnimatedDosageTable extends StatefulWidget {
  final InfusionRegimeData data;
  final bool isExpanded;
  final int maxVisibleRows;

  const AnimatedDosageTable({
    super.key,
    required this.data,
    required this.isExpanded,
    this.maxVisibleRows = 5,
  });

  @override
  State<AnimatedDosageTable> createState() => _AnimatedDosageTableState();
}

class _AnimatedDosageTableState extends State<AnimatedDosageTable>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _contentController;
  late Animation<double> _headerAnimation;
  late Animation<double> _contentAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _mainController,
      curve: Curves.fastOutSlowIn,
    );

    _contentAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(_contentAnimation);

    if (widget.isExpanded) {
      _mainController.forward();
      _contentController.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedDosageTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded != oldWidget.isExpanded) {
      if (widget.isExpanded) {
        _mainController.forward();
        Future.delayed(const Duration(milliseconds: 25), () {
          if (mounted) _contentController.forward();
        });
      } else {
        _contentController.reverse();
        _mainController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bolus display above table
        if (widget.data.totalBolus > 0.01)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.medication_liquid,
                  size: 18,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bolus: ${formatBolusValue(widget.data.totalBolus)} mL',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        // Animated table
        SizeTransition(
          sizeFactor: _headerAnimation,
          child: FadeTransition(
            opacity: _headerAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(_contentAnimation),
                child: DosageDataTable(
                  data: widget.data,
              maxVisibleRows: widget.isExpanded ? widget.maxVisibleRows : 0,                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Custom data table that only shows Rate column
class DosageDataTable extends StatelessWidget {
  final InfusionRegimeData data;
  final int maxVisibleRows;
  final int? selectedRowIndex;
  final Function(int)? onRowTap;
  final ScrollController? scrollController;

  const DosageDataTable({
    super.key,
    required this.data,
    this.maxVisibleRows = 5,
    this.selectedRowIndex,
    this.onRowTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (data.rows.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: IntrinsicHeight(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBolusRow(context),
            _buildHeader(context),
            Expanded(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxVisibleRows * 41.0),
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: data.rows.asMap().entries.map((entry) {
                      final index = entry.key;
                      final row = entry.value;
                      final isFirstRow = index == 0;
                      final isSelected = selectedRowIndex == index;
                      return _buildDataRow(context, row, isFirstRow, isSelected, index);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBolusRow(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );
    
    // Style for bolus value - matches time value styling
    final bolusValueStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w500,
      color: theme.colorScheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // Determine bolus value - show "-- mL" for models that don't support bolus
    final bolusValue = data.totalBolus > 0.01 
        ? '${formatBolusValue(data.totalBolus)} mL'
        : '-- mL';

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.primary, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Bolus label (30%)
          Expanded(
            flex: 30,
            child: Text(AppLocalizations.of(context)!.bolus, style: headerStyle),
          ),
          // Bolus value (70%) - matches time value styling
          Expanded(
            flex: 70,
            child: Text(
              bolusValue,
              style: bolusValueStyle,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.primary, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Time column (30%)
          Expanded(
            flex: 30,
            child: Text(AppLocalizations.of(context)!.time, style: headerStyle),
          ),
          // Rate column (70%)
          Expanded(
            flex: 70,
            child: Text(
              '${AppLocalizations.of(context)!.rate} (mL/hr)', 
              style: headerStyle, 
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, InfusionRegimeRow row, bool isFirstRow, bool isSelected, int index) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    
    // Highlight selected row
    final backgroundColor = isSelected 
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : Colors.transparent;

    // Format infusion rate - always show as integer
    final rateText = row.infusionRate < 0.1 
        ? '—'
        : row.infusionRate.round().toString();

    return GestureDetector(
      onTap: () {
        if (onRowTap != null) {
          onRowTap!(index);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor.withValues(alpha: 0.3), 
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          children: [
            // Time column (30%)
            Expanded(
              flex: 30,
              child: Text(
                row.timeString,
                style: bodyStyle?.copyWith(
                  fontWeight: isFirstRow ? FontWeight.w600 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            // Rate column (70%)
            Expanded(
              flex: 70,
              child: Text(
                rateText,
                style: bodyStyle?.copyWith(
                  fontWeight: FontWeight.normal,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Duration screen data structure
class DurationRowData {
  final int volume;
  final double duration;
  final bool isHighlighted;

  const DurationRowData({
    required this.volume,
    required this.duration,
    this.isHighlighted = false,
  });
}

class DurationDataTable extends StatelessWidget {
  final List<DurationRowData> rows;
  final int maxVisibleRows;
  final int? selectedRowIndex;
  final Function(int)? onRowTap;
  final ScrollController? scrollController;

  const DurationDataTable({
    super.key,
    required this.rows,
    this.maxVisibleRows = 6,
    this.selectedRowIndex,
    this.onRowTap,
    this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.primary, width: 1),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          Container(
            height: math.min(rows.length, maxVisibleRows) * 41.0,
            child: SingleChildScrollView(
              controller: scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: rows.asMap().entries.map((entry) {
                  final index = entry.key;
                  final row = entry.value;
                  final isSelected = selectedRowIndex == index;
                  return _buildDataRow(context, row, isSelected, index);
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
    );

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.primary, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          // Volume column (40%)
          Expanded(
            flex: 40,
            child: Row(
              children: [
                Icon(
                  Icons.science_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text('Volume', style: headerStyle),
              ],
            ),
          ),
          // Duration column (60%)
          Expanded(
            flex: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.watch_later_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  'Duration', 
                  style: headerStyle, 
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(BuildContext context, DurationRowData row, bool isSelected, int index) {
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );
    
    // Highlight selected row
    final backgroundColor = isSelected 
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : Colors.transparent;

    return GestureDetector(
      onTap: () {
        onRowTap?.call(index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.2), 
              width: 0.5
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            // Volume column (40%)
            Expanded(
              flex: 40,
              child: Text(
                '${row.volume} mL',
                style: bodyStyle?.copyWith(
                  fontWeight: row.isHighlighted ? FontWeight.bold : FontWeight.normal,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            // Duration column (60%)
            Expanded(
              flex: 60,
              child: Text(
                formatDurationAsHoursMinutes(row.duration),
                style: bodyStyle?.copyWith(
                  fontWeight: row.isHighlighted ? FontWeight.bold : FontWeight.normal,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}