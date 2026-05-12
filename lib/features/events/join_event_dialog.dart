import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../core/constants/app_colors.dart';

class JoinEventDialog extends StatefulWidget {
  const JoinEventDialog({super.key});

  @override
  State<JoinEventDialog> createState() => _JoinEventDialogState();
}

class _JoinEventDialogState extends State<JoinEventDialog> {
  final _codeController = TextEditingController();
  final _service = FirestoreService();
  bool _loading = false;
  String? _error;
  String? _foundEventName;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _searchEvent() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() { _loading = true; _error = null; _foundEventName = null; });

    try {
      final event = await _service.findEventByInviteCode(code);
      if (event == null) {
        setState(() => _error = 'No se encontró ningún evento con este código.');
      } else {
        setState(() => _foundEventName = event.name);
      }
    } catch (e) {
      setState(() => _error = 'Error al buscar: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _requestJoin() async {
    final code = _codeController.text.trim().toUpperCase();
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final event = await _service.findEventByInviteCode(code);
      if (event == null) {
        setState(() => _error = 'Evento no encontrado.');
        return;
      }

      await _service.requestJoinEvent(
        eventId: event.id,
        userId: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? user.email ?? 'Usuario',
        photoUrl: user.photoURL,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud enviada. El propietario revisará tu solicitud.'),
            backgroundColor: AppColors.confirmed,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Unirse a un Evento',
          style: TextStyle(fontWeight: FontWeight.w800)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_add_rounded, size: 48, color: AppColors.brushedGold),
            const SizedBox(height: 16),
            const Text(
              'Ingresa el código de invitación que te compartieron para solicitar acceso al evento.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 3),
              decoration: InputDecoration(
                hintText: 'PLA-XXXXXX',
                hintStyle: TextStyle(
                    color: Colors.grey.shade600, letterSpacing: 3, fontSize: 20),
                prefixIcon: const Icon(Icons.vpn_key_rounded),
              ),
              onChanged: (_) {
                if (_foundEventName != null || _error != null) {
                  setState(() { _foundEventName = null; _error = null; });
                }
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.declined.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.declined, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!,
                        style: const TextStyle(color: AppColors.declined, fontSize: 12))),
                  ],
                ),
              ),
            ],
            if (_foundEventName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.confirmed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.confirmed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration_rounded, color: AppColors.confirmed),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Evento encontrado:',
                              style: TextStyle(color: Colors.grey, fontSize: 11)),
                          Text(_foundEventName!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        if (_foundEventName == null)
          ElevatedButton(
            onPressed: _loading ? null : _searchEvent,
            child: _loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Buscar'),
          )
        else
          ElevatedButton.icon(
            onPressed: _loading ? null : _requestJoin,
            icon: _loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, size: 18),
            label: const Text('Solicitar Acceso'),
          ),
      ],
    );
  }
}
