/// Floating, rounded bottom navigation bar per the Ekalivan design system.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme_extension.dart';

/// One destination in [BottomNav].
class BottomNavItem {
  /// Creates a bottom navigation destination.
  const BottomNavItem({required this.icon, required this.label});

  /// Icon shown for this destination.
  final IconData icon;

  /// Label shown under the icon.
  final String label;
}

/// Floating white bottom navigation bar with rounded top corners, a blue
/// active icon, and a gray inactive icon.
class BottomNav extends StatelessWidget {
  /// Creates the bottom navigation bar.
  const BottomNav({super.key, required this.items, required this.currentIndex, required this.onTap});

  /// Destinations to show.
  final List<BottomNavItem> items;

  /// Currently selected index.
  final int currentIndex;

  /// Invoked with the tapped index.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final EkalivanThemeExtension tokens =
        Theme.of(context).extension<EkalivanThemeExtension>() ?? EkalivanThemeExtension.standard;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: tokens.softShadow,
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          for (int i = 0; i < items.length; i++)
            _BottomNavButton(item: items[i], selected: i == currentIndex, onTap: () => onTap(i)),
        ],
      ),
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({required this.item, required this.selected, required this.onTap});

  final BottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.primaryBlue : Colors.grey.shade400;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(item.icon, color: color),
              const SizedBox(height: 2),
              Text(item.label, style: TextStyle(color: color, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}
