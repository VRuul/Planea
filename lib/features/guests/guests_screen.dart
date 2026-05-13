import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../data/models/guest_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/table_model.dart';
import '../../data/models/seating_assignment_model.dart';
import '../../data/models/seating_data_model.dart';
import '../../data/services/firestore_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';
import 'package:url_launcher/url_launcher.dart';
import '../shared/widgets/guest_role_chip.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({super.key});

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  final _service = FirestoreService();
  GuestStatus? _filterStatus;
  GuestRole? _filterRole;
  String? _filterCustomRole;
  String? _filterGuestType;
  String? _filterSeatingStatus; // 'Completos', 'Parciales', 'Sin Asignar'
  String _search = '';
  List<GuestModel> _allGuestsCached = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final auth = context.read<AuthProvider>();
    final eventProvider = context.watch<EventProvider>();
    final userId = auth.currentUser?.uid ?? '';

    return StreamBuilder<List<EventModel>>(
      stream: _service.watchUserEvents(userId),
      builder: (context, eventSnap) {
        final events = eventSnap.data ?? [];

        // Validamos el currentEventId contra la lista real de Firestore
        final currentEventId =
            events.any((e) => e.id == eventProvider.currentEventId)
            ? eventProvider.currentEventId
            : (events.isNotEmpty ? events.first.id : null);

        if (currentEventId == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l.guestsTitle)),
            body: _EmptyGuestsNoEvent(),
          );
        }

        final currentEvent = events.firstWhere((e) => e.id == currentEventId);

        return Scaffold(
          appBar: AppBar(
            title: Text(l.guestsTitle),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.message_rounded,
                  color: AppColors.brushedGold,
                ),
                tooltip: 'Configurar Mensaje',
                onPressed: () =>
                    _showTemplateDialog(context, currentEventId, currentEvent),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: () => _showFilterSheet(context, l),
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: l.searchGuest,
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.brushedGold),
                    filled: true,
                    fillColor: theme.brightness == Brightness.dark 
                        ? Colors.white.withValues(alpha: 0.03) 
                        : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: theme.brightness == Brightness.dark 
                            ? Colors.white.withValues(alpha: 0.05) 
                            : Colors.black.withValues(alpha: 0.05)
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(
                        color: theme.brightness == Brightness.dark 
                            ? Colors.white.withValues(alpha: 0.05) 
                            : Colors.black.withValues(alpha: 0.05)
                      ),
                    ),
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(height: 8),
              if (_filterStatus != null || _filterRole != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (_filterStatus != null)
                        _FilterChip(
                          label: _statusLabel(l, _filterStatus!),
                          onRemove: () => setState(() => _filterStatus = null),
                        ),
                      if (_filterRole != null)
                        _FilterChip(
                          label: _roleLabel(l, _filterRole!),
                          onRemove: () => setState(() => _filterRole = null),
                        ),
                      if (_filterCustomRole != null)
                        _FilterChip(
                          label: _filterCustomRole!,
                          onRemove: () =>
                              setState(() => _filterCustomRole = null),
                        ),
                      if (_filterGuestType != null)
                        _FilterChip(
                          label: _filterGuestType!,
                          onRemove: () =>
                              setState(() => _filterGuestType = null),
                        ),
                      if (_filterSeatingStatus != null)
                        _FilterChip(
                          label: _filterSeatingStatus!,
                          onRemove: () =>
                              setState(() => _filterSeatingStatus = null),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: StreamBuilder<SeatingData>(
                  stream: _service.watchSeatingData(currentEventId),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data;
                    final tables = data?.tables ?? [];
                    final assignments = data?.assignments ?? [];
                    _allGuestsCached = data?.guests ?? [];

                    return Scaffold(
                      backgroundColor: Colors.transparent,
                      floatingActionButton: FloatingActionButton.extended(
                        onPressed: () => _showGuestDialog(
                          context,
                          currentEventId,
                          null,
                          _allGuestsCached,
                        ),
                        backgroundColor: AppColors.brushedGold,
                        foregroundColor: AppColors.charcoal,
                        icon: const Icon(Icons.person_add_rounded),
                        label: Text(l.addGuest),
                      ),
                      body: _buildGuestList(
                        context,
                        _allGuestsCached,
                        currentEventId,
                        l,
                        theme,
                        tables,
                        assignments,
                        currentEvent,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        allGuests: _allGuestsCached,
        currentStatus: _filterStatus,
        currentRole: _filterRole,
        currentCustomRole: _filterCustomRole,
        currentGuestType: _filterGuestType,
        currentSeatingStatus: _filterSeatingStatus,
        onApply: (status, role, customRole, type, seating) => setState(() {
          _filterStatus = status;
          _filterRole = role;
          _filterCustomRole = customRole;
          _filterGuestType = type;
          _filterSeatingStatus = seating;
        }),
      ),
    );
  }

  Widget _buildGuestList(
    BuildContext context,
    List<GuestModel> allGuests,
    String eventId,
    AppLocalizations l,
    ThemeData theme,
    List<TableModel> tables,
    List<SeatingAssignment> assignments,
    EventModel event,
  ) {
    final filtered = allGuests.where((g) {
      final matchSearch =
          _search.isEmpty ||
          g.displayName.toLowerCase().contains(_search.toLowerCase());
      final matchStatus = _filterStatus == null || g.status == _filterStatus;

      bool matchRole = true;
      if (_filterRole != null) {
        matchRole = g.role == _filterRole && g.customRole == null;
      } else if (_filterCustomRole != null) {
        matchRole = g.customRole == _filterCustomRole;
      }

      bool matchType = true;
      if (_filterGuestType != null) {
        if (_filterGuestType == l.countAdults) {
          matchType = g.adults > 0;
        } else if (_filterGuestType == l.countChildren) {
          matchType = g.children > 0;
        } else if (_filterGuestType == l.countDisabled) {
          matchType = g.disabled > 0;
        } else {
          // Custom type
          matchType = (g.customCounts[_filterGuestType!] ?? 0) > 0;
        }
      }

      bool matchSeating = true;
      if (_filterSeatingStatus != null) {
        final guestAssig = assignments.where((a) => a.guestId == g.id);
        final totalAssigned = guestAssig.fold<int>(
          0,
          (sum, a) => sum + a.total,
        );

        if (_filterSeatingStatus == 'Completos') {
          matchSeating = totalAssigned >= g.totalSeats;
        } else if (_filterSeatingStatus == 'Parciales') {
          matchSeating = totalAssigned > 0 && totalAssigned < g.totalSeats;
        } else if (_filterSeatingStatus == 'Sin Asignar') {
          matchSeating = totalAssigned == 0;
        }
      }

      return matchSearch &&
          matchStatus &&
          matchRole &&
          matchType &&
          matchSeating;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.people_outline_rounded,
              size: 64,
              color: AppColors.brushedGold,
            ),
            const SizedBox(height: 12),
            Text(l.noGuests, style: theme.textTheme.titleMedium),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _GuestCard(
        guest: filtered[i],
        eventId: eventId,
        allGuests: allGuests,
        tables: tables,
        assignments: assignments,
        whatsappTemplate: event.whatsappTemplate ?? 'Hola {nombre}, te contacto para saludarte.',
        emailTemplate: event.emailTemplate ?? 'Hola {nombre}, te escribo para confirmar tus detalles.',
        emailSubject: event.emailSubject ?? 'Información de tu invitación',
      ),
    );
  }

  void _showTemplateDialog(
    BuildContext context,
    String eventId,
    EventModel event,
  ) {
    showDialog(
      context: context,
      builder: (context) => _MessageTemplateDialog(
        eventId: eventId,
        event: event,
        service: _service,
      ),
    );
  }

  Future<void> _showGuestDialog(
    BuildContext context,
    String eventId, [
    GuestModel? guest,
    List<GuestModel>? allGuests,
  ]) async {
    await showDialog(
      context: context,
      builder: (_) =>
          _GuestDialog(eventId: eventId, guest: guest, allGuests: allGuests),
    );
  }
}

class _MessageTemplateDialog extends StatefulWidget {
  final String eventId;
  final EventModel event;
  final FirestoreService service;

  const _MessageTemplateDialog({
    required this.eventId,
    required this.event,
    required this.service,
  });

  @override
  State<_MessageTemplateDialog> createState() => _MessageTemplateDialogState();
}

class _MessageTemplateDialogState extends State<_MessageTemplateDialog> {
  int activeTab = 0; // 0 for WhatsApp, 1 for Email
  late TextEditingController waController;
  late TextEditingController emailController;
  late TextEditingController subjectController;

  @override
  void initState() {
    super.initState();
    waController = TextEditingController(text: widget.event.whatsappTemplate ?? 'Hola {nombre}, te contacto para saludarte.');
    emailController = TextEditingController(text: widget.event.emailTemplate ?? 'Hola {nombre}, te escribo para confirmar tus detalles.');
    subjectController = TextEditingController(text: widget.event.emailSubject ?? 'Información de tu invitación');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.all(0),
      title: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_motion_rounded, color: AppColors.brushedGold, size: 24),
                const SizedBox(width: 12),
                Text(
                  "Configurar Mensajes",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Custom Segmented Control
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: baseColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _TabButton(
                    label: "WhatsApp",
                    icon: Icons.chat_bubble_outline_rounded,
                    selected: activeTab == 0,
                    onTap: () => setState(() => activeTab = 0),
                  ),
                  _TabButton(
                    label: "Correo",
                    icon: Icons.alternate_email_rounded,
                    selected: activeTab == 1,
                    onTap: () => setState(() => activeTab = 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TagChip(label: "{nombre}"),
                _TagChip(label: "{mesa}"),
                _TagChip(label: "{total}"),
              ],
            ),
            const SizedBox(height: 24),
            if (activeTab == 0) ...[
              TextField(
                controller: waController,
                maxLines: 6,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration("Mensaje de WhatsApp", Icons.chat_bubble_outline_rounded, theme),
              ),
            ] else ...[
              TextField(
                controller: subjectController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration("Asunto del correo", Icons.subject_rounded, theme),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                maxLines: 6,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration("Cuerpo del correo", Icons.email_outlined, theme),
              ),
            ],
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white54 : Colors.black45),
          child: const Text("Cancelar"),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () async {
            if (activeTab == 0) {
              await widget.service.updateEventTemplate(widget.eventId, waController.text.trim());
            } else {
              await widget.service.updateEventEmailConfig(widget.eventId, emailController.text.trim(), subjectController.text.trim());
            }
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brushedGold,
            foregroundColor: AppColors.charcoal,
            elevation: 8,
            shadowColor: AppColors.brushedGold.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            "GUARDAR",
            style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 13),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.brushedGold, size: 20),
      filled: true,
      fillColor: baseColor.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.brushedGold, width: 1.5)),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brushedGold : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.charcoal : (isDark ? Colors.white54 : Colors.black45)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.charcoal : (isDark ? Colors.white54 : Colors.black45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  const _TagChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.brushedGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.brushedGold,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _showGuestDialog(
    BuildContext context,
    String eventId, [
    GuestModel? guest,
    List<GuestModel>? allGuests,
  ]) async {
    await showDialog(
      context: context,
      builder: (_) =>
          _GuestDialog(eventId: eventId, guest: guest, allGuests: allGuests),
    );
  }
}

