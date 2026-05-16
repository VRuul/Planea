import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/event_model.dart';
import '../../data/models/collaborator_model.dart';
import '../../data/services/supabase_service.dart';
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
  final _service = SupabaseService();
  bool _codeLoading = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EventModel?>(
      stream: _service.watchEvent(widget.event.id),
      initialData: widget.event,
      builder: (context, eventSnap) {
        final event = eventSnap.data ?? widget.event;
        return _buildBody(context, event);
      },
    );
  }

  Widget _buildBody(BuildContext context, EventModel event) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final userId = context.read<AuthProvider>().currentUser?.id ?? '';
    final isOwner = event.organizerId == userId;
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: BackButton(color: isDark ? AppColors.brushedGold : baseColor),
        title: Text('Equipo del Evento', style: TextStyle(fontWeight: FontWeight.w800, color: baseColor)),
        actions: [
          if (isOwner)
            IconButton(
              icon: Icon(Icons.person_add_rounded, color: isDark ? AppColors.brushedGold : baseColor),
              tooltip: 'Invitar por correo',
              onPressed: () => _showInviteByEmailDialog(context, event),
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
                event: event,
                onGenerateCode: () => _generateCode(context, event),
                isLoading: _codeLoading,
              ),
              const SizedBox(height: 28),
            ],

            // ── PENDING REQUESTS ─────────────────────────────────
            if (isOwner) ...[
              _SectionTitle('Solicitudes Pendientes'),
              const SizedBox(height: 12),
              StreamBuilder<List<CollaboratorModel>>(
                stream: _service.watchPendingRequests(event.id),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
                      ),
                      child: Center(
                        child: Text('Error al cargar solicitudes',
                            style: TextStyle(color: baseColor.withValues(alpha: 0.3), fontSize: 12)),
                      ),
                    );
                  }
                  final pending = snap.data ?? [];
                  if (pending.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
                      ),
                      child: Center(
                        child: Text('No hay solicitudes pendientes',
                            style: TextStyle(color: baseColor.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    );
                  }
                  return Column(
                    children: pending.map((c) => _PendingRequestCard(
                      collaborator: c,
                      eventId: event.id,
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
              stream: _service.watchCollaborators(event.id),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: baseColor.withValues(alpha: 0.05)),
                    ),
                    child: Center(
                      child: Text('Error al cargar colaboradores',
                          style: TextStyle(color: baseColor.withValues(alpha: 0.3), fontSize: 12)),
                    ),
                  );
                }
                final all = (snap.data ?? [])
                    .where((c) => c.isApproved)
                    .toList();
                if (all.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: baseColor.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: baseColor.withValues(alpha: 0.05)),
                    ),
                    child: Center(
                      child: Text('Aún no hay colaboradores',
                          style: TextStyle(color: baseColor.withValues(alpha: 0.3), fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  );
                }
                return Column(
                  children: all.map((c) => _CollaboratorCard(
                    collaborator: c,
                    eventId: event.id,
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

  Future<void> _generateCode(BuildContext context, EventModel event) async {
    setState(() => _codeLoading = true);
    try {
      await _service.generateInviteCode(event.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar código: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _codeLoading = false);
    }
  }

  void _showInviteByEmailDialog(BuildContext context, EventModel event) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;
    final emailController = TextEditingController();
    CollaboratorRole selectedRole = CollaboratorRole.viewer;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Invitar Colaborador',
              style: TextStyle(fontWeight: FontWeight.w900, color: baseColor, letterSpacing: 0.5)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  autofocus: true,
                  style: TextStyle(color: baseColor),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Correo electrónico', Icons.email_outlined, theme),
                ),
                const SizedBox(height: 20),
                Text('Rol a asignar:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: baseColor)),
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
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              style: TextButton.styleFrom(foregroundColor: baseColor.withValues(alpha: 0.5)),
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.trim().isEmpty) return;
                final auth = context.read<AuthProvider>();
                final userName = auth.userDisplayName ?? 'Admin';
                await _service.inviteByEmail(
                  eventId: event.id,
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brushedGold,
                foregroundColor: AppColors.charcoal,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enviar Invitación', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark, baseColor = isDark ? Colors.white : Colors.black;
    return InputDecoration(
      labelText: label, 
      labelStyle: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 14), 
      prefixIcon: Icon(icon, color: AppColors.brushedGold, size: 20), 
      filled: true, 
      fillColor: baseColor.withValues(alpha: 0.03), 
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), 
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))), 
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))), 
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.brushedGold, width: 1.5))
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;
    final hasCode = event.inviteCode != null && event.inviteCode!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          if (!hasCode) ...[
            const Icon(Icons.link_rounded, size: 40, color: AppColors.brushedGold),
            const SizedBox(height: 12),
            Text('Genera un código de invitación para compartir este evento con tu equipo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: baseColor.withValues(alpha: 0.4), fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: isLoading ? null : onGenerateCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brushedGold,
                foregroundColor: AppColors.charcoal,
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: isLoading
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.charcoal))
                  : const Icon(Icons.vpn_key_rounded),
              label: const Text('Generar Código', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
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
                      Text('Código de Invitación', style: TextStyle(fontSize: 11, color: baseColor.withValues(alpha: 0.4))),
                      const SizedBox(height: 4),
                      Text(event.inviteCode!,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w900,
                              letterSpacing: 4, color: AppColors.brushedGold)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: AppColors.brushedGold),
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
                    await SupabaseService().generateInviteCode(event.id);
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: theme.scaffoldBackgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text('Código QR', textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w900, color: baseColor, letterSpacing: 0.5)),
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
              Text('Escanea este código con la app Planea para unirte al evento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: baseColor.withValues(alpha: 0.4), fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.brushedGold, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, color: baseColor.withValues(alpha: 0.4))),
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.pending.withValues(alpha: 0.2)),
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
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: baseColor)),
                Text(collaborator.email,
                    style: theme.textTheme.bodySmall?.copyWith(color: baseColor.withValues(alpha: 0.4))),
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
              SupabaseService().rejectCollaborator(eventId, collaborator.userId);
            },
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(BuildContext context) {
    CollaboratorRole selectedRole = CollaboratorRole.viewer;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: theme.scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('Aprobar Colaborador', style: TextStyle(fontWeight: FontWeight.w900, color: baseColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${collaborator.displayName} quiere unirse al evento.',
                  style: TextStyle(color: baseColor.withValues(alpha: 0.7))),
              Text(collaborator.email,
                  style: TextStyle(color: baseColor.withValues(alpha: 0.4), fontSize: 12)),
              const SizedBox(height: 20),
              Text('Asignar rol:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: baseColor)),
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
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              style: TextButton.styleFrom(foregroundColor: baseColor.withValues(alpha: 0.5)),
              child: const Text('Cancelar')
            ),
            ElevatedButton(
              onPressed: () {
                SupabaseService().approveCollaborator(eventId, collaborator.userId, selectedRole);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brushedGold,
                foregroundColor: AppColors.charcoal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Aprobar', style: TextStyle(fontWeight: FontWeight.w800)),
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;
    final roleColor = collaborator.isAdmin ? AppColors.brushedGold : Colors.blueGrey;
    final roleLabel = collaborator.isAdmin ? 'Administrador' : 'Visualizador';
    final roleIcon = collaborator.isAdmin
        ? Icons.admin_panel_settings_rounded
        : Icons.visibility_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
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
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: baseColor)),
                Text(collaborator.email,
                    style: theme.textTheme.bodySmall?.copyWith(color: baseColor.withValues(alpha: 0.4))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withValues(alpha: 0.15)),
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
              icon: Icon(Icons.more_vert_rounded, color: baseColor.withValues(alpha: 0.3)),
              onSelected: (val) {
                if (val == 'remove') {
                  SupabaseService().removeCollaborator(eventId, collaborator.userId);
                } else if (val == 'admin') {
                  SupabaseService().updateCollaboratorRole(eventId, collaborator.userId, CollaboratorRole.admin);
                } else if (val == 'viewer') {
                  SupabaseService().updateCollaboratorRole(eventId, collaborator.userId, CollaboratorRole.viewer);
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
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brushedGold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.15)),
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
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white)),
                Text(email, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brushedGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.15)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black87;
    final color = selected ? AppColors.brushedGold : baseColor.withValues(alpha: 0.4);

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
            Text(description, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 10), textAlign: TextAlign.center),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(title.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w900, color: (isDark ? AppColors.brushedGold : Colors.black87).withValues(alpha: 0.5), letterSpacing: 1.5)),
    );
  }
}
