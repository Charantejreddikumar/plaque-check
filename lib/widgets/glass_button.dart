import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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
    final button = widget.isPrimary
        ? _buildFilledButton()
        : _buildOutlinedButton();
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      onPointerUp: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.99 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: button,
      ),
    );
  }

  Widget _buildFilledButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onPressed,
        icon: Icon(widget.icon, size: 19),
        label: Text(widget.label),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.onPressed,
        icon: Icon(widget.icon, size: 19, color: AppTheme.highlight(context)),
        label: Text(widget.label),
      ),
    );
  }
}
