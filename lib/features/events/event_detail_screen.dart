import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/event_model.dart';
import '../../data/services/firestore_service.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';
import './events_screen.dart';
import './widgets/event_utils.dart';
import './collaborators_panel.dart';


class EventDetailScreen extends StatelessWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EventModel?>(
      stream: FirestoreService().watchEvent(eventId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(
            body: Center(
                child:
                    CircularProgressIndicator(color: AppColors.brushedGold)));
        }

        if (snap.data == null) {
          // Si el evento fue borrado (ya sea por nosotros o por otro), 
          // nos aseguramos de limpiar cualquier diálogo y regresar a la lista.
          Future.microtask(() {
            if (context.mounted) {
              // Intentamos cerrar cualquier diálogo abierto (como el de carga)
              // antes de navegar a la lista principal.
              Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst || route is! DialogRoute);
              context.go('/events');
            }
          });
          return const Scaffold();
        }

        return _EventDetailView(event: snap.data!);
      },
    );
  }
}

class _EventDetailView extends StatelessWidget {
  final EventModel event;
  const _EventDetailView({required this.event});

  Future<void> _confirmDelete(BuildContext context) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('¿Eliminar evento?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text(
          'Esta acción borrará toda la información del evento, incluyendo invitados y colaboradores. No se puede deshacer.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.cancelButton, style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar permanentemente'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Show a loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.brushedGold)),
      );

      try {
        await FirestoreService().deleteEvent(event.id);
        // No cerramos el diálogo aquí manualmente; el StreamBuilder en la parte superior
        // detectará que el documento desapareció, cerrará todos los diálogos y navegará a /events.
      } catch (e) {
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Cerrar diálogo de carga en caso de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.charcoal,
            leading: const BackButton(color: AppColors.brushedGold),
            actions: [
              IconButton(
                icon: const Icon(Icons.group_rounded, color: AppColors.brushedGold),
                tooltip: 'Equipo',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CollaboratorsPanel(event: event)),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.brushedGold),
                onPressed: () {
                  final userId = context.read<AuthProvider>().currentUser?.uid ?? '';
                  showDialog(
                    context: context,
                    builder: (_) => EventDialog(userId: userId, event: event),
                  );
                },
              ),
              if (context.read<AuthProvider>().currentUser?.uid == event.organizerId)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  tooltip: 'Eliminar Evento',
                  onPressed: () => _confirmDelete(context),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(event.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
              background: Container(
                decoration: BoxDecoration(
                  color: AppColors.charcoal,
                  border: Border(bottom: BorderSide(color: AppColors.brushedGold.withValues(alpha: 0.15))),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.brushedGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.2)),
                        ),
                        child: Icon(
                          event.customTypeIcon != null 
                            ? IconData(event.customTypeIcon!, fontFamily: 'MaterialIcons') 
                            : getEventTypeInfo(context, event.type).icon,
                          size: 48, color: AppColors.brushedGold),
                      ),
                      if (event.celebrantNames != null) ...[
                        const SizedBox(height: 12),
                        Text(event.celebrantNames!, 
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList.list(children: [
              _SectionTitle(l.budgetSection),
              const SizedBox(height: 16),
              _BudgetCard(event: event),
              const SizedBox(height: 32),
              _SectionTitle(l.eventDetailsSection),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    _DetailRow(icon: Icons.category_outlined,
                        label: l.typeLabelDetail,
                        value: event.customType ?? getEventTypeInfo(context, event.type).label),
                    _DetailRow(icon: Icons.calendar_today_outlined,
                        label: l.dateLabelDetail,
                        value: '${event.date.day}/${event.date.month}/${event.date.year}'),
                    if (event.celebrantNames != null)
                      _DetailRow(icon: Icons.people_outline_rounded,
                          label: "Protagonistas", value: event.celebrantNames!),
                    if (event.guestGoal > 0)
                      _DetailRow(icon: Icons.group_outlined,
                          label: "Meta de invitados", value: "${event.guestGoal}"),
                    if (event.venue != null)
                      _DetailRow(icon: Icons.location_on_outlined,
                          label: l.venueLabelDetail, value: event.venue!, isLast: true),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ],
      ),
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final progress = event.budgetProgress;
    final remaining = event.budget - event.budgetSpent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.03), 
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: baseColor.withValues(alpha: 0.05))),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.totalBudgetLabel,
                  style: theme.textTheme.labelSmall?.copyWith(color: baseColor.withValues(alpha: 0.4), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('\$${event.budget.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900, color: baseColor)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(l.remainingLabel,
                  style: theme.textTheme.labelSmall?.copyWith(color: baseColor.withValues(alpha: 0.4), fontWeight: FontWeight.w600, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text('\$${remaining.toStringAsFixed(0)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: remaining >= 0 ? AppColors.brushedGold : Colors.redAccent,
                  )),
            ]),
          ],
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress, minHeight: 12,
            backgroundColor: baseColor.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.9 ? Colors.redAccent : AppColors.brushedGold),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.budgetSpentLabel('\$${event.budgetSpent.toStringAsFixed(0)}'),
              style: theme.textTheme.labelSmall?.copyWith(color: baseColor.withValues(alpha: 0.4), fontWeight: FontWeight.w500),
            ),
            Text('${(progress * 100).round()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.brushedGold, fontWeight: FontWeight.w900)),
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
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  const _DetailRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: baseColor.withValues(alpha: 0.05))),
      ),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.brushedGold),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: baseColor.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: baseColor)),
            ],
          ),
        ),
      ]),
    );
  }
}
