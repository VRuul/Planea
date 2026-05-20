import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/models/event_model.dart';
import '../../data/services/supabase_service.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/event_provider.dart';

class EventMenuScreen extends StatefulWidget {
  final String? eventId;
  const EventMenuScreen({super.key, this.eventId});

  @override
  State<EventMenuScreen> createState() => _EventMenuScreenState();
}

class _EventMenuScreenState extends State<EventMenuScreen> {
  final _service = SupabaseService();
  List<MenuModel>? _localMenus;
  EventModel? _lastEvent;
  void _addOrEditMenu({MenuModel? menuToEdit, int? editIndex}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MenuEditorDialog(
        menu: menuToEdit,
        onSave: (savedMenu) async {
          if (_lastEvent == null) return;
          final updatedMenus = List<MenuModel>.from(_localMenus ?? _lastEvent!.menus);
          if (editIndex != null) {
            updatedMenus[editIndex] = savedMenu;
          } else {
            updatedMenus.add(savedMenu);
          }

          final messenger = ScaffoldMessenger.of(context);
          try {
            await _service.updateEvent(_lastEvent!.copyWith(menus: updatedMenus));
            setState(() {
              _localMenus = updatedMenus;
            });
            messenger.showSnackBar(
              const SnackBar(
                backgroundColor: AppColors.confirmed,
                behavior: SnackBarBehavior.floating,
                content: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 12),
                    Text("Menú guardado correctamente", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                content: Text("Error al guardar: $e"),
              ),
            );
            rethrow;
          }
        },
      ),
    );
  }

  void _deleteMenu(int index) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text("Eliminar Menú", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("¿Estás seguro de que deseas eliminar este menú? Los invitados asignados a él quedarán sin selección.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              if (_lastEvent == null || _localMenus == null) return;
              final updatedMenus = List<MenuModel>.from(_localMenus!);
              updatedMenus.removeAt(index);

              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(dialogContext);

              try {
                await _service.updateEvent(_lastEvent!.copyWith(menus: updatedMenus));
                setState(() {
                  _localMenus = updatedMenus;
                });
                messenger.showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.confirmed,
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white),
                        SizedBox(width: 12),
                        Text("Menú eliminado correctamente", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    content: Text("Error al eliminar: $e"),
                  ),
                );
              }
            },
            child: const Text("ELIMINAR", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    final eventProvider = context.watch<EventProvider>();
    final effectiveEventId = widget.eventId ?? eventProvider.currentEventId;

    if (effectiveEventId == null) {
      return Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(
          title: const Text("Menús de Catering", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: Navigator.canPop(context)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                )
              : null,
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: baseColor.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.2)),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 48,
                  color: AppColors.brushedGold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Selecciona un evento primero",
                style: TextStyle(
                  color: AppColors.brushedGold,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Usa el selector en el panel lateral para elegir un evento activo.",
                style: TextStyle(
                  color: baseColor.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        title: const Text("Menús de Catering", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditMenu(),
        backgroundColor: AppColors.brushedGold,
        foregroundColor: AppColors.charcoal,
        icon: const Icon(Icons.restaurant_menu_rounded),
        label: const Text("Agregar Menú", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<EventModel?>(
        stream: _service.watchEvent(effectiveEventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brushedGold));
          }
          final event = snapshot.data;
          if (event == null) {
            return const Center(child: Text("Evento no encontrado", style: TextStyle(color: Colors.white70)));
          }

          if (_localMenus == null || _lastEvent?.id != event.id) {
            _localMenus = List.from(event.menus);
            _lastEvent = event;
          }

          if (_localMenus!.isEmpty) {
            return _buildEmptyState(baseColor);
          }

          return ListView.separated(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
            itemCount: _localMenus!.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final menu = _localMenus![i];
              return _MenuCard(
                menu: menu,
                onEdit: () => _addOrEditMenu(menuToEdit: menu, editIndex: i),
                onDelete: () => _deleteMenu(i),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(Color baseColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: baseColor.withValues(alpha: 0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant_menu_rounded, color: AppColors.brushedGold, size: 64),
              const SizedBox(height: 20),
              const Text(
                "Sin Menús Personalizados",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.brushedGold),
              ),
              const SizedBox(height: 8),
              Text(
                "Crea menús personalizados para tu banquete (ej. Adulto Tradicional, Infantil, Vegano) para que tus invitados elijan sus platillos favoritos al confirmar asistencia.",
                textAlign: TextAlign.center,
                style: TextStyle(color: baseColor.withValues(alpha: 0.6), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _addOrEditMenu(),
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text("CREAR PRIMER MENÚ", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brushedGold,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MenuCard({
    required this.menu,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: baseColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.brushedGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    menu.icon ?? "🍽️",
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    menu.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white60, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          if (menu.courses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("Sin tiempos o platillos añadidos.", style: TextStyle(color: Colors.white30, fontSize: 12)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: menu.courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final course = menu.courses[i];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.brushedGold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${i + 1}T",
                        style: const TextStyle(color: AppColors.brushedGold, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                course.name,
                                style: const TextStyle(color: AppColors.brushedGold, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              const Text("•", style: TextStyle(color: Colors.white24)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  course.dishName,
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (course.description != null && course.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              course.description!,
                              style: const TextStyle(color: Colors.white30, fontSize: 10, height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MenuEditorDialog extends StatefulWidget {
  final MenuModel? menu;
  final Future<void> Function(MenuModel) onSave;

  const _MenuEditorDialog({this.menu, required this.onSave});

  @override
  State<_MenuEditorDialog> createState() => _MenuEditorDialogState();
}

class _MenuEditorDialogState extends State<_MenuEditorDialog> {
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final List<MenuCourseModel> _courses = [];

  final _courseNameController = TextEditingController();
  final _dishNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  final List<String> _emojiOptions = ["🥩", "🐟", "🥗", "👶", "🍰", "🍷", "🍹", "🍲", "🌮", "🍕", "🍝", "🍩"];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.menu != null) {
      _nameController.text = widget.menu!.name;
      _iconController.text = widget.menu!.icon ?? "🥩";
      _courses.addAll(widget.menu!.courses);
    } else {
      _iconController.text = "🥩";
    }
  }

  void _addCourse() {
    if (_courseNameController.text.isEmpty || _dishNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Completa el nombre del tiempo y del platillo"),
        ),
      );
      return;
    }

    setState(() {
      _courses.add(
        MenuCourseModel(
          name: _courseNameController.text.trim(),
          dishName: _dishNameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        ),
      );
      _courseNameController.clear();
      _dishNameController.clear();
      _descriptionController.clear();
    });
  }

  void _deleteCourse(int index) {
    setState(() {
      _courses.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Ingresa el nombre del menú"),
        ),
      );
      return;
    }

    final savedMenu = MenuModel(
      id: widget.menu?.id ?? "menu_${DateTime.now().millisecondsSinceEpoch}",
      name: _nameController.text.trim(),
      icon: _iconController.text.trim().isEmpty ? "🍽️" : _iconController.text.trim(),
      courses: List.from(_courses),
    );

    setState(() => _saving = true);
    try {
      await widget.onSave(savedMenu);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      // Error is handled by caller
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.charcoal,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 750),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.menu == null ? "Nuevo Menú" : "Editar Menú",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Menu Name Input
                    const Text("Nombre del Menú", style: TextStyle(color: AppColors.brushedGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "Ej. Menú Premium 3 Tiempos",
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.02),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icon/Emoji Selector
                    const Text("Icono de Menú", style: TextStyle(color: AppColors.brushedGold, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Text(_iconController.text, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _emojiOptions.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final emoji = _emojiOptions[index];
                                final isSelected = _iconController.text == emoji;
                                return InkWell(
                                  onTap: () => setState(() => _iconController.text = emoji),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.brushedGold.withValues(alpha: 0.1) : Colors.transparent,
                                      border: Border.all(color: isSelected ? AppColors.brushedGold : Colors.white10),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(emoji, style: const TextStyle(fontSize: 18)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tiempos (Catering Courses) Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("TIEMPOS / PLATILLOS", style: TextStyle(color: AppColors.brushedGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        Text("${_courses.length} añadidos", style: const TextStyle(color: Colors.white30, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Course list
                    if (_courses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.01),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                        ),
                        child: const Text(
                          "Aún no agregas tiempos a este menú. Comienza a crearlos a continuación.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white30, fontSize: 11, height: 1.4),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _courses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final course = _courses[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.brushedGold.withValues(alpha: 0.1),
                                  child: Text("${i + 1}", style: const TextStyle(color: AppColors.brushedGold, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${course.name}: ${course.dishName}",
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      if (course.description != null) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          course.description!,
                                          style: const TextStyle(color: Colors.white30, fontSize: 9),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () => _deleteCourse(i),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // Add course Form Box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.01),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text("Agregar Nuevo Tiempo", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: _courseNameController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: "Ej. Entrada",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.02),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _dishNameController,
                                  style: const TextStyle(color: Colors.white, fontSize: 13),
                                  decoration: InputDecoration(
                                    hintText: "Nombre del platillo",
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.02),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _descriptionController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: "Descripción o notas de ingredientes (opcional)",
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.02),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _addCourse,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text("AGREGAR TIEMPO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.05),
                              foregroundColor: Colors.white70,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text("CANCELAR", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brushedGold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Text("LISTO", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
