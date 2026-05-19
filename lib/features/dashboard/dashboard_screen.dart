import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../data/models/guest_model.dart';
import '../../data/models/event_model.dart';
import '../../data/services/supabase_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';
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
    final userId = auth.currentUser?.id ?? '';

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
        stream: SupabaseService().watchUserEvents(userId),
        builder: (context, eventSnap) {
          final events = eventSnap.data ?? [];
          // Aseguramos que el ID actual sea válido y exista en la lista actual.
          final currentEventId = events.any((e) => e.id == eventProvider.currentEventId)
              ? eventProvider.currentEventId
              : (events.isNotEmpty ? events.first.id : null);

          if (currentEventId == null) return _EmptyDashboard();

          return StreamBuilder<List<GuestModel>>(
            stream: SupabaseService().watchGuests(currentEventId),
            builder: (context, guestSnap) {
              final guests = guestSnap.data ?? [];
              
              final confirmedGroups = guests.where((g) => g.status == GuestStatus.confirmed).length;
              final pendingGroups = guests.where((g) => g.status == GuestStatus.pending).length;
              final declinedGroups = guests.where((g) => g.status == GuestStatus.declined).length;

              final totalPeopleConfirmed = guests
                  .where((g) => g.status == GuestStatus.confirmed)
                  .fold<int>(0, (sum, g) => sum + g.totalSeats);
              
              final totalExpected = guests.fold<int>(0, (sum, g) => sum + g.totalSeats);
              final progress = totalExpected > 0 ? totalPeopleConfirmed / totalExpected : 0.0;

              final totalCheckedIn = guests
                  .where((g) => g.checkedIn)
                  .fold<int>(0, (sum, g) => sum + g.totalSeats);


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
                          _CateringAndAccessStats(
                            checkedIn: totalCheckedIn,
                            totalExpected: totalPeopleConfirmed,
                            guests: guests,
                            event: currentEvent,
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: AppColors.brushedGold.withValues(alpha: 0.05), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            // Glass background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                      isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                    ],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.brushedGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.celebration_rounded, color: AppColors.brushedGold, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: baseColor)),
                            Text(
                              '${_localizedType(l, event.type)} • ${event.date.day}/${event.date.month}/${event.date.year}',
                              style: theme.textTheme.labelSmall?.copyWith(color: baseColor.withValues(alpha: 0.5), letterSpacing: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _CountdownTimer(targetDate: event.date),
                  const SizedBox(height: 12),
                  Text("TIEMPO PARA LA CELEBRACIÓN", style: TextStyle(color: AppColors.brushedGold.withValues(alpha: 0.6), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ],
              ),
            ),
          ],
        ),
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

class _CountdownTimer extends StatefulWidget {
  final DateTime targetDate;
  const _CountdownTimer({required this.targetDate});

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _timeLeft = widget.targetDate.isAfter(now) ? widget.targetDate.difference(now) : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _TimeBlock(value: days.toString().padLeft(2, '0'), label: "DÍAS"),
        _TimeBlock(value: hours.toString().padLeft(2, '0'), label: "HORAS"),
        _TimeBlock(value: minutes.toString().padLeft(2, '0'), label: "MIN"),
        _TimeBlock(value: seconds.toString().padLeft(2, '0'), label: "SEG", isLast: true),
      ],
    );
  }
}

