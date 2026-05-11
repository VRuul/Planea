import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final paths = ['/dashboard', '/guests', '/events', '/settings'];
    for (int i = 0; i < paths.length; i++) {
      if (location.startsWith(paths[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final items = [
      _NavItem(icon: Icons.dashboard_rounded, label: l.navDashboard, path: '/dashboard'),
      _NavItem(icon: Icons.people_rounded, label: l.navGuests, path: '/guests'),
      _NavItem(icon: Icons.celebration_rounded, label: l.navEvents, path: '/events'),
      _NavItem(icon: Icons.settings_rounded, label: l.navSettings, path: '/settings'),
    ];

    final isDesktopOrTablet = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final selectedIndex = _selectedIndex(context);

    if (isDesktopOrTablet) {
      return _DesktopShell(items: items, selectedIndex: selectedIndex, child: child);
    }
    return _MobileShell(items: items, selectedIndex: selectedIndex, child: child);
  }
}

class _DesktopShell extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final Widget child;

  const _DesktopShell({required this.items, required this.selectedIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isDesktop,
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(items[i].path),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: _PlaneaLogo(compact: !isDesktop),
            ),
            destinations: items
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.icon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final Widget child;

  const _MobileShell({required this.items, required this.selectedIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) => context.go(items[i].path),
        destinations: items
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.icon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _PlaneaLogo extends StatelessWidget {
  final bool compact;
  const _PlaneaLogo({this.compact = false});

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
      child: const Icon(Icons.celebration_rounded, color: AppColors.charcoal, size: 22),
    );
    if (compact) return circle;
    return Row(
      children: [
        circle,
        const SizedBox(width: 12),
        Text(
          'Planea',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.brushedGold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  const _NavItem({required this.icon, required this.label, required this.path});
}
