import 'dart:math';
import 'package:flutter/material.dart';

/// WeeklyBarChartPainter implemented using CustomPainter
/// Direct implementation of Week 8 Canvas Drawing
class WeeklyBarChartPainter extends CustomPainter {
  final Map<int, double> weeklyData; // 1 (Mon) -> 7 (Sun)
  final double progress; // 0.0 -> 1.0
  final Color barColor;
  final Color activeBarColor;
  final Color gridLineColor;
  final Color labelColor;
  final int todayWeekday;

  WeeklyBarChartPainter({
    required this.weeklyData,
    required this.progress,
    required this.barColor,
    required this.activeBarColor,
    required this.gridLineColor,
    required this.labelColor,
    required this.todayWeekday,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double bottomMargin = 28.0;
    const double topMargin = 24.0;
    final chartHeight = size.height - bottomMargin - topMargin;
    final chartWidth = size.width;

    // Determine max value for vertical scaling
    double maxVal = 0;
    for (final v in weeklyData.values) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) maxVal = 100000; // Default scale if empty

    // 1. Draw subtle horizontal guide lines
    final gridPaint = Paint()
      ..color = gridLineColor
      ..strokeWidth = 0.8;

    for (int i = 0; i <= 3; i++) {
      final y = topMargin + chartHeight * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // 2. Draw 7 daily bars
    const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    final slotWidth = chartWidth / 7;
    final barWidth = slotWidth * 0.44;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 1; i <= 7; i++) {
      final amount = weeklyData[i] ?? 0.0;
      final isToday = (i == todayWeekday);
      final xCenter = slotWidth * (i - 1) + (slotWidth / 2);

      // Compute animated bar height
      final barHeight = (amount / maxVal) * chartHeight * progress;
      final barTop = topMargin + (chartHeight - barHeight);
      final barRect = Rect.fromLTWH(
        xCenter - (barWidth / 2),
        barTop,
        barWidth,
        max(barHeight, 4.0),
      );
      final rrect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
        bottomLeft: const Radius.circular(3),
        bottomRight: const Radius.circular(3),
      );

      // Paint with vertical gradient for premium feel
      final barPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: isToday
              ? [activeBarColor, activeBarColor.withValues(alpha: 0.75)]
              : [barColor, barColor.withValues(alpha: 0.4)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(barRect);

      canvas.drawRRect(rrect, barPaint);

      // Draw day label text below bar
      textPainter.text = TextSpan(
        text: days[i - 1],
        style: TextStyle(
          color: isToday ? activeBarColor : labelColor,
          fontSize: 11.5,
          fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
        ),
      );
      textPainter.layout(minWidth: slotWidth, maxWidth: slotWidth);
      textPainter.paint(
        canvas,
        Offset(slotWidth * (i - 1), size.height - bottomMargin + 8),
      );

      // Draw small amount label if value exists and progress is near complete
      if (amount > 0 && progress > 0.75) {
        final amountText = _formatShortAmount(amount);
        textPainter.text = TextSpan(
          text: amountText,
          style: TextStyle(
            color: isToday ? activeBarColor : labelColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        );
        textPainter.layout(minWidth: slotWidth + 12, maxWidth: slotWidth + 12);
        textPainter.paint(
          canvas,
          Offset(xCenter - (textPainter.width / 2), max(barTop - 15, 2.0)),
        );
      }
    }
  }

  String _formatShortAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant WeeklyBarChartPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.weeklyData != weeklyData ||
      oldDelegate.activeBarColor != activeBarColor;
}
