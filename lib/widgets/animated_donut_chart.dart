import 'package:flutter/material.dart';
import '../core/formatters.dart';
import '../models/expense_category.dart';
import 'donut_chart_painter.dart';

/// Interactive Animated Donut Chart Widget
/// Connects CustomPainter with AnimationController and AnimatedBuilder (Slide 34)
/// Supports tap selection to drill down into category details.
class AnimatedDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> data;
  final double totalAmount;

  const AnimatedDonutChart({
    super.key,
    required this.data,
    required this.totalAmount,
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalAmount != widget.totalAmount ||
        oldWidget.data != widget.data) {
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
    final sortedEntries = widget.data.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final total = widget.totalAmount;
    final percentages = total > 0
        ? sortedEntries.map((e) => e.value / total).toList()
        : <double>[];
    final colors = sortedEntries.map((e) => e.key.color).toList();

    // Center display logic based on selection
    final selectedEntry = (_selectedIndex != null && _selectedIndex! < sortedEntries.length)
        ? sortedEntries[_selectedIndex!]
        : null;

    final centerLabel = selectedEntry != null
        ? selectedEntry.key.displayName.split(' & ')[0]
        : 'Tổng chi tiêu';

    final centerAmount = selectedEntry != null
        ? Formatters.formatVND(selectedEntry.value)
        : Formatters.formatVND(widget.totalAmount);

    final centerPct = (selectedEntry != null && total > 0)
        ? '${(selectedEntry.value / total * 100).toStringAsFixed(1)}%'
        : '${sortedEntries.length} danh mục';

    return Column(
      children: [
        SizedBox(
          width: 230,
          height: 230,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, _) => CustomPaint(
                  size: const Size(220, 220),
                  painter: DonutChartPainter(
                    percentages: percentages,
                    colors: colors,
                    progress: _animation.value,
                    trackColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    selectedIndex: _selectedIndex,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(60),
                onTap: () {
                  setState(() => _selectedIndex = null);
                },
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: selectedEntry?.key.color ?? theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        centerAmount,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                          fontSize: 16.5,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: (selectedEntry?.key.color ?? theme.colorScheme.primary).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          centerPct,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: selectedEntry?.key.color ?? theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Interactive Category Chips Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(sortedEntries.length, (idx) {
              final e = sortedEntries[idx];
              final isSelected = _selectedIndex == idx;
              final pct = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _selectedIndex = isSelected ? null : idx;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? e.key.color.withValues(alpha: 0.22)
                        : e.key.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? e.key.color : e.key.color.withValues(alpha: 0.25),
                      width: isSelected ? 1.6 : 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: e.key.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${e.key.displayName.split(' & ')[0]}: $pct%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? e.key.color : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
