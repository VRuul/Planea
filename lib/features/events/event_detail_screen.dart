import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import '../../data/models/event_model.dart';
import '../../data/services/firestore_service.dart';
import '../../providers/theme_provider.dart';
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

class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EventModel?>(
      stream: FirestoreService().watchEvent(eventId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(
                child:
                    CircularProgressIndicator(color: AppColors.brushedGold)));
        }
        return _EventDetailView(event: snap.data!);
      },
    );
  }
}

class _EventDetailView extends StatelessWidget {
  final EventModel event;
  const _EventDetailView({required this.event});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(event.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [event.primaryColor, event.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.celebration_rounded,
                      size: 64, color: Colors.white30),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(children: [
              _SectionTitle(l.colorPaletteSection),
              const SizedBox(height: 16),
              _ColorPaletteEditor(event: event),
              const SizedBox(height: 24),
              _SectionTitle(l.budgetSection),
              const SizedBox(height: 16),
              _BudgetCard(event: event),
              const SizedBox(height: 24),
              _SectionTitle(l.eventDetailsSection),
              const SizedBox(height: 16),
              _DetailRow(icon: Icons.category_outlined,
                  label: l.typeLabelDetail,
                  value: _localizedEventType(l, event.type)),
              _DetailRow(icon: Icons.calendar_today_outlined,
                  label: l.dateLabelDetail,
                  value: '${event.date.day}/${event.date.month}/${event.date.year}'),
              if (event.venue != null)
                _DetailRow(icon: Icons.location_on_outlined,
                    label: l.venueLabelDetail, value: event.venue!),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ColorPaletteEditor extends StatelessWidget {
  final EventModel event;
  const _ColorPaletteEditor({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final themeProvider = context.read<ThemeProvider>();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(
          color: event.secondaryColor.withValues(alpha: 0.1),
          blurRadius: 16, offset: const Offset(0, 4),
        )],
      ),
      child: Column(children: [
        _ColorRow(
          label: l.primaryColorLabel,
          color: event.primaryColor,
          onPick: (c) async {
            final picked = await _showColorPicker(context, c, l.primaryColorLabel, l);
            if (picked != null) {
              await FirestoreService().updateEvent(event.copyWith(primaryColor: picked));
              themeProvider.applyEventColors(picked, event.secondaryColor);
            }
          },
        ),
        const SizedBox(height: 16),
        _ColorRow(
          label: l.accentColorLabel,
          color: event.secondaryColor,
          onPick: (c) async {
            final picked = await _showColorPicker(context, c, l.accentColorLabel, l);
            if (picked != null) {
              await FirestoreService().updateEvent(event.copyWith(secondaryColor: picked));
              themeProvider.applyEventColors(event.primaryColor, picked);
            }
          },
        ),
        const SizedBox(height: 16),
        Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [event.primaryColor, event.secondaryColor]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(l.previewLabel,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
          ),
        ),
      ]),
    );
  }

  Future<Color?> _showColorPicker(
      BuildContext context, Color initial, String label, AppLocalizations l) async {
    Color selected = initial;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l.chooseColorFor(label)),
        content: SingleChildScrollView(
          child: ColorPicker(
            color: initial,
            onColorChanged: (c) => selected = c,
            heading: Text(l.selectColorHeading,
                style: Theme.of(context).textTheme.titleSmall),
            subheading: Text(l.adjustToneSubheading,
                style: Theme.of(context).textTheme.bodySmall),
            pickersEnabled: const {
              ColorPickerType.both: true,
              ColorPickerType.primary: false,
              ColorPickerType.accent: false,
              ColorPickerType.bw: false,
              ColorPickerType.custom: true,
              ColorPickerType.wheel: true,
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancelButton)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.applyButton)),
        ],
      ),
    );
    return result == true ? selected : null;
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final Color color;
  final ValueChanged<Color> onPick;
  const _ColorRow({required this.label, required this.color, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
        GestureDetector(
          onTap: () => onPick(color),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: color, shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3), width: 2),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.edit_outlined, size: 14, color: Colors.grey),
          ]),
        ),
      ],
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final EventModel event;
  const _BudgetCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final progress = event.budgetProgress;
    final remaining = event.budget - event.budgetSpent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: theme.cardTheme.color, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.totalBudgetLabel,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              Text('\$${event.budget.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(l.remainingLabel,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              Text('\$${remaining.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: remaining >= 0 ? AppColors.confirmed : AppColors.declined,
                  )),
            ]),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress, minHeight: 10,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.9 ? AppColors.declined : AppColors.brushedGold),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.budgetSpentLabel('\$${event.budgetSpent.toStringAsFixed(0)}'),
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            Text('${(progress * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.brushedGold, fontWeight: FontWeight.w600)),
          ],
        ),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
