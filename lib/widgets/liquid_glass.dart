import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/theme.dart';

class LiquidBackdrop extends StatelessWidget {
  final Widget child;

  const LiquidBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppColors.nightTop, AppColors.nightMid, AppColors.night]
              : const [Color(0xFFD7E3F6), AppColors.paper, Color(0xFFC9D8F0)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _orb(isDark ? AppColors.gold.withValues(alpha: 0.20) : AppColors.gold.withValues(alpha: 0.35), 180),
          ),
          Positioned(
            bottom: 80,
            left: -60,
            child: _orb(
              isDark ? const Color(0xFF8AA4D4).withValues(alpha: 0.10) : Colors.white.withValues(alpha: 0.7),
              220,
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _orb(Color color, double size) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class GlassSurface extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const GlassSurface({
    super.key,
    required this.child,
    this.radius = 18,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shape = BorderRadius.circular(radius);
    Widget body = child;
    if (padding != null) body = Padding(padding: padding!, child: body);
    if (onTap != null || onLongPress != null) {
      body = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: shape,
          child: body,
        ),
      );
    }

    final glass = ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [AppColors.nightGlassTop, AppColors.nightGlassBottom]
                  : [
                      Colors.white.withValues(alpha: 0.58),
                      Colors.white.withValues(alpha: 0.28),
                    ],
            ),
            border: Border.all(
              color: isDark ? AppColors.gold.withValues(alpha: 0.42) : Colors.white.withValues(alpha: 0.74),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: isDark ? 14 : 32,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        isDark ? AppColors.paper.withValues(alpha: 0.14) : Colors.white.withValues(alpha: 0.50),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
              body,
            ],
          ),
        ),
      ),
    );

    if (margin == null) return glass;
    return Padding(padding: margin!, child: glass);
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final double radius;

  const GlassCard({super.key, required this.child, this.margin, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(margin: margin, radius: radius, child: child);
  }
}
