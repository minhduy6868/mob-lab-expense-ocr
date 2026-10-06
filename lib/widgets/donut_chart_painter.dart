import 'dart:math';
import 'package:flutter/material.dart';

/// DonutChartPainter implemented using CustomPainter
/// Direct implementation of Week 8 Slide 33 & 34 with active slice highlight support
class DonutChartPainter extends CustomPainter {
  final List<double> percentages; // [0.4, 0.35, 0.25]
  final List<Color> colors;
  final double progress; // 0.0 -> 1.0
  final double strokeWidth;
  final Color trackColor;
  final int? selectedIndex;

  const DonutChartPainter({
    required this.percentages,
    required this.colors,
    required this.progress,
    this.strokeWidth = 22.0,
    this.trackColor = const Color(0x1F000000),
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = (min(size.width, size.height) - strokeWidth - 10) / 2;

    // 1. Draw subtle background track ring
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, baseRadius, trackPaint);

    if (percentages.isEmpty) return;

    // 2. Draw animated category arcs
    double startAngle = -pi / 2; // Start at 12 o'clock

    for (int i = 0; i < percentages.length; i++) {
      final sweep = (2 * pi * percentages[i]) * progress;
      if (sweep <= 0.001) continue;

      final isSelected = selectedIndex == i;
      final currentStroke = isSelected ? strokeWidth + 6.0 : strokeWidth;
      final currentRadius = isSelected ? baseRadius + 2.0 : baseRadius;
      final arcRect = Rect.fromCircle(center: center, radius: currentRadius);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.round
        ..color = colors[i % colors.length];

      if (isSelected) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);
      }

      canvas.drawArc(arcRect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter old) =>
      old.progress != progress ||
      old.percentages != percentages ||
      old.colors != colors ||
      old.selectedIndex != selectedIndex;
}
