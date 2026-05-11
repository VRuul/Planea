import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/event_model.dart';
import '../../data/services/firestore_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';

String _localizedEventType(AppLocalizations l, EventType t) {
  switch (t) {
    case EventType.wedding: return l.typeWedding;
    case EventType.quinceanera: return l.typeQuinceanera;
    case EventType.birthday: return l.typeBirthday;
    case EventType.corporate: return l.typeCorporate;
    case EventType.graduation: return l.typeGraduation;
    case EventType.other: return l.typeOther;
  }
}

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final userId = context.read<AuthProvider>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(l.eventsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateEventSheet(context, userId),
        backgroundColor: AppColors.brushedGold,
        foregroundColor: AppColors.charcoal,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.newEvent),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: FirestoreService().watchUserEvents(userId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.brushedGold));
          }
          final events = snap.data ?? [];
          if (events.isEmpty) return _EmptyEvents(userId: userId);
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: events.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) => _EventCard(event: events[i]),
          );
        },
      ),
    );
  }

  void _showCreateEventSheet(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _CreateEventSheet(userId: userId),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return GestureDetector(
      onTap: () => context.go('/events/${event.id}'),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [event.primaryColor, event.secondaryColor],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(
            color: event.secondaryColor.withValues(alpha: 0.3),
            blurRadius: 20, offset: const Offset(0, 8),
          )],
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(event.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${event.date.day}/${event.date.month}/${event.date.year}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _localizedEventType(l, event.type).toUpperCase(),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  final String userId;
  const _EmptyEvents({required this.userId});

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
            child: const Icon(Icons.celebration_outlined,
                size: 48, color: AppColors.charcoal),
          ),
          const SizedBox(height: 20),
          Text(l.startPlanning,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(l.startPlanningSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CreateEventSheet extends StatefulWidget {
  final String userId;
  const _CreateEventSheet({required this.userId});

  @override
  State<_CreateEventSheet> createState() => _CreateEventSheetState();
}

class _CreateEventSheetState extends State<_CreateEventSheet> {
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  EventType _type = EventType.wedding;
  DateTime _date = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l) async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final event = EventModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        type: _type,
        date: _date,
        primaryColor: AppColors.charcoal,
        secondaryColor: AppColors.brushedGold,
        venue: _venueController.text.trim().isEmpty
            ? null
            : _venueController.text.trim(),
        organizerId: widget.userId,
      );
      await FirestoreService().createEvent(event);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(l.newEvent,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: l.eventNameLabel,
              prefixIcon: const Icon(Icons.celebration_outlined),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<EventType>(
            initialValue: _type,
            decoration: InputDecoration(
              labelText: l.eventTypeLabel,
              prefixIcon: const Icon(Icons.category_outlined),
            ),
            items: EventType.values
                .map((t) => DropdownMenuItem(
                    value: t, child: Text(_localizedEventType(l, t))))
                .toList(),
            onChanged: (v) => setState(() => _type = v!),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: TextField(
                decoration: InputDecoration(
                  labelText: l.eventDateLabel(
                      '${_date.day}/${_date.month}/${_date.year}'),
                  prefixIcon: const Icon(Icons.calendar_today_outlined),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _venueController,
            decoration: InputDecoration(
              labelText: l.venueOptional,
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _save(l),
              child: _saving
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : Text(l.createEvent),
            ),
          ),
        ],
      ),
    );
  }
}
