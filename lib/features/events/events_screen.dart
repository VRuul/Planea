import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/event_model.dart';
import '../../data/services/firestore_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';
import './widgets/event_utils.dart';
import './join_event_dialog.dart';


class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final userId = context.read<AuthProvider>().currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l.eventsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_rounded),
            tooltip: 'Unirse a un evento',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const JoinEventDialog(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEventDialog(context, userId),
        backgroundColor: AppColors.brushedGold,
        foregroundColor: AppColors.charcoal,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.newEvent, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
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

  void _showEventDialog(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (_) => EventDialog(userId: userId),
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;
    final typeInfo = getEventTypeInfo(context, event.type);

    return GestureDetector(
      onTap: () => context.go('/events/${event.id}'),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(color: AppColors.brushedGold.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.brushedGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(typeInfo.icon, color: AppColors.brushedGold, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(event.name, style: theme.textTheme.titleLarge?.copyWith(color: baseColor, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: baseColor.withValues(alpha: 0.4), size: 12),
                      const SizedBox(width: 6),
                      Text(
                        '${event.date.day}/${event.date.month}/${event.date.year}',
                        style: theme.textTheme.labelSmall?.copyWith(color: baseColor.withValues(alpha: 0.4), letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brushedGold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeInfo.label.toUpperCase(),
                          style: const TextStyle(color: AppColors.brushedGold, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: baseColor.withValues(alpha: 0.2), size: 16),
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
            decoration: BoxDecoration(
                color: AppColors.brushedGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.2))),
            child: const Icon(Icons.celebration_outlined,
                size: 48, color: AppColors.brushedGold),
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

class EventDialog extends StatefulWidget {
  final String userId;
  final EventModel? event;
  const EventDialog({required this.userId, this.event});

  @override
  State<EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<EventDialog> {
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  final _budgetController = TextEditingController();
  final _goalController = TextEditingController();
  final _celebrantController = TextEditingController();
  
  EventType _type = EventType.wedding;
  String? _selectedCustomType;
  int? _selectedCustomTypeIcon;
  Color _primaryColor = AppColors.charcoal;
  Color _secondaryColor = AppColors.brushedGold;
  
  DateTime _date = DateTime.now().add(const Duration(days: 30));
  bool _saving = false;
  bool _isAdvancedExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      final e = widget.event!;
      _nameController.text = e.name;
      _venueController.text = e.venue ?? "";
      _budgetController.text = e.budget.toStringAsFixed(0);
      _goalController.text = e.guestGoal.toString();
      _celebrantController.text = e.celebrantNames ?? "";
      _type = e.type;
      _selectedCustomType = e.customType;
      _selectedCustomTypeIcon = e.customTypeIcon;
      _primaryColor = e.primaryColor;
      _secondaryColor = e.secondaryColor;
      _date = e.date;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    _budgetController.dispose();
    _goalController.dispose();
    _celebrantController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l) async {
    setState(() => _saving = true);
    try {
      final isEdit = widget.event != null;
      final typeInfo = getEventTypeInfo(context, _type);
      final typeName = _selectedCustomType ?? typeInfo.label;
      final protagonists = _celebrantController.text.trim();
      
      // Construimos el nombre automáticamente: "Boda de Ana y Luis" o solo "Boda" si está vacío
      final autoName = protagonists.isEmpty ? typeName : "$typeName de $protagonists";

      final event = (widget.event ?? EventModel(
        id: const Uuid().v4(),
        name: "",
        type: EventType.other,
        date: DateTime.now(),
        primaryColor: Colors.black,
        secondaryColor: Colors.white,
        organizerId: widget.userId,
      )).copyWith(
        name: autoName,
        type: _type,
        customType: _selectedCustomType,
        customTypeIcon: _selectedCustomTypeIcon,
        date: _date,
        primaryColor: _primaryColor,
        secondaryColor: _secondaryColor,
        venue: _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
        budget: double.tryParse(_budgetController.text) ?? 0,
        guestGoal: int.tryParse(_goalController.text) ?? 0,
        celebrantNames: protagonists.isEmpty ? null : protagonists,
      );

      if (isEdit) {
        await FirestoreService().updateEvent(event);
      } else {
        await FirestoreService().createEvent(event);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.event == null ? l.newEvent : "Editar Evento", 
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── CAMPOS BÁSICOS ──────────────────────────────────────────
              // ── TIPO DE EVENTO (Primero para definir los labels de abajo) ────────
              _buildTypeSelector(l, theme),
              const SizedBox(height: 16),

              // ── PROTAGONISTAS (Ahora el campo principal de identificación) ───────
              TextField(
                controller: _celebrantController,
                decoration: InputDecoration(
                  labelText: getEventTypeInfo(context, _type).protagonistLabel,
                  prefixIcon: const Icon(Icons.people_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),

              // ── FECHA ────────────────────────────────────────────────────────
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
              
              // ── SECCIÓN AVANZADA ────────────────────────────────────────
              const SizedBox(height: 12),
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text("Más información", style: theme.textTheme.labelMedium?.copyWith(color: AppColors.brushedGold)),
                  trailing: Icon(_isAdvancedExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.brushedGold),
                  onExpansionChanged: (v) => setState(() => _isAdvancedExpanded = v),
                  childrenPadding: const EdgeInsets.only(top: 8),
                  children: [
                    TextField(
                      controller: _venueController,
                      decoration: InputDecoration(
                        labelText: l.venueOptional,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _budgetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Presupuesto",
                              prefixIcon: Icon(Icons.monetization_on_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _goalController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Meta de invitados",
                              prefixIcon: Icon(Icons.group_outlined),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    const Text("Colores del Evento", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _ColorPickerButton(
                          label: "Primario",
                          color: _primaryColor,
                          onTap: () => _showColorPicker(true),
                        ),
                        const SizedBox(width: 16),
                        _ColorPickerButton(
                          label: "Secundario",
                          color: _secondaryColor,
                          onTap: () => _showColorPicker(false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancelButton)),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(l),
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.createEvent),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(AppLocalizations l, ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCustomType ?? _type.name,
      decoration: InputDecoration(
        labelText: l.eventTypeLabel,
        prefixIcon: Icon(
          _selectedCustomType != null 
            ? (_selectedCustomTypeIcon != null ? IconData(_selectedCustomTypeIcon!, fontFamily: 'MaterialIcons') : Icons.celebration)
            : getEventTypeInfo(context, _type).icon,
        ),
      ),
      items: [
        ...EventType.values.map((t) {
          final info = getEventTypeInfo(context, t);
          return DropdownMenuItem(
            value: t.name,
            child: Row(
              children: [
                Icon(info.icon, size: 18, color: AppColors.brushedGold),
                const SizedBox(width: 12),
                Text(info.label),
              ],
            ),
          );
        }),
        const DropdownMenuItem(
          value: "ADD_NEW",
          child: Text("+ Añadir nuevo tipo...", style: TextStyle(color: AppColors.brushedGold, fontWeight: FontWeight.bold)),
        ),
      ],
      onChanged: (val) {
        if (val == "ADD_NEW") {
          _showAddNewTypeDialog();
        } else {
          final standardType = EventType.values.firstWhere((t) => t.name == val, orElse: () => EventType.other);
          setState(() {
            _type = standardType;
            _selectedCustomType = null;
            _selectedCustomTypeIcon = null;
          });
        }
      },
    );
  }

  void _showAddNewTypeDialog() {
    final controller = TextEditingController();
    int? selectedIconCode;
    final icons = [Icons.favorite, Icons.auto_awesome, Icons.cake, Icons.school, Icons.business_center, Icons.celebration, Icons.music_note, Icons.restaurant, Icons.beach_access, Icons.nightlife];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nuevo Tipo de Evento"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: "Ej: Baby Shower, Bautizo...")),
              const SizedBox(height: 20),
              const Text("Elige un icono:"),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12, runSpacing: 12,
                children: icons.map((icon) {
                  final isSelected = selectedIconCode == icon.codePoint;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedIconCode = icon.codePoint),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.brushedGold.withValues(alpha: 0.2) : Colors.transparent,
                        border: Border.all(color: isSelected ? AppColors.brushedGold : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: isSelected ? AppColors.brushedGold : Colors.grey),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            TextButton(
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    _selectedCustomType = controller.text.trim();
                    _selectedCustomTypeIcon = selectedIconCode;
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

  void _showColorPicker(bool isPrimary) {
    final colors = [
      AppColors.charcoal, AppColors.brushedGold,
      const Color(0xFF1A1A1A), const Color(0xFFD4AF37),
      const Color(0xFF722F37), const Color(0xFF5D3FD3),
      const Color(0xFF0047AB), const Color(0xFF008080),
      const Color(0xFFE0115F), const Color(0xFFFFD700),
      const Color(0xFFC0C0C0), const Color(0xFF50C878),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Color ${isPrimary ? 'Primario' : 'Secundario'}"),
        content: SizedBox(
          width: 300,
          child: Wrap(
            spacing: 12, runSpacing: 12,
            alignment: WrapAlignment.center,
            children: colors.map((c) => InkWell(
              onTap: () {
                setState(() => isPrimary ? _primaryColor = c : _secondaryColor = c);
                Navigator.pop(context);
              },
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }
}

class _ColorPickerButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ColorPickerButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(width: 20, height: 20, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
