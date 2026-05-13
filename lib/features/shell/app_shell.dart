import 'dart:ui';
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
    final paths = ['/dashboard', '/guests', '/tables', '/events', '/settings'];
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
      _NavItem(icon: Icons.table_restaurant_rounded, label: l.navTables, path: '/tables'),
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final isDesktop = ResponsiveBreakpoints.of(context).largerThan(TABLET);
    
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isDesktop ? 260 : 80,
            height: double.infinity,
            decoration: BoxDecoration(
              color: (isDark ? AppColors.charcoal : Colors.white).withValues(alpha: 0.95),
              border: Border(right: BorderSide(color: AppColors.brushedGold.withValues(alpha: 0.1))),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _PlaneaLogo(compact: !isDesktop),
                ),
                const SizedBox(height: 32),
                if (isDesktop) Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _EventSwitcher(),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Divider(color: Colors.white10),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final isSelected = selectedIndex == index;
                      return _SidebarItem(
                        item: item,
                        isSelected: isSelected,
                        compact: !isDesktop,
                        onTap: () => context.go(item.path),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppColors.brushedGold.withValues(alpha: 0.08) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? AppColors.brushedGold.withValues(alpha: 0.1) 
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                item.icon,
                size: 24,
                color: isSelected ? AppColors.brushedGold : baseColor.withValues(alpha: 0.4),
              ),
              if (!compact) ...[
                const SizedBox(width: 16),
                Text(
                  item.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isSelected ? AppColors.brushedGold : baseColor.withValues(alpha: 0.6),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
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

    final isDark = theme.brightness == Brightness.dark;

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

        return InkWell(
          onTap: () => _showEventPicker(context, events, eventProvider),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brushedGold.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: currentEvent.primaryColor,
                    child: const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                  ),
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 6, height: 6,
                            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "EVENTO ACTIVO",
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 9, 
                              fontWeight: FontWeight.w900,
                              color: AppColors.brushedGold.withValues(alpha: 0.7),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.unfold_more_rounded, size: 18, color: AppColors.brushedGold.withValues(alpha: 0.5)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEventPicker(BuildContext context, List<EventModel> events, EventProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = context.l10n;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (isDark ? AppColors.charcoal : Colors.white).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.2)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, 
                  height: 4, 
                  decoration: BoxDecoration(
                    color: AppColors.brushedGold.withValues(alpha: 0.2), 
                    borderRadius: BorderRadius.circular(2)
                  )
                ),
                const SizedBox(height: 20),
                const Text(
                  "MIS EVENTOS", 
                  style: TextStyle(
                    color: AppColors.brushedGold, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 11, 
                    letterSpacing: 2
                  )
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final e = events[index];
                      final isSelected = e.id == provider.currentEventId;
                      
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          provider.setCurrentEventId(e.id);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.brushedGold.withValues(alpha: 0.05) 
                                : Colors.transparent,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? AppColors.brushedGold : Colors.transparent, 
                                width: 4
                              )
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(color: e.primaryColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  e.name, 
                                  style: TextStyle(
                                    color: isSelected 
                                        ? AppColors.brushedGold 
                                        : (isDark ? Colors.white : Colors.black87), 
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (isSelected) 
                                const Icon(
                                  Icons.check_circle_rounded, 
                                  color: AppColors.brushedGold, 
                                  size: 18
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
