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
import '../shared/widgets/premium_picker.dart';


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
        primaryColor: AppColors.charcoal,
        secondaryColor: AppColors.brushedGold,
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return AlertDialog(
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          Icon(widget.event == null ? Icons.add_circle_outline_rounded : Icons.edit_rounded, color: AppColors.brushedGold),
          const SizedBox(width: 12),
          Text(widget.event == null ? l.newEvent : "Editar Evento", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _buildTypeSelector(l, theme),
              const SizedBox(height: 16),
              TextField(controller: _celebrantController, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: _inputDecoration(getEventTypeInfo(context, _type).protagonistLabel, Icons.people_outline_rounded, theme)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDate,
                child: AbsorbPointer(
                  child: TextField(style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: _inputDecoration(l.eventDateLabel('${_date.day}/${_date.month}/${_date.year}'), Icons.calendar_today_outlined, theme)),
                ),
              ),
              const SizedBox(height: 12),
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text("Más información", style: theme.textTheme.labelMedium?.copyWith(color: AppColors.brushedGold, fontWeight: FontWeight.w700)),
                  trailing: Icon(_isAdvancedExpanded ? Icons.expand_less : Icons.expand_more, color: AppColors.brushedGold),
                  onExpansionChanged: (v) => setState(() => _isAdvancedExpanded = v),
                  childrenPadding: const EdgeInsets.only(top: 8),
                  children: [
                    TextField(controller: _venueController, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: _inputDecoration(l.venueOptional, Icons.location_on_outlined, theme)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _budgetController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: _inputDecoration("Presupuesto", Icons.monetization_on_outlined, theme))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _goalController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: _inputDecoration("Meta de invitados", Icons.group_outlined, theme))),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white54 : Colors.black45), child: Text(l.cancelButton)),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(l),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brushedGold,
            foregroundColor: AppColors.charcoal,
            elevation: 8,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.charcoal)) : Text(widget.event == null ? l.createEvent : "GUARDAR", style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildTypeSelector(AppLocalizations l, ThemeData theme) {
    final currentVal = _selectedCustomType ?? _type.name;
    final currentIcon = _selectedCustomType != null 
        ? (_selectedCustomTypeIcon != null ? IconData(_selectedCustomTypeIcon!, fontFamily: 'MaterialIcons') : Icons.celebration) 
        : getEventTypeInfo(context, _type).icon;

    return PremiumPicker<String>(
      label: l.eventTypeLabel,
      icon: currentIcon,
      value: currentVal,
      items: [
        ...EventType.values.map((t) {
          final info = getEventTypeInfo(context, t);
          return PremiumPickerItem(value: t.name, label: info.label, icon: info.icon);
        }),
        PremiumPickerItem(
          value: "ADD_NEW", 
          label: "+ Añadir nuevo tipo...", 
          icon: Icons.add_circle_outline_rounded,
          isSpecial: true,
        ),
      ],
      onChanged: (val) {
        if (val == "ADD_NEW") {
          _showAddNewTypeDialog();
        } else if (val != null) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? AppColors.charcoal : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          title: Text("Nuevo Tipo de Evento", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5, color: isDark ? Colors.white : Colors.black87)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              TextField(controller: controller, autofocus: true, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: _inputDecoration("Ej: Baby Shower, Bautizo...", Icons.edit_note_rounded, Theme.of(context))),
              const SizedBox(height: 24),
              const Text("ELIGE UN ICONO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.brushedGold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                child: Wrap(
                  spacing: 12, runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: icons.map((icon) {
                    final isSelected = selectedIconCode == icon.codePoint;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedIconCode = icon.codePoint),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brushedGold.withValues(alpha: 0.1) : Colors.transparent, 
                          border: Border.all(color: isSelected ? AppColors.brushedGold : (isDark ? Colors.white10 : Colors.black12)), 
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(icon, color: isSelected ? AppColors.brushedGold : (isDark ? Colors.white30 : Colors.black38), size: 20),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white54 : Colors.black45), child: const Text("Cancelar")),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () { if (controller.text.trim().isNotEmpty) { setState(() { _selectedCustomType = controller.text.trim(); _selectedCustomTypeIcon = selectedIconCode; }); } Navigator.pop(context); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brushedGold, foregroundColor: AppColors.charcoal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: const Text("Añadir", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark, baseColor = isDark ? Colors.white : Colors.black;
    return InputDecoration(labelText: label, labelStyle: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 14), prefixIcon: Icon(icon, color: AppColors.brushedGold, size: 20), filled: true, fillColor: baseColor.withValues(alpha: 0.03), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.brushedGold, width: 1.5)));
  }
}
