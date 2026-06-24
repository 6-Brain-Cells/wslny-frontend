import 'package:flutter/material.dart';
import 'package:wslny/l10n/app_localizations.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppLocalizations l10n;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: NavigationBar(
        height: 70,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        backgroundColor: Colors.transparent,
        indicatorColor: theme.colorScheme.primary.withOpacity(0.2),
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            selectedIcon: Icon(Icons.home, color: theme.colorScheme.primary),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            selectedIcon: Icon(Icons.favorite, color: theme.colorScheme.primary),
            label: l10n.navFavorites,
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            selectedIcon: Icon(Icons.person, color: theme.colorScheme.primary),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }
}