class _EmptyGuestsNoEvent extends StatelessWidget {
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
              gradient: AppColors.goldGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: AppColors.charcoal,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l.noEventsYet,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.noEventsYetSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
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

// ── Helpers ─────────────────────────────────────────────────────────────────

String _statusLabel(AppLocalizations l, GuestStatus s) {
  switch (s) {
    case GuestStatus.confirmed:
      return l.guestConfirmed;
    case GuestStatus.pending:
      return l.guestPending;
    case GuestStatus.declined:
      return l.guestDeclined;
  }
}

String _roleLabel(AppLocalizations l, GuestRole r) {
  switch (r) {
    case GuestRole.padrino:
      return l.rolePadrino;
    case GuestRole.vip:
      return l.roleVip;
    case GuestRole.regular:
      return l.roleRegular;
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _GuestCard extends StatelessWidget {
  final GuestModel guest;
  final String eventId;
  final List<GuestModel>? allGuests;
  final List<TableModel>? tables;
  final List<SeatingAssignment>? assignments;
  final String whatsappTemplate;
  final String emailTemplate;
  final String emailSubject;

  _GuestCard({
    required this.guest,
    required this.eventId,
    this.allGuests,
    this.tables,
    this.assignments,
    required this.whatsappTemplate,
    required this.emailTemplate,
    required this.emailSubject,
  });
  final _service = FirestoreService();

  String _buildMessage(String template) {
    final assignment = assignments?.where((a) => a.guestId == guest.id).firstOrNull;
    final tableName = assignment != null
        ? tables?.firstWhere((t) => t.id == assignment.tableId).name ?? '?'
        : 'Pendiente';

    String message = template;
    message = message.replaceAll('{nombre}', guest.displayName);
    message = message.replaceAll('{total}', guest.totalSeats.toString());
    message = message.replaceAll('{mesa}', tableName);
    return message;
  }

  Future<void> _launchWhatsApp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) return;
    final message = _buildMessage(whatsappTemplate);
    final url = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('No se pudo lanzar WhatsApp: $e');
    }
  }

