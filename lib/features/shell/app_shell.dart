import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../data/models/event_model.dart';

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
    final theme = Theme.of(context);
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isDesktop,
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(items[i].path),
            leading: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _PlaneaLogo(compact: !isDesktop),
                  const SizedBox(height: 24),
                  if (isDesktop) _EventSwitcher(),
                  const SizedBox(height: 8),
                  const Divider(),
                ],
              ),
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

class _EventSwitcher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    final userId = auth.currentUser?.uid ?? '';

    return StreamBuilder<List<EventModel>>(
      stream: eventProvider.watchUserEvents(userId),
      builder: (context, snapshot) {
        final events = snapshot.data ?? [];
        if (events.isEmpty) return const SizedBox.shrink();

        if (eventProvider.currentEventId == null && events.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            eventProvider.setCurrentEventId(events.first.id);
          });
        }

        final currentEvent = events.firstWhere(
          (e) => e.id == eventProvider.currentEventId,
          orElse: () => events.first,
        );

        return Container(
          width: 220,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.2)),
          ),
          child: PopupMenuButton<String>(
            tooltip: "Cambiar evento",
            offset: const Offset(0, 45),
            onSelected: (id) => eventProvider.setCurrentEventId(id),
            itemBuilder: (context) => events.map((e) => PopupMenuItem<String>(
              value: e.id,
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: e.primaryColor),
                  const SizedBox(width: 12),
                  Text(e.name, style: theme.textTheme.bodyMedium),
                ],
              ),
            )).toList(),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: currentEvent.primaryColor,
                  child: const Icon(Icons.star, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentEvent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Evento activo",
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                if (events.length > 1)
                  const Icon(Icons.unfold_more_rounded, size: 18, color: Colors.white54),
              ],
            ),
          ),
        );
      },
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
