import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/design_tokens.dart';
import '../models/infusion_regime_data.dart';

class InfusionRateChart extends StatefulWidget {
  final InfusionRegimeData data;
  final TimeOfDay? startTime;

  const InfusionRateChart({
    super.key,
    required this.data,
    this.startTime,
  });

  @override
  State<InfusionRateChart> createState() => _InfusionRateChartState();
}

class _InfusionRateChartState extends State<InfusionRateChart> {
  int? _hoveredIndex;

  String _formatTooltipTime(int index) {
    final row = widget.data.rows[index];
    if (widget.startTime != null) {
      final elapsed = row.time.inMinutes;
      final totalMins =
          widget.startTime!.hour * 60 + widget.startTime!.minute + elapsed;
      final h = totalMins ~/ 60 % 24;
      final m = totalMins % 60;
      final p = h >= 12 ? 'PM' : 'AM';
      final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$h12:${m.toString().padLeft(2, '0')} $p';
    }
    return row.timeString;
  }

  String _formatRate(double rate) {
    return rate >= 10 ? rate.toStringAsFixed(0) : rate.toStringAsFixed(1);
  }

  int? _hitTest(Offset localPos, double leftPad, double chartW, int n) {
    if (n <= 1) return null;
    for (int i = 0; i < n; i++) {
      final x = leftPad + chartW * i / (n - 1);
      if ((localPos.dx - x).abs() <= 12) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.rows.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final rates = widget.data.rows.map((r) => r.infusionRate).toList();
    final maxRate = rates.reduce((a, b) => a > b ? a : b);
    const leftPad = 40.0, rightPad = 12.0, topPad = 8.0, bottomPad = 20.0;

    final tooltipText = _hoveredIndex != null
        ? '${_formatTooltipTime(_hoveredIndex!)}  |  ${_formatRate(rates[_hoveredIndex!])} mL/hr'
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(kRadius),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (event) {
          final size = context.size;
          if (size == null) return;
          final chartW =
              (size.width - leftPad - rightPad).clamp(0.0, double.infinity);
          final hit =
              _hitTest(event.localPosition, leftPad, chartW, rates.length);
          if (hit != _hoveredIndex) setState(() => _hoveredIndex = hit);
        },
        onExit: (_) {
          if (_hoveredIndex != null) setState(() => _hoveredIndex = null);
        },
        child: GestureDetector(
          onTapDown: (details) {
            final size = context.size;
            if (size == null) return;
            final chartW =
                (size.width - leftPad - rightPad).clamp(0.0, double.infinity);
            final hit = _hitTest(
                details.localPosition, leftPad, chartW, rates.length);
            if (hit != null) {
              setState(
                  () => _hoveredIndex = _hoveredIndex == hit ? null : hit);
            }
          },
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _ChartPainter(
                  data: widget.data,
                  maxRate: maxRate,
                  lineColor: theme.colorScheme.primary,
                  fillColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                  gridColor:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  labelColor: theme.colorScheme.outline,
                  hoveredIndex: _hoveredIndex,
                  leftPad: leftPad,
                  rightPad: rightPad,
                  topPad: topPad,
                  bottomPad: bottomPad,
                ),
              ),
              if (tooltipText != null)
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.inverseSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tooltipText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onInverseSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final InfusionRegimeData data;
  final double maxRate;
  final Color lineColor, fillColor, gridColor, labelColor;
  final int? hoveredIndex;
  final double leftPad, rightPad, topPad, bottomPad;

  _ChartPainter({
    required this.data,
    required this.maxRate,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.labelColor,
    this.hoveredIndex,
    required this.leftPad,
    required this.rightPad,
    required this.topPad,
    required this.bottomPad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.rows.isEmpty || maxRate <= 0) return;
    final rates = data.rows.map((r) => r.infusionRate).toList();
    final n = rates.length;
    final chartW = math.max(0, size.width - leftPad - rightPad);
    final chartH = math.max(0, size.height - topPad - bottomPad);

    final gridPaint = Paint()..color = gridColor..strokeWidth = 0.5;
    final labelStyle = TextStyle(color: labelColor, fontSize: 9);
    for (int i = 0; i <= 3; i++) {
      final y = topPad + chartH * (1 - i / 3);
      canvas.drawLine(
          Offset(leftPad, y), Offset(size.width - rightPad, y), gridPaint);
      final val = (maxRate * i / 3);
      final label =
          val >= 10 ? val.toStringAsFixed(0) : val.toStringAsFixed(1);
      final tp = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPad - 4);
      tp.paint(canvas, Offset(leftPad - tp.width - 4, y - tp.height / 2));
    }

    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final x = leftPad + chartW * i / (n - 1);
      final y = topPad + chartH * (1 - rates[i] / maxRate);
      points.add(Offset(x, y));
    }

    if (points.length >= 2) {
      final fillPath = Path()
        ..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      fillPath.lineTo(points.last.dx, topPad + chartH);
      fillPath.lineTo(points.first.dx, topPad + chartH);
      fillPath.close();
      canvas.drawPath(
          fillPath, Paint()..color = fillColor..style = PaintingStyle.fill);
    }

    if (points.length >= 2) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final linePath = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    if (hoveredIndex != null &&
        hoveredIndex! >= 0 &&
        hoveredIndex! < points.length) {
      final hp = points[hoveredIndex!];
      canvas.drawLine(
        Offset(hp.dx, topPad),
        Offset(hp.dx, topPad + chartH),
        Paint()
          ..color = lineColor.withValues(alpha: 0.3)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
      canvas.drawCircle(
          hp, 5, Paint()..color = lineColor..style = PaintingStyle.fill);
      canvas.drawCircle(
          hp, 5,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter o) =>
      data != o.data || maxRate != o.maxRate || hoveredIndex != o.hoveredIndex;
}
