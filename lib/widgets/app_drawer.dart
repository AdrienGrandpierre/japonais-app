import 'package:flutter/material.dart';

import '../enums/quiz_mode.dart';
import '../models/phrase.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.phrases,
    required this.currentRoute,
    this.phrasePerformance = const {},
    this.onNavigateToTraining,
  });

  final List<Phrase> phrases;
  final AppRoute currentRoute;
  final Map<String, int> phrasePerformance;
  final VoidCallback? onNavigateToTraining;

  Widget _drawerItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: isActive ? color.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive
                      ? color
                      : enabled
                      ? null
                      : Colors.grey,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isActive
                          ? color
                          : enabled
                          ? null
                          : Colors.grey,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Japonais App',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentRoute == AppRoute.home ? 'Accueil' : 'Entraînement',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _drawerItem(
            context: context,
            icon: Icons.home,
            label: 'Accueil',
            isActive: currentRoute == AppRoute.home,
            enabled: true,
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
          _drawerItem(
            context: context,
            icon: Icons.menu_book,
            label: 'Entraînement',
            isActive: currentRoute == AppRoute.training,
            enabled: phrases.isNotEmpty,
            onTap: currentRoute == AppRoute.training
                ? () => Navigator.pop(context)
                : () {
                    Navigator.pop(context);
                    onNavigateToTraining?.call();
                  },
          ),
        ],
      ),
    );
  }
}
