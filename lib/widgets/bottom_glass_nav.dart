import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BottomGlassNavigation extends StatelessWidget {
  const BottomGlassNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 20,
            left: 24,
            right: 24,
          ),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF1E3A5F) : Colors.white).withValues(
              alpha: isDark ? 0.70 : 0.78,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.glassBorder(context),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0EA5E9).withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _TabItem(
                index: 0,
                iconData: Icons.home_rounded,
                label: 'Home',
                selectedIndex: selectedIndex,
                onTap: onTabSelected,
              ),
              _TabItem(
                index: 1,
                iconData: Icons.document_scanner_outlined,
                label: 'Scan',
                selectedIndex: selectedIndex,
                onTap: onTabSelected,
              ),
              _TabItem(
                index: 2,
                iconData: Icons.history_edu_outlined,
                label: 'History',
                selectedIndex: selectedIndex,
                onTap: onTabSelected,
              ),
              _TabItem(
                index: 3,
                iconData: Icons.person_outline,
                label: 'Profile',
                selectedIndex: selectedIndex,
                onTap: onTabSelected,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.index,
    required this.iconData,
    required this.label,
    required this.selectedIndex,
    required this.onTap,
  });

  final int index;
  final IconData iconData;
  final String label;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    final accent = AppTheme.accentSoft(context);
    final muted = AppTheme.textSecondary(context);

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppTheme.glassBorder(context)
                : Colors.transparent,
            width: 1.1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: isSelected ? accent : muted, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? accent : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
