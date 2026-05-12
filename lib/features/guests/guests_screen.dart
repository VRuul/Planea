import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/event_provider.dart';
import '../../data/models/guest_model.dart';
import '../../data/services/firestore_service.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';
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
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final eventId = context.watch<EventProvider>().currentEventId;

    if (eventId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.guestsTitle)),
        body: Center(child: Text(l.selectEventFirst)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.guestsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterSheet(context, l),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGuestDialog(context, eventId),
        backgroundColor: AppColors.brushedGold,
        foregroundColor: AppColors.charcoal,
        icon: const Icon(Icons.person_add_rounded),
        label: Text(l.addGuest),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l.searchGuest,
                prefixIcon: const Icon(Icons.search_rounded),
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
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<GuestModel>>(
              stream: _service.watchGuests(eventId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.brushedGold));
                }
                final filtered = (snap.data ?? []).where((g) {
                  final matchSearch = _search.isEmpty ||
                      g.displayName.toLowerCase().contains(_search.toLowerCase());
                  final matchStatus =
                      _filterStatus == null || g.status == _filterStatus;
                  final matchRole =
                      _filterRole == null || g.role == _filterRole;
                  return matchSearch && matchStatus && matchRole;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 64, color: AppColors.brushedGold),
                        const SizedBox(height: 12),
                        Text(l.noGuests,
                            style: theme.textTheme.titleMedium),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _GuestCard(guest: filtered[i], eventId: eventId),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FilterSheet(
        currentStatus: _filterStatus,
        currentRole: _filterRole,
        onApply: (status, role) =>
            setState(() { _filterStatus = status; _filterRole = role; }),
      ),
    );
  }

  Future<void> _showGuestDialog(BuildContext context, String eventId, [GuestModel? guest]) async {
    await showDialog(
      context: context,
      builder: (_) => _GuestDialog(eventId: eventId, guest: guest),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

String _statusLabel(AppLocalizations l, GuestStatus s) {
  switch (s) {
    case GuestStatus.confirmed: return l.guestConfirmed;
    case GuestStatus.pending: return l.guestPending;
    case GuestStatus.declined: return l.guestDeclined;
  }
}

String _roleLabel(AppLocalizations l, GuestRole r) {
  switch (r) {
    case GuestRole.padrino: return l.rolePadrino;
    case GuestRole.vip: return l.roleVip;
    case GuestRole.regular: return l.roleRegular;
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _GuestCard extends StatelessWidget {
  final GuestModel guest;
  final String eventId;
  _GuestCard({required this.guest, required this.eventId});
  final _service = FirestoreService();

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
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Text(
            guest.displayName.isNotEmpty ? guest.displayName[0].toUpperCase() : '?',
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
        title: Text(guest.displayName,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Wrap(
          spacing: 6, runSpacing: 4,
          children: [
            GuestRoleChip(role: guest.role),
            if (guest.tableId != null)
              _SmallTag(label: l.tableLabel(guest.tableId!), color: Colors.blue.shade300),
            _SmallTag(label: 'Total: ${guest.totalSeats}', color: Colors.purple.shade300),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(_statusLabel(l, guest.status),
              style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (guest.adults > 0) _CountIndicator(label: l.countAdults, count: guest.adults, icon: Icons.person),
                    if (guest.children > 0) _CountIndicator(label: l.countChildren, count: guest.children, icon: Icons.child_care),
                    if (guest.teenagers > 0) _CountIndicator(label: l.countTeenagers, count: guest.teenagers, icon: Icons.face),
                    if (guest.disabled > 0) _CountIndicator(label: l.countDisabled, count: guest.disabled, icon: Icons.accessible),
                  ],
                ),
                const Divider(height: 32),
                if (guest.phone != null || guest.email != null || guest.socialMedia != null) ...[
                  Text(l.contactInfoSection, style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  if (guest.phone != null) _ContactRow(icon: Icons.phone_outlined, value: guest.phone!),
                  if (guest.email != null) _ContactRow(icon: Icons.email_outlined, value: guest.email!),
                  if (guest.socialMedia != null) _ContactRow(icon: Icons.link_rounded, value: guest.socialMedia!),
                  const SizedBox(height: 16),
                ],
                if (guest.notes != null && guest.notes!.isNotEmpty) ...[
                  Text(l.notesLabel, style: theme.textTheme.labelLarge),
                  Text(guest.notes!, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                ],
                if (guest.dietaryRestrictions != null && guest.dietaryRestrictions!.isNotEmpty) ...[
                  Text(l.dietaryLabel, style: theme.textTheme.labelLarge?.copyWith(color: Colors.orange.shade700)),
                  Text(guest.dietaryRestrictions!, style: theme.textTheme.bodySmall),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showDeleteDialog(context, l),
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      label: Text(l.deleteButton, style: const TextStyle(color: Colors.red)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        // Using a private method from the parent state is tricky, 
                        // so we'll trigger it via a callback or find another way.
                        // Actually, since _GuestCard is inside _GuestsScreenState's build, 
                        // we can pass the function.
                        final state = context.findAncestorStateOfType<_GuestsScreenState>();
                        state?._showGuestDialog(context, eventId, guest);
                      },
                      icon: const Icon(Icons.edit_outlined, color: AppColors.brushedGold, size: 18),
                      label: Text(l.editButton, style: const TextStyle(color: AppColors.brushedGold)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _showStatusPicker(context, l);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l.applyFilters),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(BuildContext context, AppLocalizations l) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: GuestStatus.values.map((s) => ListTile(
          title: Text(_statusLabel(l, s)),
          onTap: () {
            _service.updateGuestStatus(eventId, guest.id, s);
            Navigator.pop(context);
          },
        )).toList(),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancelButton)),
          TextButton(
            onPressed: () {
              _service.deleteGuest(eventId, guest.id);
              Navigator.pop(context);
            },
            child: Text(l.deleteButton, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CountIndicator extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  const _CountIndicator({required this.label, required this.count, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: count > 0 ? AppColors.brushedGold : Colors.grey.shade400),
        const SizedBox(height: 4),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _ContactRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
      ]),
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
          borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w600)),
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
  final GuestStatus? currentStatus;
  final GuestRole? currentRole;
  final Function(GuestStatus?, GuestRole?) onApply;

  const _FilterSheet(
      {this.currentStatus, this.currentRole, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  GuestStatus? _status;
  GuestRole? _role;

  @override
  void initState() {
    super.initState();
    _status = widget.currentStatus;
    _role = widget.currentRole;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.filterGuests,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Text(l.filterStatus, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: GuestStatus.values
                .map((s) => ChoiceChip(
                      label: Text(_statusLabel(l, s)),
                      selected: _status == s,
                      onSelected: (v) =>
                          setState(() => _status = v ? s : null),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(l.filterRole, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: GuestRole.values
                .map((r) => ChoiceChip(
                      label: Text(_roleLabel(l, r)),
                      selected: _role == r,
                      onSelected: (v) =>
                          setState(() => _role = v ? r : null),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(_status, _role);
                Navigator.pop(context);
              },
              child: Text(l.applyFilters),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestDialog extends StatefulWidget {
  final String eventId;
  final GuestModel? guest;
  const _GuestDialog({required this.eventId, this.guest});

  @override
  State<_GuestDialog> createState() => _GuestDialogState();
}

class _GuestDialogState extends State<_GuestDialog> {
  final _displayController = TextEditingController();
  final _firstController = TextEditingController();
  final _lastController = TextEditingController();
  final _tableController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _socialController = TextEditingController();
  final _notesController = TextEditingController();
  final _dietController = TextEditingController();

  GuestRole _role = GuestRole.regular;
  int _adults = 1, _children = 0, _teenagers = 0, _disabled = 0;
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
      _tableController.text = g.tableId ?? '';
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
      _showSplitName = g.firstName != null || g.lastName != null;
    }
  }

  @override
  void dispose() {
    _displayController.dispose();
    _firstController.dispose();
    _lastController.dispose();
    _tableController.dispose();
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
        tableId: _tableController.text.trim().isEmpty ? null : _tableController.text.trim(),
        adults: _adults,
        children: _children,
        teenagers: _teenagers,
        disabled: _disabled,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        socialMedia: _socialController.text.trim().isEmpty ? null : _socialController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        dietaryRestrictions: _dietController.text.trim().isEmpty ? null : _dietController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(widget.guest == null ? l.addGuestTitle : "Editar Invitado", 
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── CAMPOS BÁSICOS ──────────────────────────────────────────
              TextField(
                controller: _displayController,
                decoration: InputDecoration(
                  labelText: l.guestDisplayName,
                  prefixIcon: const Icon(Icons.badge_outlined),
                ),
              ),
              const SizedBox(height: 16),
              _CounterRow(
                label: l.countAdults,
                count: _adults,
                onChanged: (v) => setState(() => _adults = v),
              ),
              const SizedBox(height: 12),
              _CounterRow(
                label: l.countChildren,
                count: _children,
                onChanged: (v) => setState(() => _children = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GuestRole>(
                value: _role,
                decoration: InputDecoration(labelText: l.roleLabel, prefixIcon: const Icon(Icons.star_outline)),
                items: GuestRole.values.map((r) => DropdownMenuItem(value: r, child: Text(_roleLabel(l, r)))).toList(),
                onChanged: (v) => setState(() => _role = v!),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: l.contactPhone, prefixIcon: const Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(labelText: l.notesLabel, prefixIcon: const Icon(Icons.notes_rounded)),
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
                    Row(children: [
                      Checkbox(value: _showSplitName, onChanged: (v) => setState(() => _showSplitName = v!)),
                      Text("Separar nombre y apellido", style: theme.textTheme.bodySmall),
                    ]),
                    if (_showSplitName) ...[
                      TextField(controller: _firstController, decoration: InputDecoration(labelText: l.guestFirstName)),
                      const SizedBox(height: 12),
                      TextField(controller: _lastController, decoration: InputDecoration(labelText: l.guestLastName)),
                    ],
                    const Divider(height: 32),
                    _CounterRow(label: l.countTeenagers, count: _teenagers, onChanged: (v) => setState(() => _teenagers = v)),
                    _CounterRow(label: l.countDisabled, count: _disabled, onChanged: (v) => setState(() => _disabled = v)),
                    const Divider(height: 32),
                    TextField(controller: _emailController, decoration: InputDecoration(labelText: l.contactEmail, prefixIcon: const Icon(Icons.email_outlined))),
                    const SizedBox(height: 12),
                    TextField(controller: _socialController, decoration: InputDecoration(labelText: l.contactSocial, prefixIcon: const Icon(Icons.link_rounded))),
                    const SizedBox(height: 12),
                    TextField(controller: _tableController, decoration: InputDecoration(labelText: l.tableOptional, prefixIcon: const Icon(Icons.table_restaurant_outlined))),
                    const SizedBox(height: 12),
                    TextField(controller: _dietController, decoration: InputDecoration(labelText: l.dietaryLabel, prefixIcon: const Icon(Icons.no_food_outlined))),
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
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.saveButton),
        ),
      ],
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int count;
  final ValueChanged<int> onChanged;
  const _CounterRow({required this.label, required this.count, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: count > 0 ? () => onChanged(count - 1) : null),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => onChanged(count + 1)),
      ],
    );
  }
}
