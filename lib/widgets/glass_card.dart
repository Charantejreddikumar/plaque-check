import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 28,
    this.opacity = 0.14,
    this.borderOpacity = 0.18,
    this.glowColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double opacity;
  final double borderOpacity;
  final Color? glowColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final glassColor = Colors.white;
    final shadowColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFF3B82F6);
    final resolvedOpacity = isDark ? opacity : (opacity + 0.28).clamp(0, 0.56);
    final resolvedBorderOpacity = isDark
        ? borderOpacity
        : (borderOpacity + 0.18).clamp(0, 0.52);
    final borderColor = AppTheme.glassBorder(context);
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor.withValues(alpha: resolvedOpacity.toDouble()),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Color.alphaBlend(
                Colors.white.withValues(
                  alpha: resolvedBorderOpacity.toDouble(),
                ),
                borderColor,
              ),
              width: 1.15,
            ),
            boxShadow: glowColor == null
                ? [
                    BoxShadow(
                      color: shadowColor.withValues(
                        alpha: isDark ? 0.16 : 0.08,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: shadowColor.withValues(
                        alpha: isDark ? 0.18 : 0.09,
                      ),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: glowColor!.withValues(alpha: isDark ? 0.18 : 0.12),
                      blurRadius: 28,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
