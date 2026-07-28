import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class SideGlassNavigation extends StatelessWidget {
  const SideGlassNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final accent = AppTheme.accent(context);

    return Container(
      width: 250,
      height: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.glassBorder(context)),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2B7A78).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PlaqueCheck',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'AI Oral Suite',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 36),
          _SidebarItem(
            index: 0,
            iconData: Icons.home_rounded,
            label: 'Home',
            selectedIndex: selectedIndex,
            onTap: onTabSelected,
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            index: 1,
            iconData: Icons.document_scanner_outlined,
            label: 'Scan Teeth',
            selectedIndex: selectedIndex,
            onTap: onTabSelected,
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            index: 2,
            iconData: Icons.history_edu_outlined,
            label: 'Scan History',
            selectedIndex: selectedIndex,
            onTap: onTabSelected,
          ),
          const SizedBox(height: 8),
          _SidebarItem(
            index: 3,
            iconData: Icons.person_outline,
            label: 'Profile',
            selectedIndex: selectedIndex,
            onTap: onTabSelected,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondarySurface(context),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, size: 18, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Engine Active',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
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

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: AppTheme.isDark(context) ? 0.20 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: accent.withValues(alpha: 0.3))
              : Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(iconData, color: isSelected ? accent : muted, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accent : AppTheme.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
