import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../data/models/guest_model.dart';
import '../../data/models/event_model.dart';
import '../../data/services/firestore_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';
import '../shared/widgets/stat_card.dart';
import '../shared/widgets/celebration_progress_bar.dart';
import '../shared/widgets/guest_role_chip.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final auth = context.read<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    final userId = auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navDashboard),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.charcoal, size: 14),
                  const SizedBox(width: 4),
                  Text(l.premiumBadge,
                      style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.charcoal, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: FirestoreService().watchUserEvents(userId),
        builder: (context, eventSnap) {
          final events = eventSnap.data ?? [];
          final currentEventId = eventProvider.currentEventId ??
              (events.isNotEmpty ? events.first.id : null);

          if (currentEventId == null) return _EmptyDashboard();

          return StreamBuilder<List<GuestModel>>(
            stream: FirestoreService().watchGuests(currentEventId),
            builder: (context, guestSnap) {
              final guests = guestSnap.data ?? [];
              final confirmedGroups = guests.where((g) => g.status == GuestStatus.confirmed).length;
              final pendingGroups = guests.where((g) => g.status == GuestStatus.pending).length;
              final declinedGroups = guests.where((g) => g.status == GuestStatus.declined).length;

              final totalPeopleConfirmed = guests
                  .where((g) => g.status == GuestStatus.confirmed)
                  .fold<int>(0, (sum, g) => sum + g.totalSeats);
              final totalPeoplePending = guests
                  .where((g) => g.status == GuestStatus.pending)
                  .fold<int>(0, (sum, g) => sum + g.totalSeats);
              
              final totalExpected = guests.fold<int>(0, (sum, g) => sum + g.totalSeats);
              final progress = totalExpected > 0 ? totalPeopleConfirmed / totalExpected : 0.0;

              final currentEvent = events.firstWhere(
                (e) => e.id == currentEventId,
                orElse: () => events.first,
              );

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _DashboardHeader(event: currentEvent)),
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CelebrationProgressBar(
                            progress: progress,
                            confirmed: totalPeopleConfirmed,
                            total: totalExpected,
                          ),
                          const SizedBox(height: 24),
                          Text(l.guestSummary,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _StatsRow(
                            confirmed: confirmedGroups,
                            pending: pendingGroups,
                            declined: declinedGroups,
                          ),
                          const SizedBox(height: 24),
                          if (events.length > 1) ...[
                            Text(l.myEvents,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            _EventSelectorRow(events: events),
                            const SizedBox(height: 24),
                          ],
                          Text(l.recentActivity,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.separated(
                      itemCount: guests.take(5).length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _GuestTile(guest: guests[i]),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final EventModel event;
  const _DashboardHeader({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [event.primaryColor, event.secondaryColor],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: event.secondaryColor.withValues(alpha: 0.3),
            blurRadius: 24, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  '${_localizedType(l, event.type)} • ${event.date.day}/${event.date.month}/${event.date.year}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.white70, letterSpacing: 0.5),
                ),
                if (event.venue != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_outlined,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(event.venue!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.white70)),
                  ]),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.celebration_rounded,
                color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }

  String _localizedType(AppLocalizations l, EventType t) {
    switch (t) {
      case EventType.wedding: return l.typeWedding;
      case EventType.quinceanera: return l.typeQuinceanera;
      case EventType.birthday: return l.typeBirthday;
      case EventType.corporate: return l.typeCorporate;
      case EventType.graduation: return l.typeGraduation;
      case EventType.other: return l.typeOther;
    }
  }
}

class _StatsRow extends StatelessWidget {
  final int confirmed, pending, declined;
  const _StatsRow({required this.confirmed, required this.pending, required this.declined});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        Expanded(child: StatCard(label: l.statConfirmed, value: confirmed.toString(),
            icon: Icons.check_circle_rounded, color: AppColors.confirmed)),
        const SizedBox(width: 12),
        Expanded(child: StatCard(label: l.statPending, value: pending.toString(),
            icon: Icons.schedule_rounded, color: AppColors.pending)),
        const SizedBox(width: 12),
        Expanded(child: StatCard(label: l.statDeclined, value: declined.toString(),
            icon: Icons.cancel_rounded, color: AppColors.declined)),
      ],
    );
  }
}

class _GuestTile extends StatelessWidget {
  final GuestModel guest;
  const _GuestTile({required this.guest});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final statusColor = guest.status == GuestStatus.confirmed
        ? AppColors.confirmed
        : guest.status == GuestStatus.pending
            ? AppColors.pending
            : AppColors.declined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: statusColor.withValues(alpha: 0.15),
            child: Text(
              guest.displayName.isNotEmpty ? guest.displayName[0].toUpperCase() : '?',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guest.displayName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GuestRoleChip(role: guest.role),
                    if (guest.totalSeats > 1) ...[
                      const SizedBox(width: 8),
                      Text('• ${guest.totalSeats} pers.', style: theme.textTheme.labelSmall?.copyWith(color: Colors.white54)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusLabel(l, guest.status),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l, GuestStatus s) {
    switch (s) {
      case GuestStatus.confirmed: return l.guestConfirmed;
      case GuestStatus.pending: return l.guestPending;
      case GuestStatus.declined: return l.guestDeclined;
    }
  }
}

class _EventSelectorRow extends StatelessWidget {
  final List<EventModel> events;
  const _EventSelectorRow({required this.events});

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = events[i];
          final selected = e.id == eventProvider.currentEventId;
          return ChoiceChip(
            label: Text(e.name),
            selected: selected,
            onSelected: (_) => eventProvider.setCurrentEventId(e.id),
          );
        },
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient, shape: BoxShape.circle),
            child: const Icon(Icons.add_circle_outline_rounded,
                size: 48, color: AppColors.charcoal),
          ),
          const SizedBox(height: 20),
          Text(l.noEventsYet,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(l.noEventsYetSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}
