import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/data')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) {
            switch (i) {
              case 0:
                context.go('/radar');
              case 1:
                context.go('/data');
              case 2:
                context.go('/settings');
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Text('\u{1F4E1}', style: TextStyle(fontSize: 20)),
              activeIcon: Text('\u{1F4E1}', style: TextStyle(fontSize: 20)),
              label: '\uB808\uC774\uB354',
            ),
            BottomNavigationBarItem(
              icon: Text('\u{1F4C1}', style: TextStyle(fontSize: 20)),
              activeIcon: Text('\u{1F4C1}', style: TextStyle(fontSize: 20)),
              label: '\uC790\uB8CC\uD568',
            ),
            BottomNavigationBarItem(
              icon: Text('\u2699\uFE0F', style: TextStyle(fontSize: 20)),
              activeIcon: Text('\u2699\uFE0F', style: TextStyle(fontSize: 20)),
              label: '\uC124\uC815',
            ),
          ],
        ),
      ),
    );
  }
}
