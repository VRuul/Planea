import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/event_model.dart';
import '../../data/models/collaborator_model.dart';
import '../../data/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';

class CollaboratorsPanel extends StatefulWidget {
  final EventModel event;
  const CollaboratorsPanel({super.key, required this.event});

  @override
  State<CollaboratorsPanel> createState() => _CollaboratorsPanelState();
}

class _CollaboratorsPanelState extends State<CollaboratorsPanel> {
  final _service = FirestoreService();
  bool _codeLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final userId = context.read<AuthProvider>().currentUser?.uid ?? '';
    final isOwner = widget.event.organizerId == userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipo del Evento'),
        actions: [
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.person_add_rounded),
              tooltip: 'Invitar por correo',
              onPressed: () => _showInviteByEmailDialog(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── SHARE SECTION ────────────────────────────────────
            if (isOwner) ...[
              _SectionTitle('Compartir Evento'),
              const SizedBox(height: 12),
              _ShareCard(
                event: widget.event,
                onGenerateCode: () => _generateCode(context),
                isLoading: _codeLoading,
              ),
              const SizedBox(height: 28),
            ],

            // ── PENDING REQUESTS ─────────────────────────────────
            if (isOwner) ...[
              _SectionTitle('Solicitudes Pendientes'),
              const SizedBox(height: 12),
              StreamBuilder<List<CollaboratorModel>>(
                stream: _service.watchPendingRequests(widget.event.id),
                builder: (context, snap) {
                  final pending = snap.data ?? [];
                  if (pending.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('No hay solicitudes pendientes',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    );
                  }
                  return Column(
                    children: pending.map((c) => _PendingRequestCard(
                      collaborator: c,
                      eventId: widget.event.id,
                    )).toList(),
                  );
                },
              ),
              const SizedBox(height: 28),
            ],

            // ── TEAM MEMBERS ─────────────────────────────────────
            _SectionTitle('Miembros del Equipo'),
            const SizedBox(height: 12),
            _OwnerCard(
              displayName: 'Propietario',
              email: context.read<AuthProvider>().currentUser?.email ?? '',
            ),
            const SizedBox(height: 8),
            StreamBuilder<List<CollaboratorModel>>(
              stream: _service.watchCollaborators(widget.event.id),
              builder: (context, snap) {
                final all = (snap.data ?? [])
                    .where((c) => c.isApproved)
                    .toList();
                if (all.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('Aún no hay colaboradores',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return Column(
                  children: all.map((c) => _CollaboratorCard(
                    collaborator: c,
                    eventId: widget.event.id,
                    isOwner: isOwner,
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateCode(BuildContext context) async {
    setState(() => _codeLoading = true);
    try {
      await _service.generateInviteCode(widget.event.id);
    } finally {
      if (mounted) setState(() => _codeLoading = false);
    }
  }

  void _showInviteByEmailDialog(BuildContext context) {
    final emailController = TextEditingController();
    CollaboratorRole selectedRole = CollaboratorRole.viewer;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Invitar Colaborador',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    hintText: 'ejemplo@correo.com',
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Rol a asignar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleOption(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Administrador',
                        description: 'Puede editar todo',
                        selected: selectedRole == CollaboratorRole.admin,
                        onTap: () => setDialogState(() => selectedRole = CollaboratorRole.admin),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleOption(
                        icon: Icons.visibility_rounded,
                        label: 'Visualizador',
                        description: 'Solo lectura',
                        selected: selectedRole == CollaboratorRole.viewer,
                        onTap: () => setDialogState(() => selectedRole = CollaboratorRole.viewer),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.trim().isEmpty) return;
                final userName = context.read<AuthProvider>().currentUser?.displayName ?? 'Admin';
                await _service.inviteByEmail(
                  eventId: widget.event.id,
                  email: emailController.text.trim(),
                  role: selectedRole,
                  inviterName: userName,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invitación enviada'),
                        backgroundColor: AppColors.confirmed),
                  );
                }
              },
              child: const Text('Enviar Invitación'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SHARE CARD ─────────────────────────────────────────────────
class _ShareCard extends StatelessWidget {
  final EventModel event;
  final VoidCallback onGenerateCode;
  final bool isLoading;
  const _ShareCard({required this.event, required this.onGenerateCode, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCode = event.inviteCode != null && event.inviteCode!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          if (!hasCode) ...[
            const Icon(Icons.link_rounded, size: 40, color: AppColors.brushedGold),
            const SizedBox(height: 12),
            const Text('Genera un código de invitación para compartir este evento con tu equipo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onGenerateCode,
              icon: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.vpn_key_rounded),
              label: const Text('Generar Código'),
            ),
          ] else ...[
            Row(
              children: [
                const Icon(Icons.vpn_key_rounded, color: AppColors.brushedGold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Código de Invitación', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(event.inviteCode!,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900,
                              letterSpacing: 3, color: AppColors.brushedGold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded),
                  tooltip: 'Copiar código',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: event.inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ShareAction(
                  icon: Icons.copy_rounded,
                  label: 'Copiar',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: event.inviteCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                _ShareAction(
                  icon: Icons.link_rounded,
                  label: 'Link',
                  onTap: () {
                    final link = 'https://planea.app/join?code=${event.inviteCode}';
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Enlace copiado'), duration: Duration(seconds: 1)),
                    );
                  },
                ),
                _ShareAction(
                  icon: Icons.qr_code_2_rounded,
                  label: 'QR',
                  onTap: () => _showQRDialog(context, event.inviteCode!),
                ),
                _ShareAction(
                  icon: Icons.refresh_rounded,
                  label: 'Regenerar',
                  onTap: () async {
                    await FirestoreService().generateInviteCode(event.id);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showQRDialog(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Código QR', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2_rounded, size: 160, color: Colors.black87),
                      const SizedBox(height: 12),
                      Text(code, style: const TextStyle(
                          color: Colors.black87, fontWeight: FontWeight.w900,
                          fontSize: 18, letterSpacing: 2)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Escanea este código con la app Planea para unirte al evento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }
}

class _ShareAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ShareAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.brushedGold, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ── PENDING REQUEST CARD ─────────────────────────────────────────
class _PendingRequestCard extends StatelessWidget {
  final CollaboratorModel collaborator;
  final String eventId;
  const _PendingRequestCard({required this.collaborator, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.pending.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.pending.withValues(alpha: 0.15),
            child: Text(
              collaborator.displayName.isNotEmpty
                  ? collaborator.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(color: AppColors.pending, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collaborator.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(collaborator.email,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: AppColors.confirmed),
            tooltip: 'Aprobar',
            onPressed: () => _showApprovalDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.cancel_rounded, color: AppColors.declined),
            tooltip: 'Rechazar',
            onPressed: () {
              FirestoreService().rejectCollaborator(eventId, collaborator.userId);
            },
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(BuildContext context) {
    CollaboratorRole selectedRole = CollaboratorRole.viewer;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: const Text('Aprobar Colaborador', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${collaborator.displayName} quiere unirse al evento.',
                  style: const TextStyle(color: Colors.grey)),
              Text(collaborator.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              const Text('Asignar rol:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleOption(
                      icon: Icons.admin_panel_settings_rounded,
                      label: 'Admin',
                      description: 'Puede editar',
                      selected: selectedRole == CollaboratorRole.admin,
                      onTap: () => setDialogState(() => selectedRole = CollaboratorRole.admin),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleOption(
                      icon: Icons.visibility_rounded,
                      label: 'Visualizador',
                      description: 'Solo lectura',
                      selected: selectedRole == CollaboratorRole.viewer,
                      onTap: () => setDialogState(() => selectedRole = CollaboratorRole.viewer),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                FirestoreService().approveCollaborator(eventId, collaborator.userId, selectedRole);
                Navigator.pop(context);
              },
              child: const Text('Aprobar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── COLLABORATOR CARD ────────────────────────────────────────────
class _CollaboratorCard extends StatelessWidget {
  final CollaboratorModel collaborator;
  final String eventId;
  final bool isOwner;
  const _CollaboratorCard({
    required this.collaborator,
    required this.eventId,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roleColor = collaborator.isAdmin ? AppColors.brushedGold : Colors.blueGrey;
    final roleLabel = collaborator.isAdmin ? 'Administrador' : 'Visualizador';
    final roleIcon = collaborator.isAdmin
        ? Icons.admin_panel_settings_rounded
        : Icons.visibility_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: roleColor.withValues(alpha: 0.15),
            child: Text(
              collaborator.displayName.isNotEmpty
                  ? collaborator.displayName[0].toUpperCase()
                  : '?',
              style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(collaborator.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                Text(collaborator.email,
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(roleIcon, size: 14, color: roleColor),
                const SizedBox(width: 4),
                Text(roleLabel, style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (isOwner) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'remove') {
                  FirestoreService().removeCollaborator(eventId, collaborator.userId);
                } else if (val == 'admin') {
                  FirestoreService().updateCollaboratorRole(eventId, collaborator.userId, CollaboratorRole.admin);
                } else if (val == 'viewer') {
                  FirestoreService().updateCollaboratorRole(eventId, collaborator.userId, CollaboratorRole.viewer);
                }
              },
              itemBuilder: (_) => [
                if (!collaborator.isAdmin)
                  const PopupMenuItem(value: 'admin', child: Text('Cambiar a Administrador')),
                if (collaborator.isAdmin)
                  const PopupMenuItem(value: 'viewer', child: Text('Cambiar a Visualizador')),
                const PopupMenuItem(value: 'remove',
                    child: Text('Eliminar', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── OWNER CARD ───────────────────────────────────────────────────
class _OwnerCard extends StatelessWidget {
  final String displayName;
  final String email;
  const _OwnerCard({required this.displayName, required this.email});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.brushedGold.withValues(alpha: 0.15),
            child: const Icon(Icons.star_rounded, color: AppColors.brushedGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                Text(email, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brushedGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shield_rounded, size: 14, color: AppColors.brushedGold),
                SizedBox(width: 4),
                Text('Propietario',
                    style: TextStyle(color: AppColors.brushedGold, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── ROLE OPTION ──────────────────────────────────────────────────
class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  const _RoleOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brushedGold : Colors.grey;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.brushedGold.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            Text(description, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ── SECTION TITLE ────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
  }
}
