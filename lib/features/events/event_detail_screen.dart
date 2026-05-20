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
import '../shared/widgets/premium_picker.dart';


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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => RsvpConfigDialog(event: widget.event),
                );
              },
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: const Text("Personalizar Portal y Diseño"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brushedGold.withValues(alpha: 0.08),
                foregroundColor: AppColors.brushedGold,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.brushedGold, width: 1.2),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
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

class RsvpConfigDialog extends StatefulWidget {
  final EventModel event;
  const RsvpConfigDialog({super.key, required this.event});

  @override
  State<RsvpConfigDialog> createState() => _RsvpConfigDialogState();
}

class _RsvpConfigDialogState extends State<RsvpConfigDialog> {
  final _coverPhotoController = TextEditingController();
  final _dressCodeController = TextEditingController();
  final _customNotesController = TextEditingController();
  final _registryUrlController = TextEditingController();

  String _themeStyle = 'classic_gold';
  bool _showCountdown = true;
  bool _showMap = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final config = widget.event.rsvpConfig;
    _coverPhotoController.text = config.coverPhotoUrl ?? '';
    _dressCodeController.text = config.dressCode ?? '';
    _customNotesController.text = config.customNotes ?? '';
    _registryUrlController.text = config.registryUrl ?? '';
    _themeStyle = config.themeStyle;
    _showCountdown = config.showCountdown;
    _showMap = config.showMap;
  }

  @override
  void dispose() {
    _coverPhotoController.dispose();
    _dressCodeController.dispose();
    _customNotesController.dispose();
    _registryUrlController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updatedConfig = widget.event.rsvpConfig.copyWith(
        themeStyle: _themeStyle,
        coverPhotoUrl: _coverPhotoController.text.trim().isEmpty ? null : _coverPhotoController.text.trim(),
        dressCode: _dressCodeController.text.trim().isEmpty ? null : _dressCodeController.text.trim(),
        customNotes: _customNotesController.text.trim().isEmpty ? null : _customNotesController.text.trim(),
        registryUrl: _registryUrlController.text.trim().isEmpty ? null : _registryUrlController.text.trim(),
        showCountdown: _showCountdown,
        showMap: _showMap,
      );

      final updatedEvent = widget.event.copyWith(rsvpConfig: updatedConfig);
      await SupabaseService().updateEvent(updatedEvent);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración de RSVP guardada con éxito'),
            backgroundColor: AppColors.charcoal,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Row(
        children: [
          Icon(Icons.palette_outlined, color: AppColors.brushedGold),
          SizedBox(width: 12),
          Text(
            "Personalizar RSVP",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              
              // Theme Picker
              PremiumPicker<String>(
                label: "Tema Visual",
                icon: Icons.style_outlined,
                value: _themeStyle,
                items: const [
                  PremiumPickerItem(value: 'classic_gold', label: 'Oro Clásico (Oscuro)', icon: Icons.brightness_5),
                  PremiumPickerItem(value: 'romantic_rose', label: 'Rosa Romántico', icon: Icons.favorite),
                  PremiumPickerItem(value: 'midnight_luxury', label: 'Lujo de Medianoche', icon: Icons.nights_stay),
                  PremiumPickerItem(value: 'minimal_light', label: 'Luz Mínima (Claro)', icon: Icons.wb_sunny_outlined),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _themeStyle = val);
                },
              ),
              const SizedBox(height: 16),

              // Cover Photo URL
              TextField(
                controller: _coverPhotoController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration("URL Foto de Portada (Opcional)", Icons.image_outlined, theme),
              ),
              const SizedBox(height: 16),

              // Dress Code
              TextField(
                controller: _dressCodeController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration("Código de Vestimenta (ej: Formal)", Icons.checkroom_outlined, theme),
              ),
              const SizedBox(height: 16),

              // Registry URL
              TextField(
                controller: _registryUrlController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration("Mesa de Regalos URL (Opcional)", Icons.card_giftcard_outlined, theme),
              ),
              const SizedBox(height: 16),

              // Custom Notes
              TextField(
                controller: _customNotesController,
                maxLines: 2,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration("Anotaciones Especiales para Invitados", Icons.note_alt_outlined, theme),
              ),
              const SizedBox(height: 20),

              // Toggles
              SwitchListTile(
                title: Text("Mostrar Cuenta Regresiva", style: TextStyle(color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text("Muestra un contador hacia la fecha del evento", style: TextStyle(color: Colors.grey, fontSize: 11)),
                value: _showCountdown,
                activeColor: AppColors.brushedGold,
                onChanged: (val) => setState(() => _showCountdown = val),
              ),
              SwitchListTile(
                title: Text("Mostrar Mapa del Salón", style: TextStyle(color: baseColor, fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text("Muestra un plano interactivo de la mesa asignada", style: TextStyle(color: Colors.grey, fontSize: 11)),
                value: _showMap,
                activeColor: AppColors.brushedGold,
                onChanged: (val) => setState(() => _showMap = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancelar", style: TextStyle(color: baseColor.withValues(alpha: 0.5))),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brushedGold,
            foregroundColor: AppColors.charcoal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.charcoal))
              : const Text("Guardar", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark, baseColor = isDark ? Colors.white : Colors.black;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.brushedGold, size: 20),
      filled: true,
      fillColor: baseColor.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.brushedGold, width: 1.5)),
    );
  }
}