class _TimeBlock extends StatelessWidget {
  final String value;
  final String label;
  final bool isLast;
  const _TimeBlock({required this.value, required this.label, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.brushedGold, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ],
    );
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
        Expanded(child: _PremiumStatCard(label: l.statConfirmed, value: confirmed.toString(), icon: Icons.check_circle_rounded, color: AppColors.confirmed)),
        const SizedBox(width: 12),
        Expanded(child: _PremiumStatCard(label: l.statPending, value: pending.toString(), icon: Icons.schedule_rounded, color: AppColors.pending)),
        const SizedBox(width: 12),
        Expanded(child: _PremiumStatCard(label: l.statDeclined, value: declined.toString(), icon: Icons.cancel_rounded, color: AppColors.declined)),
      ],
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;

  const _PremiumStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.6), size: 20),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(color: baseColor, fontSize: 24, fontWeight: FontWeight.w900)),
          Text(label.toUpperCase(), style: TextStyle(color: baseColor.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        ],
      ),
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    
    final statusColor = guest.status == GuestStatus.confirmed
        ? AppColors.confirmed
        : guest.status == GuestStatus.pending
            ? AppColors.pending
            : AppColors.declined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.brushedGold.withValues(alpha: 0.1),
            child: Text(
              guest.displayName.isNotEmpty ? guest.displayName[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.brushedGold, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guest.displayName, style: TextStyle(color: baseColor, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    GuestRoleChip(role: guest.role),
                    if (guest.adults + guest.children + guest.teenagers + guest.disabled > 1) ...[
                      const SizedBox(width: 8),
                      Text('• ${guest.adults + guest.children + guest.teenagers + guest.disabled} pers.', style: TextStyle(color: baseColor.withValues(alpha: 0.4), fontSize: 11)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _statusLabel(l, guest.status).toUpperCase(),
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5),
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
            decoration: const BoxDecoration(
                gradient: AppColors.goldGradient, shape: BoxShape.circle),
            child: const Icon(Icons.event_busy_rounded,
                size: 48, color: AppColors.charcoal),
            ),
          const SizedBox(height: 20),
          Text(l.noEventsYet,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(l.noEventsYetSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go('/events'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.newEvent),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brushedGold,
              foregroundColor: AppColors.charcoal,
            ),
          ),
        ],
      ),
    );
  }
}

class _CateringAndAccessStats extends StatelessWidget {
  final int checkedIn;
  final int totalExpected;
  final List<GuestModel> guests;
  final EventModel event;

  const _CateringAndAccessStats({
    required this.checkedIn,
    required this.totalExpected,
    required this.guests,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, color: AppColors.brushedGold, size: 20),
              const SizedBox(width: 8),
              Text(
                "CATERING Y CONTROL DE ASISTENCIA",
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brushedGold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _AccessProgressTile(
                  label: "CHECK-IN (ASISTENCIA)",
                  value: "$checkedIn / $totalExpected",
                  progress: totalExpected > 0 ? checkedIn / totalExpected : 0.0,
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.confirmed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          if (event.menus.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: event.menus.map((menu) {
                final count = guests
                    .where((g) => g.status == GuestStatus.confirmed && g.menuSelection == menu.id)
                    .fold<int>(0, (sum, g) => sum + g.totalSeats);
                return SizedBox(
                  width: 140,
                  child: _MenuMiniCard(
                    label: menu.name,
                    count: count,
                    emoji: menu.icon ?? "🍽️",
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _MenuMiniCard(
                    label: "Wagyu Steak",
                    count: guests
                        .where((g) => g.status == GuestStatus.confirmed && g.menuSelection == 'meat')
                        .fold<int>(0, (sum, g) => sum + g.totalSeats),
                    emoji: "🥩",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MenuMiniCard(
                    label: "Salmon Gourmet",
                    count: guests
                        .where((g) => g.status == GuestStatus.confirmed && g.menuSelection == 'fish')
                        .fold<int>(0, (sum, g) => sum + g.totalSeats),
                    emoji: "🐟",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MenuMiniCard(
                    label: "Vegetariano",
                    count: guests
                        .where((g) => g.status == GuestStatus.confirmed && g.menuSelection == 'veg')
                        .fold<int>(0, (sum, g) => sum + g.totalSeats),
                    emoji: "🥗",
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MenuMiniCard(
                    label: "Kids Menu",
                    count: guests
                        .where((g) => g.status == GuestStatus.confirmed && g.menuSelection == 'kids')
                        .fold<int>(0, (sum, g) => sum + g.totalSeats),
                    emoji: "👶",
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessProgressTile extends StatelessWidget {
  final String label;
  final String value;
  final double progress;
  final IconData icon;
  final Color color;

  const _AccessProgressTile({
    required this.label,
    required this.value,
    required this.progress,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: TextStyle(color: baseColor.withValues(alpha: 0.4), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  Text(value, style: TextStyle(color: baseColor, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: baseColor.withValues(alpha: 0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuMiniCard extends StatelessWidget {
  final String label;
  final int count;
  final String emoji;

  const _MenuMiniCard({
    required this.label,
    required this.count,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withValues(alpha: 0.04)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            "$count un.",
            style: TextStyle(color: baseColor, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(color: baseColor.withValues(alpha: 0.3), fontSize: 7, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