  Future<void> _launchEmail(String email) async {
    final subject = _buildMessage(emailSubject);
    final body = _buildMessage(emailTemplate);
    final url = Uri.parse("mailto:$email?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}");
    try {
      await launchUrl(url);
    } catch (e) {
      debugPrint('No se pudo lanzar Email: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = guest.status == GuestStatus.confirmed
        ? AppColors.confirmed
        : guest.status == GuestStatus.pending
        ? AppColors.pending
        : AppColors.declined;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark 
            ? theme.cardTheme.color?.withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: AppColors.brushedGold,
          collapsedIconColor: Colors.white30,
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
                ),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: statusColor.withValues(alpha: isDark ? 0.1 : 0.2),
                  child: Text(
                    guest.displayName.isNotEmpty ? guest.displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isDark ? statusColor : statusColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              if (guest.phone != null && guest.phone!.isNotEmpty)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _launchWhatsApp(guest.phone!),
                      child: Icon(
                        Icons.chat_bubble_rounded, 
                        color: isDark ? Colors.greenAccent : Colors.green.shade600, 
                        size: 14
                      ),
                    ),
                  ),
                ),
              if (guest.email != null && guest.email!.isNotEmpty)
                Positioned(
                  left: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.charcoal : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                      ],
                    ),
                    child: InkWell(
                      onTap: () => _launchEmail(guest.email!),
                      child: Icon(
                        Icons.email_rounded, 
                        color: isDark ? Colors.blueAccent : Colors.blue.shade600, 
                        size: 14
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  guest.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              _StatusPill(status: guest.status, color: statusColor, l: l),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (guest.customRole != null)
                  _CustomRoleChip(
                    label: guest.customRole!,
                    iconCode: guest.customRoleIcon,
                  )
                else
                  GuestRoleChip(role: guest.role),
                
                ...() {
                  final guestAssig = assignments?.where((a) => a.guestId == guest.id).toList() ?? [];
                  return guestAssig.map((a) {
                    final t = tables?.firstWhere(
                      (t) => t.id == a.tableId,
                      orElse: () => TableModel(id: '', eventId: '', name: '?', capacity: 0),
                    );
                    return _PremiumTag(
                      label: "${t?.name ?? 'Mesa'} (${a.total})",
                      icon: Icons.table_restaurant_rounded,
                      color: Colors.blueAccent.withValues(alpha: 0.8),
                    );
                  }).toList();
                }(),
                _PremiumTag(
                  label: 'Total: ${guest.totalSeats}',
                  icon: Icons.people_alt_rounded,
                  color: Colors.purpleAccent.withValues(alpha: 0.8),
                ),
              ],
            ),
          ),
          children: [
            Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (guest.adults > 0)
                      _PremiumCounter(
                        label: l.countAdults,
                        count: guest.adults,
                        icon: Icons.person_rounded,
                      ),
                    if (guest.children > 0)
                      _PremiumCounter(
                        label: l.countChildren,
                        count: guest.children,
                        icon: Icons.child_care_rounded,
                      ),
                    ...guest.customCounts.entries.where((e) => e.value > 0).map(
                      (e) {
                        final iconCode = guest.customIcons[e.key];
                        final icon = iconCode != null
                            ? IconData(iconCode, fontFamily: 'MaterialIcons')
                            : Icons.star_rounded;
                        return _PremiumCounter(
                          label: e.key,
                          count: e.value,
                          icon: icon,
                        );
                      },
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Divider(color: isDark ? Colors.white10 : Colors.black12),
                ),
                if (guest.phone != null ||
                    guest.email != null ||
                    guest.socialMedia != null) ...[
                  Row(
                    children: [
                      Text(l.contactInfoSection.toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark ? AppColors.brushedGold : AppColors.charcoal.withValues(alpha: 0.6),
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w800,
                          )),
                      const Spacer(),
                      if (guest.email != null)
                        IconButton(
                          onPressed: () => _launchEmail(guest.email!),
                          icon: const Icon(Icons.alternate_email_rounded, color: Colors.blueAccent, size: 20),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (guest.phone != null)
                    _ContactItem(
                      icon: Icons.phone_android_rounded,
                      value: guest.phone!,
                    ),
                  if (guest.email != null)
                    _ContactItem(
                      icon: Icons.email_rounded,
                      value: guest.email!,
                    ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    _ActionButton(
                      label: l.deleteButton,
                      icon: Icons.delete_outline_rounded,
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      onTap: () => _showDeleteDialog(context, l),
                    ),
                    const SizedBox(width: 12),
                    _ActionButton(
                      label: l.editButton,
                      icon: Icons.edit_rounded,
                      color: AppColors.brushedGold,
                      onTap: () {
                        final state = context.findAncestorStateOfType<_GuestsScreenState>();
                        state?._showGuestDialog(context, eventId, guest, allGuests);
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showTablePicker(context, l),
                        icon: const Icon(Icons.table_restaurant_rounded, size: 18),
                        label: const Text("ASIGNAR MESA"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brushedGold,
                          foregroundColor: AppColors.charcoal,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  void _showStatusDialog(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          l.filterStatus,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GuestStatus.values.map((s) {
            final color = s == GuestStatus.confirmed
                ? AppColors.confirmed
                : s == GuestStatus.pending
                ? AppColors.pending
                : AppColors.declined;
            final icon = s == GuestStatus.confirmed
                ? Icons.check_circle_outline_rounded
                : s == GuestStatus.pending
                ? Icons.hourglass_empty_rounded
                : Icons.cancel_outlined;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  _service.updateGuestStatus(eventId, guest.id, s);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(
                      color: color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color),
                      const SizedBox(width: 16),
                      Text(
                        _statusLabel(l, s),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      if (guest.status == s)
                        Icon(Icons.check_rounded, color: color, size: 18),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancelButton),
          ),
        ],
      ),
    );
  }

  void _showTablePicker(BuildContext context, AppLocalizations l) {
    if (tables == null || tables!.isEmpty) return;

    // Obtenemos las asignaciones de este invitado para todas las mesas
    final guestAssignments =
        assignments?.where((a) => a.guestId == guest.id).toList() ?? [];

    showDialog(
      context: context,
      builder: (context) => _TablePickerFlow(
        guest: guest,
        tables: tables!,
        assignments: assignments ?? [],
        guestAssignments: guestAssignments,
        eventId: eventId,
        service: _service,
        l: l,
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AppLocalizations l) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.deleteConfirmTitle),
        content: Text(l.deleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancelButton),
          ),
          TextButton(
            onPressed: () {
              _service.deleteGuest(eventId, guest.id);
              Navigator.pop(context);
            },
            child: Text(
              l.deleteButton,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final GuestStatus status;
  final Color color;
  final AppLocalizations l;
  const _StatusPill({required this.status, required this.color, required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 4, spreadRadius: 0),
        ],
      ),
      child: Text(
        _statusLabel(l, status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _PremiumTag extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _PremiumTag({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _PremiumCounter extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  const _PremiumCounter({required this.label, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
            shape: BoxShape.circle,
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
          ),
          child: Icon(icon, size: 20, color: AppColors.brushedGold),
        ),
        const SizedBox(height: 8),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 8, color: isDark ? Colors.white38 : Colors.black38, letterSpacing: 0.5)),
      ],
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ContactItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white30 : Colors.black38),
          const SizedBox(width: 12),
          Text(value, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(label.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _SmallTag extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: onRemove,
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final List<GuestModel> allGuests;
  final GuestStatus? currentStatus;
  final GuestRole? currentRole;
  final String? currentCustomRole;
  final String? currentGuestType;
  final String? currentSeatingStatus;
  final Function(GuestStatus?, GuestRole?, String?, String?, String?) onApply;

  const _FilterSheet({
    required this.allGuests,
    this.currentStatus,
    this.currentRole,
    this.currentCustomRole,
    this.currentGuestType,
    this.currentSeatingStatus,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  GuestStatus? _status;
  GuestRole? _role;
  String? _customRole;
  String? _guestType;
  String? _seatingStatus;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _role = widget.currentRole;
    _customRole = widget.currentCustomRole;
    _guestType = widget.currentGuestType;
    _seatingStatus = widget.currentSeatingStatus;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;

    final customRoles = widget.allGuests
        .where((g) => g.customRole != null)
        .map((g) => g.customRole!)
        .toSet()
        .toList();

    final customTypes = widget.allGuests
        .expand((g) => g.customCounts.keys)
        .toSet()
        .toList();

    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list_rounded, color: AppColors.brushedGold, size: 28),
              const SizedBox(width: 12),
              Text(
                l.filterGuests,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(l.filterStatus.toUpperCase(), 
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            )),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: GuestStatus.values
                  .map(
                    (s) => _TypeChip(
                      label: _statusLabel(l, s),
                      selected: _status == s,
                      onSelected: (v) =>
                          setState(() => _status = v ? s : null),
                    ),
                  )
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),
          Text(l.filterRole.toUpperCase(), 
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            )),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...GuestRole.values.map(
                  (r) => _TypeChip(
                    label: _roleLabel(l, r),
                    selected: _role == r && _customRole == null,
                    onSelected: (v) => setState(() {
                      _role = v ? r : null;
                      _customRole = null;
                    }),
                  ),
                ),
                ...customRoles.map(
                  (cr) => _TypeChip(
                    label: cr,
                    selected: _customRole == cr,
                    onSelected: (v) => setState(() {
                      _customRole = v ? cr : null;
                      _role = null;
                    }),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text("Categoría de Invitado".toUpperCase(), 
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            )),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TypeChip(
                  label: l.countAdults,
                  selected: _guestType == l.countAdults,
                  onSelected: (v) =>
                      setState(() => _guestType = v ? l.countAdults : null),
                ),
                _TypeChip(
                  label: l.countChildren,
                  selected: _guestType == l.countChildren,
                  onSelected: (v) =>
                      setState(() => _guestType = v ? l.countChildren : null),
                ),
                _TypeChip(
                  label: l.countDisabled,
                  selected: _guestType == l.countDisabled,
                  onSelected: (v) =>
                      setState(() => _guestType = v ? l.countDisabled : null),
                ),
                ...customTypes.map(
                  (ct) => _TypeChip(
                    label: ct,
                    selected: _guestType == ct,
                    onSelected: (v) =>
                        setState(() => _guestType = v ? ct : null),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text("Asignación de Mesa".toUpperCase(), 
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark ? Colors.white38 : Colors.black38,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            )),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _TypeChip(
                  label: 'Completos',
                  selected: _seatingStatus == 'Completos',
                  onSelected: (v) =>
                      setState(() => _seatingStatus = v ? 'Completos' : null),
                ),
                _TypeChip(
                  label: 'Parciales',
                  selected: _seatingStatus == 'Parciales',
                  onSelected: (v) =>
                      setState(() => _seatingStatus = v ? 'Parciales' : null),
                ),
                _TypeChip(
                  label: 'Sin Asignar',
                  selected: _seatingStatus == 'Sin Asignar',
                  onSelected: (v) =>
                      setState(() => _seatingStatus = v ? 'Sin Asignar' : null),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  _status,
                  _role,
                  _customRole,
                  _guestType,
                  _seatingStatus,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brushedGold,
                foregroundColor: AppColors.charcoal,
                elevation: 8,
                shadowColor: AppColors.brushedGold.withValues(alpha: 0.3),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(
                l.applyFilters.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: onSelected,
        selectedColor: AppColors.brushedGold,
        labelStyle: TextStyle(
          color: selected 
              ? AppColors.charcoal 
              : (isDark ? Colors.white70 : Colors.black87),
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected 
                ? AppColors.brushedGold 
                : (isDark ? Colors.white10 : Colors.black12),
          ),
        ),
      ),
    );
  }
}

class _GuestDialog extends StatefulWidget {
  final String eventId;
  final GuestModel? guest;
  final List<GuestModel>? allGuests;
  const _GuestDialog({required this.eventId, this.guest, this.allGuests});

  @override
  State<_GuestDialog> createState() => _GuestDialogState();
}

class _GuestDialogState extends State<_GuestDialog> {
  final _displayController = TextEditingController();
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _socialController = TextEditingController();
  final _notesController = TextEditingController();
  final _dietController = TextEditingController();
  String? _selectedTableId;

  GuestRole _role = GuestRole.regular;
  int _adults = 1, _children = 0, _teenagers = 0, _disabled = 0;
  Map<String, int> _customCounts = {};
  Map<String, int> _customIcons = {};
  String? _selectedCustomRole;
  int? _selectedCustomRoleIcon;
  bool _saving = false;
  bool _showSplitName = false;
  bool _isAdvancedExpanded = false;
  final _service = FirestoreService();

  @override
  void initState() {
    super.initState();
    if (widget.guest != null) {
      final g = widget.guest!;
      _displayController.text = g.displayName;
      _firstController.text = g.firstName ?? '';
      _lastController.text = g.lastName ?? '';
      _selectedTableId = g.tableId;
      _phoneController.text = g.phone ?? '';
      _emailController.text = g.email ?? '';
      _socialController.text = g.socialMedia ?? '';
      _notesController.text = g.notes ?? '';
      _dietController.text = g.dietaryRestrictions ?? '';
      _role = g.role;
      _adults = g.adults;
      _children = g.children;
      _teenagers = g.teenagers;
      _disabled = g.disabled;
      _customCounts = Map.from(g.customCounts);
      _customIcons = Map.from(g.customIcons);
      _selectedCustomRole = g.customRole;
      _selectedCustomRoleIcon = g.customRoleIcon;
      _showSplitName = g.firstName != null || g.lastName != null;
    } else if (widget.allGuests != null) {
      // Automatic learning: find all unique custom fields used in this event
      for (final g in widget.allGuests!) {
        for (final entry in g.customCounts.entries) {
          if (!_customCounts.containsKey(entry.key)) {
            _customCounts[entry.key] = 0;
            if (g.customIcons.containsKey(entry.key)) {
              _customIcons[entry.key] = g.customIcons[entry.key]!;
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _displayController.dispose();
    _firstController.dispose();
    _lastController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _socialController.dispose();
    _notesController.dispose();
    _dietController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l) async {
    if (_displayController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final isEdit = widget.guest != null;
      final guest = GuestModel(
        id: isEdit ? widget.guest!.id : const Uuid().v4(),
        eventId: widget.eventId,
        displayName: _displayController.text.trim(),
        firstName: _showSplitName ? _firstController.text.trim() : null,
        lastName: _showSplitName ? _lastController.text.trim() : null,
        role: _role,
        status: isEdit ? widget.guest!.status : GuestStatus.pending,
        tableId: _selectedTableId,
        adults: _adults,
        children: _children,
        teenagers: _teenagers,
        disabled: _disabled,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        socialMedia: _socialController.text.trim().isEmpty
            ? null
            : _socialController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        dietaryRestrictions: _dietController.text.trim().isEmpty
            ? null
            : _dietController.text.trim(),
        customCounts: _customCounts,
        customIcons: _customIcons,
        customRole: _selectedCustomRole,
        customRoleIcon: _selectedCustomRoleIcon,
      );

      if (isEdit) {
        await _service.updateGuest(widget.eventId, guest);
      } else {
        await _service.addGuest(widget.eventId, guest);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showAddCustomFieldDialog() {
    final controller = TextEditingController();
    int? selectedIconCode;

    final icons = [
      Icons.pets,
      Icons.assignment_ind,
      Icons.music_note,
      Icons.card_giftcard,
      Icons.camera_alt,
      Icons.star,
      Icons.location_on,
      Icons.restaurant,
      Icons.wine_bar,
      Icons.directions_car,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nuevo tipo de invitado"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Ej: Mascotas, Staff, etc.",
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Elige un icono:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 250,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: icons.map((icon) {
                    final isSelected = selectedIconCode == icon.codePoint;
                    return InkWell(
                      onTap: () => setDialogState(
                        () => selectedIconCode = icon.codePoint,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brushedGold.withValues(alpha: 0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brushedGold
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? AppColors.brushedGold
                              : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _customCounts[name] = 0;
                    if (selectedIconCode != null)
                      _customIcons[name] = selectedIconCode!;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Añadir"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      title: Row(
        children: [
          Icon(Icons.person_add_rounded, color: AppColors.brushedGold, size: 28),
          const SizedBox(width: 12),
          Text(
            widget.guest == null ? l.addGuestTitle : "Editar Invitado",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── CAMPOS BÁSICOS ──────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _displayController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _inputDecoration(l.guestDisplayName, Icons.badge_rounded, theme),
                    ),
                    const SizedBox(height: 16),
                    _CounterRow(
                      label: l.countAdults,
                      count: _adults,
                      icon: Icons.person_rounded,
                      onChanged: (v) => setState(() => _adults = v),
                    ),
                    const SizedBox(height: 12),
                    _CounterRow(
                      label: l.countChildren,
                      count: _children,
                      icon: Icons.child_care_rounded,
                      onChanged: (v) => setState(() => _children = v),
                    ),
                    const SizedBox(height: 16),
                    _buildRoleSelector(l, theme),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration(l.contactPhone, Icons.phone_rounded, theme),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 2,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: _inputDecoration(l.notesLabel, Icons.notes_rounded, theme),
              ),

              // ── SECCIÓN AVANZADA ────────────────────────────────────────
              const SizedBox(height: 12),
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text(
                    "Más información",
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.brushedGold,
                    ),
                  ),
                  trailing: Icon(
                    _isAdvancedExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.brushedGold,
                  ),
                  onExpansionChanged: (v) =>
                      setState(() => _isAdvancedExpanded = v),
                  childrenPadding: const EdgeInsets.only(top: 8),
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _showSplitName,
                          onChanged: (v) => setState(() => _showSplitName = v!),
                        ),
                        Text(
                          "Separar nombre y apellido",
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    if (_showSplitName) ...[
                      TextField(
                        controller: _firstController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _inputDecoration(l.guestFirstName, Icons.person_outline_rounded, theme),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _lastController,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _inputDecoration(l.guestLastName, Icons.person_outline_rounded, theme),
                      ),
                    ],
                    const Divider(height: 32),
                    _CounterRow(
                      label: l.countDisabled,
                      count: _disabled,
                      onChanged: (v) => setState(() => _disabled = v),
                    ),
                    const SizedBox(height: 12),
                    ..._customCounts.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _CounterRow(
                          label: e.key,
                          count: e.value,
                          icon: _customIcons[e.key] != null
                              ? IconData(
                                  _customIcons[e.key]!,
                                  fontFamily: 'MaterialIcons',
                                )
                              : null,
                          onChanged: (v) =>
                              setState(() => _customCounts[e.key] = v),
                          onRemove: () => setState(() {
                            _customCounts.remove(e.key);
                            _customIcons.remove(e.key);
                          }),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _showAddCustomFieldDialog,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text("Añadir invitados personalizados"),
                    ),
                    const Divider(height: 32),
                    TextField(
                      controller: _emailController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _inputDecoration(l.contactEmail, Icons.email_rounded, theme),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _socialController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _inputDecoration(l.contactSocial, Icons.link_rounded, theme),
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<TableModel>>(
                      stream: _service.watchTables(widget.eventId),
                      builder: (context, snap) {
                        final tables = snap.data ?? [];
                        return DropdownButtonFormField<String?>(
                          value: _selectedTableId,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          dropdownColor: isDark ? AppColors.charcoal : Colors.white,
                          decoration: _inputDecoration(l.navTables, Icons.table_restaurant_rounded, theme),
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(l.tableOptional),
                            ),
                            ...tables.map(
                              (t) => DropdownMenuItem(
                                value: t.id,
                                child: Text(t.name),
                              ),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedTableId = v),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _dietController,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _inputDecoration(l.dietaryLabel, Icons.no_food_rounded, theme),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white54 : Colors.black45,
          ),
          child: Text(l.cancelButton),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(l),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brushedGold,
            foregroundColor: AppColors.charcoal,
            elevation: 8,
            shadowColor: AppColors.brushedGold.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.charcoal),
                )
              : Text(
                  l.saveButton.toUpperCase(), 
                  style: const TextStyle(
                    fontWeight: FontWeight.w800, 
                    letterSpacing: 1.5,
                    fontSize: 13,
                  ),
                ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: AppColors.brushedGold, size: 20),
      filled: true,
      fillColor: baseColor.withValues(alpha: 0.03),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.brushedGold, width: 1.5),
      ),
    );
  }

  Widget _buildRoleSelector(AppLocalizations l, ThemeData theme) {
    // Collect unique custom roles from all guests
    final uniqueCustomRoles = <String, int?>{};
    if (widget.allGuests != null) {
      for (final g in widget.allGuests!) {
        if (g.customRole != null) {
          uniqueCustomRoles[g.customRole!] = g.customRoleIcon;
        }
      }
    }

    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: _selectedCustomRole ?? _role.name,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          dropdownColor: isDark ? AppColors.charcoal : Colors.white,
          decoration: _inputDecoration(l.roleLabel, Icons.star_rounded, theme).copyWith(
            prefixIcon: Icon(
              _selectedCustomRole != null
                  ? (_selectedCustomRoleIcon != null
                        ? IconData(
                            _selectedCustomRoleIcon!,
                            fontFamily: 'MaterialIcons',
                          )
                        : Icons.star_rounded)
                  : Icons.star_rounded,
              color: AppColors.brushedGold,
              size: 20,
            ),
          ),
          items: [
            ...GuestRole.values.map(
              (r) => DropdownMenuItem(
                value: r.name,
                child: Text(_roleLabel(l, r)),
              ),
            ),
            ...uniqueCustomRoles.entries.map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Row(
                  children: [
                    if (e.value != null)
                      Icon(
                        IconData(e.value!, fontFamily: 'MaterialIcons'),
                        size: 18,
                        color: AppColors.brushedGold,
                      ),
                    if (e.value != null) const SizedBox(width: 8),
                    Text(e.key),
                  ],
                ),
              ),
            ),
            const DropdownMenuItem(
              value: "ADD_NEW",
              child: Text(
                "+ Añadir nuevo rol...",
                style: TextStyle(
                  color: AppColors.brushedGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          onChanged: (val) {
            if (val == "ADD_NEW") {
              _showAddNewRoleDialog();
            } else {
              final standardRole = GuestRole.values.firstWhere(
                (r) => r.name == val,
                orElse: () => GuestRole.regular,
              );
              setState(() {
                if (GuestRole.values.any((r) => r.name == val)) {
                  _role = standardRole;
                  _selectedCustomRole = null;
                  _selectedCustomRoleIcon = null;
                } else {
                  _selectedCustomRole = val;
                  _selectedCustomRoleIcon = uniqueCustomRoles[val];
                }
              });
            }
          },
        ),
      ],
    );
  }

  void _showAddNewRoleDialog() {
    final controller = TextEditingController();
    int? selectedIconCode;

    final icons = [
      Icons.star,
      Icons.auto_awesome,
      Icons.favorite,
      Icons.verified,
      Icons.workspace_premium,
      Icons.person,
      Icons.people,
      Icons.celebration,
      Icons.card_membership,
      Icons.military_tech,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nuevo Rol"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Ej: Dama de Honor, Chambelán...",
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Elige un icono:",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 250,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: icons.map((icon) {
                    final isSelected = selectedIconCode == icon.codePoint;
                    return InkWell(
                      onTap: () => setDialogState(
                        () => selectedIconCode = icon.codePoint,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.brushedGold.withValues(alpha: 0.2)
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.brushedGold
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected
                              ? AppColors.brushedGold
                              : Colors.grey,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    _selectedCustomRole = name;
                    _selectedCustomRoleIcon = selectedIconCode;
                  });
                }
                Navigator.pop(context);
              },
              child: const Text("Añadir"),
            ),
          ],
        ),
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int count;
  final IconData? icon;
  final ValueChanged<int> onChanged;
  final VoidCallback? onRemove;
  const _CounterRow({
    required this.label,
    required this.count,
    this.icon,
    required this.onChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: baseColor.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(icon ?? Icons.person_rounded, size: 20, color: AppColors.brushedGold),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: baseColor.withValues(alpha: 0.7),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 18),
                  onPressed: count > 0 ? () => onChanged(count - 1) : null,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  color: AppColors.brushedGold,
                ),
                Text(
                  '$count',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add_rounded, size: 18),
                  onPressed: () => onChanged(count + 1),
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  color: AppColors.brushedGold,
                ),
              ],
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
              onPressed: onRemove,
            ),
          ],
        ],
      ),
    );
  }
}

class _CustomRoleChip extends StatelessWidget {
  final String label;
  final int? iconCode;
  const _CustomRoleChip({required this.label, this.iconCode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brushedGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconCode != null)
            Icon(
              IconData(iconCode!, fontFamily: 'MaterialIcons'),
              size: 12,
              color: AppColors.brushedGold,
            ),
          if (iconCode != null) const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.brushedGold,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TablePickerFlow extends StatefulWidget {
  final GuestModel guest;
  final List<TableModel> tables;
  final List<SeatingAssignment> assignments;
  final List<SeatingAssignment> guestAssignments;
  final String eventId;
  final FirestoreService service;
  final AppLocalizations l;

  const _TablePickerFlow({
    required this.guest,
    required this.tables,
    required this.assignments,
    required this.guestAssignments,
    required this.eventId,
    required this.service,
    required this.l,
  });

  @override
  State<_TablePickerFlow> createState() => _TablePickerFlowState();
}

class _TablePickerFlowState extends State<_TablePickerFlow> {
  TableModel? _selectedTable;
  Map<String, int> _toAssign = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_selectedTable != null) {
      return _buildCountPicker(theme);
    }

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        "Asignar mesa para ${widget.guest.displayName}",
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 400,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.tables.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return ListTile(
                leading: const Icon(Icons.no_accounts_rounded),
                title: const Text("Sin mesa"),
                subtitle: const Text("Limpia todas las asignaciones"),
                onTap: () async {
                  for (var a in widget.guestAssignments) {
                    await widget.service.deleteAssignment(widget.eventId, a.id);
                  }
                  if (mounted) Navigator.pop(context);
                },
              );
            }
            final t = widget.tables[i - 1];
            final assignment = widget.guestAssignments.firstWhere(
              (a) => a.tableId == t.id,
              orElse: () => SeatingAssignment(
                id: '',
                guestId: widget.guest.id,
                tableId: t.id,
                counts: {},
              ),
            );
            final isAssigned = assignment.id.isNotEmpty;

            return ListTile(
              leading: Icon(
                Icons.table_restaurant_rounded,
                color: isAssigned ? AppColors.brushedGold : null,
              ),
              title: Text(t.name),
              subtitle: Text(
                isAssigned
                    ? "Asignado (${assignment.total})"
                    : "${t.capacity} asientos",
              ),
              trailing: isAssigned
                  ? const Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: AppColors.brushedGold,
                    )
                  : null,
              onTap: () {
                setState(() {
                  _selectedTable = t;
                  if (isAssigned) {
                    _toAssign = Map<String, int>.from(assignment.counts);
                  } else {
                    _toAssign = {
                      if (widget.guest.adults > 0) 'Adultos': 0,
                      if (widget.guest.children > 0) 'Niños': 0,
                      if (widget.guest.disabled > 0) 'Discapacitados': 0,
                      ...widget.guest.customCounts.map(
                        (k, v) => MapEntry(k, 0),
                      ),
                    };
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.l.cancelButton),
        ),
      ],
    );
  }

  Widget _buildCountPicker(ThemeData theme) {
    final g = widget.guest;
    final t = _selectedTable!;
    final assignment = widget.guestAssignments.firstWhere(
      (a) => a.tableId == t.id,
      orElse: () =>
          SeatingAssignment(id: '', guestId: g.id, tableId: t.id, counts: {}),
    );

    // Calcular ocupados en OTRAS mesas para este invitado
    Map<String, int> alreadyAssigned = {
      'Adultos': widget.guestAssignments
          .where((a) => a.id != assignment.id)
          .fold(0, (sum, a) => sum + (a.counts['Adultos'] ?? 0)),
      'Niños': widget.guestAssignments
          .where((a) => a.id != assignment.id)
          .fold(0, (sum, a) => sum + (a.counts['Niños'] ?? 0)),
      'Discapacitados': widget.guestAssignments
          .where((a) => a.id != assignment.id)
          .fold(0, (sum, a) => sum + (a.counts['Discapacitados'] ?? 0)),
    };
    g.customCounts.forEach((key, _) {
      alreadyAssigned[key] = widget.guestAssignments
          .where((a) => a.id != assignment.id)
          .fold(0, (sum, a) => sum + (a.counts[key] ?? 0));
    });

    final categories = _toAssign.keys.toList();
    final totalToAssign = _toAssign.values.fold(0, (sum, v) => sum + v);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text("¿Cuántos en ${t.name}?", textAlign: TextAlign.center),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...categories.map((cat) {
              final maxAvailable =
                  _getMaxForCategory(cat, g) - (alreadyAssigned[cat] ?? 0);
              if (maxAvailable <= 0 && _toAssign[cat] == 0)
                return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cat,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: _toAssign[cat]! > 0
                          ? () => setState(
                              () => _toAssign[cat] = _toAssign[cat]! - 1,
                            )
                          : null,
                    ),
                    Text(
                      "${_toAssign[cat]}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: _toAssign[cat]! < maxAvailable
                          ? () => setState(
                              () => _toAssign[cat] = _toAssign[cat]! + 1,
                            )
                          : null,
                    ),
                    Text(
                      "/ $maxAvailable",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  for (var cat in categories) {
                    final maxAvail =
                        _getMaxForCategory(cat, g) -
                        (alreadyAssigned[cat] ?? 0);
                    _toAssign[cat] = maxAvail;
                  }
                });
              },
              icon: const Icon(
                Icons.group_add_rounded,
                color: AppColors.brushedGold,
              ),
              label: const Text(
                "Asignar todo el grupo",
                style: TextStyle(
                  color: AppColors.brushedGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.brushedGold.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _selectedTable = null),
          child: const Text("Atrás"),
        ),
        ElevatedButton(
          onPressed: (totalToAssign > 0 || assignment.id.isNotEmpty)
              ? () async {
                  final cleanedCounts = Map<String, int>.from(_toAssign)
                    ..removeWhere((k, v) => v == 0);

                  if (cleanedCounts.isEmpty) {
                    if (assignment.id.isNotEmpty) {
                      await widget.service.deleteAssignment(
                        widget.eventId,
                        assignment.id,
                      );
                    }
                  } else {
                    final newAssignment = SeatingAssignment(
                      id: assignment.id,
                      guestId: g.id,
                      tableId: t.id,
                      counts: cleanedCounts,
                    );

                    if (newAssignment.id.isEmpty) {
                      await widget.service.addAssignment(
                        widget.eventId,
                        newAssignment,
                      );
                    } else {
                      await widget.service.updateAssignment(
                        widget.eventId,
                        newAssignment.id,
                        newAssignment.toFirestore(),
                      );
                    }
                  }
                  if (mounted) Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brushedGold,
            foregroundColor: AppColors.charcoal,
          ),
          child: const Text("Confirmar"),
        ),
      ],
    );
  }

  int _getMaxForCategory(String cat, GuestModel g) {
    if (cat == 'Adultos') return g.adults;
    if (cat == 'Niños') return g.children;
    if (cat == 'Discapacitados') return g.disabled;
    return g.customCounts[cat] ?? 0;
  }
}
