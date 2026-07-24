import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'glass_card.dart';

class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapCancel: () => setState(() => _isPressed = false),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.isPrimary ? _buildGradientButton() : _buildGlassButton(),
      ),
    );
  }

  Widget _buildGradientButton() {
    final isDark = AppTheme.isDark(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.42),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF60A5FA,
            ).withValues(alpha: isDark ? 0.24 : 0.18),
            blurRadius: isDark ? 28 : 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: _ButtonContent(
        icon: widget.icon,
        label: widget.label,
        color: Colors.white,
      ),
    );
  }

  Widget _buildGlassButton() {
    final accent = AppTheme.accentSoft(context);
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
      opacity: 0.12,
      borderOpacity: 0.30,
      glowColor: AppTheme.accent(context),
      child: _ButtonContent(
        icon: widget.icon,
        label: widget.label,
        color: accent,
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
