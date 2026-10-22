import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.onSurfaceVariant,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'Activités',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_basket_outlined),
          activeIcon: Icon(Icons.shopping_basket),
          label: 'Panier',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profil',
        ),
      ],
      onTap: onTap,
    );
  }
}
