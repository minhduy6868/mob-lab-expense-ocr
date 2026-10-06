import 'package:flutter/material.dart';
import 'weekly_bar_chart_painter.dart';

/// Animated Weekly Bar Chart Widget
/// Connects WeeklyBarChartPainter with AnimationController and AnimatedBuilder
class AnimatedBarChart extends StatefulWidget {
  final Map<int, double> weeklyData;

  const AnimatedBarChart({
    super.key,
    required this.weeklyData,
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyData != widget.weeklyData) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayWeekday = DateTime.now().weekday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AspectRatio(
        aspectRatio: 1.8,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) => CustomPaint(
            painter: WeeklyBarChartPainter(
              weeklyData: widget.weeklyData,
              progress: _animation.value,
              barColor: theme.colorScheme.primary.withValues(alpha: 0.35),
              activeBarColor: theme.colorScheme.primary,
              gridLineColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
              labelColor: theme.colorScheme.onSurfaceVariant,
              todayWeekday: todayWeekday,
            ),
          ),
        ),
      ),
    );
  }
}
