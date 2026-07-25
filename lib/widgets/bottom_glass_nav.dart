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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.glassBorder(context)),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
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
    final accent = AppTheme.accent(context);
    final muted = AppTheme.textSecondary(context);

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: AppTheme.isDark(context) ? 0.18 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, color: isSelected ? accent : muted, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accent : muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
