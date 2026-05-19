import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/event_model.dart';
import '../../data/services/supabase_service.dart';
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
      stream: SupabaseService().watchEvent(eventId),
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
        await SupabaseService().deleteEvent(event.id);
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
                  final userId = context.read<AuthProvider>().currentUser?.id ?? '';
                  showDialog(
                    context: context,
                    builder: (_) => EventDialog(userId: userId, event: event),
                  );
                },
              ),
              if (context.read<AuthProvider>().currentUser?.id == event.organizerId)
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
              _SectionTitle("Portal de Invitados (RSVP)"),
              const SizedBox(height: 16),
              _RsvpPortalCard(event: event),
              const SizedBox(height: 32),
              _SectionTitle("Banquete y Menús"),
              const SizedBox(height: 16),
              _CateringMenuCard(event: event),
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

class _RsvpPortalCard extends StatefulWidget {
  final EventModel event;
  const _RsvpPortalCard({required this.event});

  @override
  State<_RsvpPortalCard> createState() => _RsvpPortalCardState();
}

class _RsvpPortalCardState extends State<_RsvpPortalCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final inviteCode = widget.event.inviteCode;

    if (inviteCode == null || inviteCode.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: baseColor.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            const Icon(Icons.qr_code_scanner_rounded, color: AppColors.brushedGold, size: 48),
            const SizedBox(height: 16),
            const Text(
              "Sin Código de Invitación",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.brushedGold),
            ),
            const SizedBox(height: 8),
            Text(
              "Genera un código único para que tus invitados puedan ingresar al portal de RSVP.",
              textAlign: TextAlign.center,
              style: TextStyle(color: baseColor.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                try {
                  await SupabaseService().generateInviteCode(widget.event.id);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al generar código: $e')),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              icon: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.auto_awesome_rounded),
              label: const Text("Generar Código RSVP"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brushedGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      );
    }

    final origin = Uri.base.origin.startsWith('http') ? Uri.base.origin : 'https://planea.mx';
    final rsvpLink = '$origin/rsvp/$inviteCode';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "CÓDIGO DE INVITACIÓN",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: baseColor.withValues(alpha: 0.4),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    inviteCode,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.brushedGold,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brushedGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.qr_code_2_rounded, color: AppColors.brushedGold, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            "Enlace del Portal de Invitados:",
            style: theme.textTheme.labelMedium?.copyWith(
              color: baseColor.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: baseColor.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rsvpLink,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: baseColor.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppColors.brushedGold, size: 20),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: rsvpLink));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Enlace RSVP copiado al portapapeles'),
                          backgroundColor: AppColors.charcoal,
                        ),
                      );
                    }
                  },
                  tooltip: 'Copiar enlace',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.push('/rsvp/$inviteCode');
                  },
                  icon: const Icon(Icons.visibility_outlined, size: 18),
                  label: const Text("Probar Portal"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: baseColor.withValues(alpha: 0.05),
                    foregroundColor: baseColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: baseColor.withValues(alpha: 0.1)),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final text = '¡Hola! Te invito a confirmar tu asistencia para el evento "${widget.event.name}". Ingresa aquí para confirmar tu asistencia y elegir tu menú: $rsvpLink';
                    final url = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
                    try {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No se pudo abrir WhatsApp: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text("Compartir"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brushedGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CateringMenuCard extends StatelessWidget {
  final EventModel event;

  const _CateringMenuCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.brushedGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu_rounded, color: AppColors.brushedGold, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Menús de Catering",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.menus.isEmpty
                          ? "Sin menús personalizados (se usarán los predeterminados)"
                          : "${event.menus.length} menú(s) personalizado(s) configurado(s)",
                      style: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push('/events/${event.id}/menu'),
            icon: const Icon(Icons.settings_outlined, color: Colors.black),
            label: const Text("CONFIGURAR MENÚS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brushedGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
