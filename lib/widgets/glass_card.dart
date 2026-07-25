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
    final radius = borderRadius;
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppTheme.glassBorder(context)),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );

    if (onTap == null) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(radius),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
