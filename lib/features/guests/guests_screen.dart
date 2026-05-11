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
        onPressed: () => _showAddGuestDialog(context, eventId),
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
                      g.name.toLowerCase().contains(_search.toLowerCase());
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

  Future<void> _showAddGuestDialog(BuildContext context, String eventId) async {
    await showDialog(
      context: context,
      builder: (_) => _AddGuestDialog(eventId: eventId),
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Text(
            guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?',
            style: TextStyle(
                color: statusColor, fontWeight: FontWeight.w700, fontSize: 18),
          ),
        ),
        title: Text(guest.name,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Wrap(
          spacing: 6, runSpacing: 4,
          children: [
            GuestRoleChip(role: guest.role),
            if (guest.tableId != null)
              _SmallTag(
                  label: l.tableLabel(guest.tableId!),
                  color: Colors.blue.shade300),
            if (guest.plusOnes > 0)
              _SmallTag(
                  label: l.companionsLabel(guest.plusOnes),
                  color: Colors.purple.shade300),
          ],
        ),
        trailing: PopupMenuButton<GuestStatus>(
          icon: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(_statusLabel(l, guest.status),
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          onSelected: (s) =>
              _service.updateGuestStatus(eventId, guest.id, s),
          itemBuilder: (_) => GuestStatus.values
              .map((s) => PopupMenuItem(
                  value: s, child: Text(_statusLabel(l, s))))
              .toList(),
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

class _AddGuestDialog extends StatefulWidget {
  final String eventId;
  const _AddGuestDialog({required this.eventId});

  @override
  State<_AddGuestDialog> createState() => _AddGuestDialogState();
}

class _AddGuestDialogState extends State<_AddGuestDialog> {
  final _nameController = TextEditingController();
  final _tableController = TextEditingController();
  GuestRole _role = GuestRole.regular;
  int _plusOnes = 0;
  bool _saving = false;
  final _service = FirestoreService();

  @override
  void dispose() {
    _nameController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  Future<void> _save(AppLocalizations l) async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final guest = GuestModel(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        role: _role,
        status: GuestStatus.pending,
        tableId: _tableController.text.trim().isEmpty
            ? null
            : _tableController.text.trim(),
        plusOnes: _plusOnes,
        eventId: widget.eventId,
      );
      await _service.addGuest(widget.eventId, guest);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(l.addGuestTitle,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l.fullNameLabel,
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<GuestRole>(
              initialValue: _role,
              decoration: InputDecoration(
                labelText: l.roleLabel,
                prefixIcon: const Icon(Icons.star_outline),
              ),
              items: GuestRole.values
                  .map((r) => DropdownMenuItem(
                      value: r, child: Text(_roleLabel(l, r))))
                  .toList(),
              onChanged: (v) => setState(() => _role = v!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tableController,
              decoration: InputDecoration(
                labelText: l.tableOptional,
                prefixIcon: const Icon(Icons.table_restaurant_outlined),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: Text(l.companionsCount(_plusOnes),
                        style: theme.textTheme.bodyMedium)),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _plusOnes > 0
                      ? () => setState(() => _plusOnes--)
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => setState(() => _plusOnes++),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancelButton)),
        ElevatedButton(
          onPressed: _saving ? null : () => _save(l),
          child: _saving
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l.saveButton),
        ),
      ],
    );
  }
}
