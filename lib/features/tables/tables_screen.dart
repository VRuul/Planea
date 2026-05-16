import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planea/data/models/event_model.dart';
import 'package:planea/data/models/guest_model.dart';
import 'package:planea/data/models/table_model.dart';
import 'package:planea/data/models/venue_element_model.dart';
import 'package:planea/data/models/seating_assignment_model.dart';
import 'package:planea/data/models/seating_data_model.dart';
import 'package:planea/data/services/supabase_service.dart';
import 'package:planea/providers/event_provider.dart';
import 'package:planea/l10n/app_localizations.dart';
import 'package:planea/core/constants/app_colors.dart';
import '../shared/widgets/premium_picker.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _service = SupabaseService();
  bool _isLayoutMode = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventProvider = context.watch<EventProvider>();
    final eventId = eventProvider.currentEventId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    if (eventId == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.charcoal : Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(l.tablesTitle, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        ),
        body: Center(child: Text('Selecciona un evento primero', style: TextStyle(color: isDark ? Colors.white60 : Colors.black45))),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          l.tablesTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ModeButton(
                  icon: Icons.list_rounded,
                  label: "Lista",
                  isSelected: !_isLayoutMode,
                  onTap: () => setState(() => _isLayoutMode = false),
                ),
                _ModeButton(
                  icon: Icons.map_rounded,
                  label: "Plano",
                  isSelected: _isLayoutMode,
                  onTap: () => setState(() => _isLayoutMode = true),
                ),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<SeatingData>(
        stream: _service.watchSeatingData(eventId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: AppColors.brushedGold));

          final data = snapshot.data!;
          if (_isLayoutMode) {
            return _LayoutCanvas(
              eventId: eventId,
              tables: data.tables,
              venueElements: data.venueElements,
              service: _service,
            );
          }

          return Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.brushedGold,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: AppColors.brushedGold,
                unselectedLabelColor: isDark ? Colors.white38 : Colors.black38,
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2, fontSize: 13),
                tabs: const [Tab(text: "MESAS"), Tab(text: "ASIGNAR")],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TablesList(eventId: eventId, tables: data.tables, service: _service),
                    _AssignmentView(
                      eventId: eventId,
                      tables: data.tables,
                      guests: data.guests,
                      assignments: data.assignments,
                      service: _service,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _isLayoutMode ? null : FloatingActionButton.extended(
        onPressed: () => _showTableDialog(context, eventId),
        backgroundColor: AppColors.brushedGold,
        foregroundColor: AppColors.charcoal,
        elevation: 8,
        icon: const Icon(Icons.add_rounded),
        label: Text(l.addTable, style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  void _showTableDialog(BuildContext context, String eventId, {TableModel? table, bool showDimensions = false}) {
    showDialog(
      context: context,
      builder: (context) => _TableDialog(eventId: eventId, table: table, showDimensions: showDimensions),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brushedGold : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.brushedGold.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4)
            )
          ] : [],
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isSelected ? AppColors.charcoal : (isDark ? Colors.white54 : Colors.black45)
            ),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? AppColors.charcoal : (isDark ? Colors.white54 : Colors.black45),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablesList extends StatelessWidget {
  final String eventId;
  final List<TableModel> tables;
  final SupabaseService service;

  const _TablesList({required this.eventId, required this.tables, required this.service});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    if (tables.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.table_restaurant_outlined, size: 64, color: baseColor.withValues(alpha: 0.1)),
            const SizedBox(height: 16),
            Text('No hay mesas creadas', style: TextStyle(color: baseColor.withValues(alpha: 0.3), fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: baseColor.withValues(alpha: 0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: AppColors.brushedGold.withValues(alpha: 0.1), 
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.table_restaurant_rounded, color: AppColors.brushedGold, size: 22),
            ),
            title: Text(table.name, style: TextStyle(color: baseColor, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.3)),
            subtitle: Text('Capacidad: ${table.capacity} personas', style: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 13)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionButton(
                  icon: Icons.edit_rounded,
                  onTap: () => showDialog(context: context, builder: (context) => _TableDialog(eventId: eventId, table: table)),
                ),
                const SizedBox(width: 8),
                _ActionButton(
                  icon: Icons.delete_outline_rounded,
                  isDelete: true,
                  onTap: () => service.deleteTable(eventId, table.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LayoutCanvas extends StatefulWidget {
  final String eventId;
  final List<TableModel> tables;
  final List<VenueElementModel> venueElements;
  final SupabaseService service;

  const _LayoutCanvas({required this.eventId, required this.tables, required this.venueElements, required this.service});

  @override
  State<_LayoutCanvas> createState() => _LayoutCanvasState();
}

class _LayoutCanvasState extends State<_LayoutCanvas> {
  final TransformationController _transformController = TransformationController();
  final Map<String, Offset> _dragPositions = {};
  bool _isDragging = false;
  static const double _canvasSize = 10000.0;
  static const double _canvasOrigin = 5000.0;

  void _centerView(BoxConstraints constraints) {
    if (widget.tables.isEmpty && widget.venueElements.isEmpty) {
      final initialX = constraints.maxWidth / 2 - _canvasOrigin;
      final initialY = constraints.maxHeight / 2 - _canvasOrigin;
      _transformController.value = Matrix4.identity()..setTranslationRaw(initialX, initialY, 0.0);
      return;
    }

    double minX = double.infinity, minY = double.infinity, maxX = -double.infinity, maxY = -double.infinity;
    for (var t in widget.tables) {
      final pos = _dragPositions[t.id] ?? Offset(t.posX, t.posY);
      final baseSize = 100.0 + (t.capacity * 5.0);
      final w = t.width ?? (t.shape == TableShape.rectangular ? baseSize * 2 : baseSize);
      final h = t.height ?? baseSize;
      minX = math.min(minX, pos.dx); minY = math.min(minY, pos.dy);
      maxX = math.max(maxX, pos.dx + w); maxY = math.max(maxY, pos.dy + h);
    }
    for (var e in widget.venueElements) {
      final pos = _dragPositions[e.id] ?? Offset(e.posX, e.posY);
      minX = math.min(minX, pos.dx); minY = math.min(minY, pos.dy);
      maxX = math.max(maxX, pos.dx + e.width); maxY = math.max(maxY, pos.dy + e.height);
    }

    final centerX = (minX + maxX) / 2 + _canvasOrigin;
    final centerY = (minY + maxY) / 2 + _canvasOrigin;
    _transformController.value = Matrix4.identity()..setTranslationRaw(constraints.maxWidth / 2 - centerX, constraints.maxHeight / 2 - centerY, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return LayoutBuilder(builder: (context, constraints) {
      if (_transformController.value.isIdentity()) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _centerView(constraints));
      }
      return Stack(
        children: [
          Container(
            color: theme.scaffoldBackgroundColor,
            child: InteractiveViewer(
              transformationController: _transformController,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              minScale: 0.05, maxScale: 2.0, constrained: false,
              panEnabled: !_isDragging, scaleEnabled: !_isDragging,
              child: SizedBox(
                width: _canvasSize, height: _canvasSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _GridPainter())),
                    ...widget.venueElements.map((e) {
                      final currentPos = _dragPositions[e.id] ?? Offset(e.posX, e.posY);
                      return Positioned(
                        left: currentPos.dx + _canvasOrigin, top: currentPos.dy + _canvasOrigin,
                        child: _VenueElementItem(
                          element: e,
                          onDragUpdate: (delta) {
                            final scale = _transformController.value.getMaxScaleOnAxis();
                            setState(() {
                              _isDragging = true;
                              _dragPositions[e.id] = Offset(currentPos.dx + delta.dx / scale, currentPos.dy + delta.dy / scale);
                            });
                          },
                          onDragEnd: () {
                            setState(() => _isDragging = false);
                            final pos = _dragPositions[e.id]!;
                            widget.service.updateVenueElementPosition(widget.eventId, e.id, pos.dx, pos.dy);
                          },
                          onEdit: () => _showVenueElementDialog(context, widget.eventId, e),
                        ),
                      );
                    }),
                    ...widget.tables.map((t) {
                      final currentPos = _dragPositions[t.id] ?? Offset(t.posX, t.posY);
                      return Positioned(
                        left: currentPos.dx + _canvasOrigin, top: currentPos.dy + _canvasOrigin,
                        child: _DraggableTable(
                          table: t,
                          onDragUpdate: (delta) {
                            final scale = _transformController.value.getMaxScaleOnAxis();
                            setState(() {
                              _isDragging = true;
                              _dragPositions[t.id] = Offset(currentPos.dx + delta.dx / scale, currentPos.dy + delta.dy / scale);
                            });
                          },
                          onDragEnd: () {
                            setState(() => _isDragging = false);
                            final pos = _dragPositions[t.id]!;
                            widget.service.updateTablePosition(widget.eventId, t.id, pos.dx, pos.dy);
                          },
                          onEdit: () => _showTableDialog(context, widget.eventId, table: t, showDimensions: true),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24, bottom: 24,
            child: FloatingActionButton.extended(
              heroTag: 'center_fab',
              onPressed: () => _centerView(constraints),
              icon: const Icon(Icons.center_focus_strong_rounded, size: 20),
              label: const Text('CENTRAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
              backgroundColor: isDark ? AppColors.charcoal : Colors.white,
              foregroundColor: AppColors.brushedGold,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.brushedGold.withValues(alpha: 0.2)),
              ),
            ),
          ),
          Positioned(
            right: 24, bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'element_fab',
                  onPressed: () => _showVenueElementDialog(context, widget.eventId),
                  icon: const Icon(Icons.add_box_rounded, size: 20),
                  label: const Text('ELEMENTO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
                  backgroundColor: isDark ? AppColors.charcoal : Colors.white,
                  foregroundColor: AppColors.brushedGold,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppColors.brushedGold.withValues(alpha: 0.2)),
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'table_fab',
                  onPressed: () => _showTableDialog(context, widget.eventId, showDimensions: true),
                  icon: const Icon(Icons.table_restaurant_rounded, size: 20),
                  label: const Text('AGREGAR MESA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
                  backgroundColor: AppColors.brushedGold,
                  foregroundColor: AppColors.charcoal,
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _showVenueElementDialog(BuildContext context, String eventId, [VenueElementModel? element]) {
    showDialog(context: context, builder: (context) => _VenueElementDialog(eventId: eventId, element: element));
  }

  void _showTableDialog(BuildContext context, String eventId, {TableModel? table, bool showDimensions = false}) {
    showDialog(context: context, builder: (context) => _TableDialog(eventId: eventId, table: table, showDimensions: showDimensions));
  }
}

class _DraggableTable extends StatelessWidget {
  final TableModel table;
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onEdit;

  const _DraggableTable({required this.table, required this.onDragUpdate, required this.onDragEnd, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final baseSize = 100.0 + (table.capacity * 5.0);
    final width = table.width ?? (table.shape == TableShape.rectangular ? baseSize * 2 : baseSize);
    final height = table.height ?? baseSize;

    return GestureDetector(
      onPanUpdate: (details) => onDragUpdate(details.delta),
      onPanEnd: (_) => onDragEnd(),
      onDoubleTap: onEdit,
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: AppColors.brushedGold.withValues(alpha: 0.08),
          shape: table.shape == TableShape.circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: table.shape == TableShape.circular ? null : BorderRadius.circular(table.shape == TableShape.square ? 12 : 8),
          border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                table.name, 
                style: const TextStyle(color: AppColors.brushedGold, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: -0.2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.brushedGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${table.capacity}', 
                  style: const TextStyle(color: AppColors.brushedGold, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentView extends StatelessWidget {
  final String eventId;
  final List<TableModel> tables;
  final List<GuestModel> guests;
  final List<SeatingAssignment> assignments;
  final SupabaseService service;

  const _AssignmentView({required this.eventId, required this.tables, required this.guests, required this.assignments, required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white : Colors.black;

    final unassignedGuests = guests.where((g) {
      final guestAssignments = assignments.where((a) => a.guestId == g.id);
      final totalAssigned = guestAssignments.fold(0, (sum, a) => sum + a.total);
      final totalSeats = g.adults + g.children + g.teenagers + g.disabled;
      return totalAssigned < totalSeats;
    }).toList();
    final totalSeats = tables.fold(0, (sum, t) => sum + t.capacity);
    final occupiedSeats = assignments.fold(0, (sum, a) => sum + a.total);
    final occupancyPercent = totalSeats > 0 ? (occupiedSeats / totalSeats) : 0.0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
            border: Border(bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 56, 
                    height: 56, 
                    child: CircularProgressIndicator(
                      value: occupancyPercent, 
                      strokeWidth: 4, 
                      backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05), 
                      valueColor: const AlwaysStoppedAnimation(AppColors.brushedGold),
                    ),
                  ),
                  Text(
                    '${(occupancyPercent * 100).toInt()}%', 
                    style: TextStyle(color: AppColors.brushedGold, fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ESTADO DE ASIGNACIÓN', 
                      style: TextStyle(
                        color: AppColors.brushedGold, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 10, 
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${unassignedGuests.length} grupos sin mesa', 
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              if (unassignedGuests.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _autoAssign(context),
                  icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                  label: const Text('AUTO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brushedGold,
                    foregroundColor: AppColors.charcoal,
                    elevation: 8,
                    shadowColor: AppColors.brushedGold.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              final tableAssignments = assignments.where((a) => a.tableId == table.id).toList();
              final currentOccupancy = tableAssignments.fold(0, (sum, a) => sum + a.total);
              final isFull = currentOccupancy >= table.capacity;

              return Container(
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isFull 
                        ? Colors.redAccent.withValues(alpha: 0.3) 
                        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              table.name.toUpperCase(), 
                              style: TextStyle(
                                color: isFull ? Colors.redAccent : AppColors.brushedGold, 
                                fontWeight: FontWeight.w900, 
                                fontSize: 11,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isFull 
                                  ? Colors.redAccent.withValues(alpha: 0.1) 
                                  : AppColors.brushedGold.withValues(alpha: 0.1), 
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFull ? Icons.block_flipped : Icons.person_add_alt_1_rounded, 
                              size: 14, 
                              color: isFull ? Colors.redAccent : AppColors.brushedGold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: tableAssignments.isEmpty
                        ? Center(
                            child: Text(
                              'VACÍA', 
                              style: TextStyle(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.15), 
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: tableAssignments.length,
                            itemBuilder: (context, i) {
                              final a = tableAssignments[i];
                              final guest = guests.firstWhere((g) => g.id == a.guestId);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03), 
                                  borderRadius: BorderRadius.circular(12), 
                                  border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        guest.displayName, 
                                        style: TextStyle(
                                          color: (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.7), 
                                          fontSize: 11, 
                                          fontWeight: FontWeight.w700,
                                        ), 
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      '${a.total}', 
                                      style: const TextStyle(
                                        color: AppColors.brushedGold, 
                                        fontWeight: FontWeight.w900, 
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    InkWell(
                                      onTap: () async {
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Eliminar Asignación'),
                                            content: Text('¿Deseas quitar a ${guest.displayName} de esta mesa?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                                              TextButton(
                                                onPressed: () => Navigator.pop(context, true), 
                                                style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );
                                        if (confirm == true) {
                                          await service.deleteAssignment(eventId, a.id);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.redAccent.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close_rounded, size: 12, color: Colors.redAccent),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    ),
                    InkWell(
                      onTap: isFull ? null : () => _showAssignDialog(context, table),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      child: Container(
                        width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isFull ? Colors.transparent : AppColors.brushedGold.withValues(alpha: 0.05), 
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                        child: Center(
                          child: Text(
                            isFull ? 'CAPACIDAD MÁXIMA' : 'ASIGNAR INVITADOS', 
                            style: TextStyle(
                              color: isFull ? Colors.redAccent.withValues(alpha: 0.3) : AppColors.brushedGold, 
                              fontWeight: FontWeight.w900, 
                              fontSize: 10, 
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAssignDialog(BuildContext context, TableModel table) {
    showDialog(context: context, builder: (context) => _AssignGuestDialog(eventId: eventId, table: table, allGuests: guests, allTables: tables, allAssignments: assignments, service: service));
  }

  Future<void> _autoAssign(BuildContext context) async {
    final unassigned = guests.where((g) {
      final guestAssignments = assignments.where((a) => a.guestId == g.id);
      final totalAssigned = guestAssignments.fold(0, (sum, a) => sum + a.total);
      final totalSeats = g.adults + g.children + g.teenagers + g.disabled;
      return totalAssigned < totalSeats;
    }).toList();

    if (unassigned.isEmpty) return;

    for (var g in unassigned) {
      final totalSeats = g.adults + g.children + g.teenagers + g.disabled;
      final guestAssignments = assignments.where((a) => a.guestId == g.id);
      final totalAssigned = guestAssignments.fold(0, (sum, a) => sum + a.total);
      int remainingToAssign = totalSeats - totalAssigned;

      for (var t in tables) {
        if (remainingToAssign <= 0) break;
        
        final tableAssignments = assignments.where((a) => a.tableId == t.id);
        final currentOccupancy = tableAssignments.fold(0, (sum, a) => sum + a.total);
        final available = t.capacity - currentOccupancy;

        if (available > 0) {
          final toAssign = math.min(remainingToAssign, available);
          
          final Map<String, int> counts = {};
          int tempToAssign = toAssign;
          
          // Heuristic: try to assign adults first
          final List<String> types = ['adults', 'children', 'teenagers', 'disabled'];
          for (var type in types) {
            if (tempToAssign <= 0) break;
            int totalOfType = 0;
            if (type == 'adults') totalOfType = g.adults;
            else if (type == 'children') totalOfType = g.children;
            else if (type == 'teenagers') totalOfType = g.teenagers;
            else if (type == 'disabled') totalOfType = g.disabled;

            final alreadyAssignedOfType = assignments.where((a) => a.guestId == g.id).fold(0, (sum, a) => sum + (a.counts[type] ?? 0));
            final remainingOfType = totalOfType - alreadyAssignedOfType;

            if (remainingOfType > 0) {
              final take = math.min(tempToAssign, remainingOfType);
              counts[type] = take;
              tempToAssign -= take;
            }
          }

          if (counts.isNotEmpty) {
            await service.addAssignment(eventId, SeatingAssignment(
              id: '',
              eventId: eventId,
              guestId: g.id,
              tableId: t.id,
              counts: counts,
            ));
            remainingToAssign -= toAssign;
          }
        }
      }
    }
  }
}

class _TableDialog extends StatefulWidget {
  final String eventId;
  final TableModel? table;
  final bool showDimensions;
  const _TableDialog({required this.eventId, this.table, this.showDimensions = false});
  @override
  State<_TableDialog> createState() => _TableDialogState();
}

class _TableDialogState extends State<_TableDialog> {
  final SupabaseService _service = SupabaseService();
  late TextEditingController _nameController, _capacityController, _widthController, _heightController;
  late TableShape _shape;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialCapacity = widget.table?.capacity ?? 10;
    String? initialWidth = widget.table?.width?.toString();
    String? initialHeight = widget.table?.height?.toString();
    if (widget.showDimensions && widget.table == null) {
      final baseSize = 100.0 + (initialCapacity * 5.0);
      initialWidth = baseSize.toString(); initialHeight = baseSize.toString();
    }
    _nameController = TextEditingController(text: widget.table?.name ?? '');
    _capacityController = TextEditingController(text: initialCapacity.toString());
    _widthController = TextEditingController(text: initialWidth ?? '');
    _heightController = TextEditingController(text: initialHeight ?? '');
    _shape = widget.table?.shape ?? TableShape.circular;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          Icon(
            widget.table == null ? Icons.add_circle_outline_rounded : Icons.edit_rounded, 
            color: AppColors.brushedGold, 
            size: 28,
          ), 
          const SizedBox(width: 12), 
          Text(
            widget.table == null ? 'Crear Mesa' : 'Editar Mesa', 
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
        ],
      ),
      content: SizedBox(
        width: 450, 
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              const SizedBox(height: 24),
              TextField(
                controller: _nameController, 
                style: TextStyle(color: isDark ? Colors.white : Colors.black87), 
                decoration: _inputDecoration(l.tableName, Icons.badge_outlined, theme),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _capacityController, 
                keyboardType: TextInputType.number, 
                style: TextStyle(color: isDark ? Colors.white : Colors.black87), 
                decoration: _inputDecoration(l.tableCapacity, Icons.groups_rounded, theme),
              ),
              const SizedBox(height: 16),
              PremiumPicker<TableShape>(
                label: l.tableShape,
                icon: Icons.shape_line_rounded,
                value: _shape,
                items: [
                  PremiumPickerItem(value: TableShape.circular, label: l.shapeCircular, icon: Icons.circle_outlined),
                  PremiumPickerItem(value: TableShape.square, label: l.shapeSquare, icon: Icons.crop_square_rounded),
                  PremiumPickerItem(value: TableShape.rectangular, label: l.shapeRectangular, icon: Icons.rectangle_outlined),
                ],
                onChanged: (val) { if (val != null) setState(() => _shape = val); },
              ),
              if (widget.showDimensions) ...[
                const SizedBox(height: 16), 
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _widthController, 
                        keyboardType: TextInputType.number, 
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87), 
                        decoration: _inputDecoration('Ancho (px)', Icons.width_normal_rounded, theme),
                      ),
                    ), 
                    const SizedBox(width: 16), 
                    Expanded(
                      child: TextField(
                        controller: _heightController, 
                        keyboardType: TextInputType.number, 
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87), 
                        decoration: _inputDecoration('Alto (px)', Icons.height_rounded, theme),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context), 
          style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white54 : Colors.black45), 
          child: Text(l.cancelButton),
        ), 
        const SizedBox(width: 8), 
        ElevatedButton(
          onPressed: _saving ? null : _save, 
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brushedGold, 
            foregroundColor: AppColors.charcoal, 
            elevation: 12, 
            shadowColor: AppColors.brushedGold.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ), 
          child: _saving 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.charcoal)) 
              : Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final table = TableModel(id: widget.table?.id ?? '', eventId: widget.eventId, name: name, capacity: int.tryParse(_capacityController.text.trim()) ?? 10, shape: _shape, width: double.tryParse(_widthController.text.trim()), height: double.tryParse(_heightController.text.trim()), posX: widget.table?.posX ?? 0.0, posY: widget.table?.posY ?? 0.0);
      if (widget.table == null) { await _service.addTable(widget.eventId, table); } else { await _service.updateTable(widget.eventId, table); }
      if (mounted) Navigator.pop(context);
    } finally { if (mounted) setState(() => _saving = false); }
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark, baseColor = isDark ? Colors.white : Colors.black;
    return InputDecoration(labelText: label, labelStyle: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 14), prefixIcon: Icon(icon, color: AppColors.brushedGold, size: 20), filled: true, fillColor: baseColor.withValues(alpha: 0.03), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.brushedGold, width: 1.5)));
  }
}

class _VenueElementDialog extends StatefulWidget {
  final String eventId;
  final VenueElementModel? element;
  const _VenueElementDialog({required this.eventId, this.element});
  @override
  State<_VenueElementDialog> createState() => _VenueElementDialogState();
}

class _VenueElementDialogState extends State<_VenueElementDialog> {
  final SupabaseService _service = SupabaseService();
  late TextEditingController _nameController, _widthController, _heightController;
  late VenueElementType _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.element?.name ?? '');
    _widthController = TextEditingController(text: (widget.element?.width ?? 200.0).toString());
    _heightController = TextEditingController(text: (widget.element?.height ?? 200.0).toString());
    _type = widget.element?.type ?? VenueElementType.danceFloor;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context), theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(children: [Icon(widget.element == null ? Icons.add_box_rounded : Icons.edit_note_rounded, color: AppColors.brushedGold), const SizedBox(width: 12), Text(widget.element == null ? 'Agregar Elemento' : 'Editar Elemento', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))]),
      content: SizedBox(width: 450, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(height: 16),
        PremiumPicker<VenueElementType>(
          label: 'Tipo',
          icon: Icons.category_rounded,
          value: _type,
          items: VenueElementType.values.map((type) => PremiumPickerItem(
            value: type, 
            label: _getLocalizedTypeName(type, l), 
            icon: _getIconForType(type),
          )).toList(),
          onChanged: (val) { if (val != null) setState(() => _type = val); },
        ),
        const SizedBox(height: 16),
        TextField(controller: _nameController, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: _inputDecoration('Nombre', Icons.label_outline, theme)),
        const SizedBox(height: 16),
        Row(children: [Expanded(child: TextField(controller: _widthController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: _inputDecoration('Ancho', Icons.width_normal, theme))), const SizedBox(width: 16), Expanded(child: TextField(controller: _heightController, keyboardType: TextInputType.number, style: TextStyle(color: isDark ? Colors.white : Colors.black87), decoration: _inputDecoration('Alto', Icons.height, theme)))])
      ]))),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: isDark ? Colors.white54 : Colors.black45),
          child: const Text('Cancelar')
        ),
        if (widget.element != null)
          TextButton(
            onPressed: () async {
              await _service.deleteVenueElement(widget.eventId, widget.element!.id);
              if (mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Eliminar')
          ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brushedGold,
            foregroundColor: AppColors.charcoal,
            elevation: 8,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.charcoal))
              : Text('GUARDAR', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1, fontSize: 12))
        )
      ]
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final element = VenueElementModel(id: widget.element?.id ?? '', eventId: widget.eventId, name: _nameController.text.trim().isEmpty ? _type.name : _nameController.text.trim(), type: _type, width: double.tryParse(_widthController.text.trim()) ?? 200, height: double.tryParse(_heightController.text.trim()) ?? 200, posX: widget.element?.posX ?? 0.0, posY: widget.element?.posY ?? 0.0);
      if (widget.element == null) { await _service.addVenueElement(widget.eventId, element); } else { await _service.updateVenueElement(widget.eventId, element); }
      if (mounted) Navigator.pop(context);
    } finally { if (mounted) setState(() => _saving = false); }
  }

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark, baseColor = isDark ? Colors.white : Colors.black;
    return InputDecoration(labelText: label, labelStyle: TextStyle(color: baseColor.withValues(alpha: 0.5), fontSize: 14), prefixIcon: Icon(icon, color: AppColors.brushedGold, size: 20), filled: true, fillColor: baseColor.withValues(alpha: 0.03), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: baseColor.withValues(alpha: 0.08))), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.brushedGold, width: 1.5)));
  }

  String _getLocalizedTypeName(VenueElementType type, AppLocalizations l) {
    switch (type) {
      case VenueElementType.danceFloor: return l.venueElementDanceFloor;
      case VenueElementType.dj: return l.venueElementDJ;
      case VenueElementType.candyBar: return l.venueElementCandyBar;
      case VenueElementType.entrance: return l.venueElementEntrance;
      case VenueElementType.reception: return l.venueElementReception;
      case VenueElementType.bar: return l.venueElementBar;
      case VenueElementType.bathrooms: return l.venueElementBathrooms;
      case VenueElementType.kitchen: return l.venueElementKitchen;
      default: return l.venueElementOther;
    }
  }

  IconData _getIconForType(VenueElementType type) {
    switch (type) {
      case VenueElementType.danceFloor: return Icons.curtains_rounded;
      case VenueElementType.dj: return Icons.album_rounded;
      case VenueElementType.candyBar: return Icons.restaurant_rounded;
      case VenueElementType.entrance: return Icons.login_rounded;
      case VenueElementType.reception: return Icons.theater_comedy_rounded;
      case VenueElementType.bar: return Icons.local_bar_rounded;
      case VenueElementType.bathrooms: return Icons.wc_rounded;
      case VenueElementType.kitchen: return Icons.outdoor_grill_rounded;
      default: return Icons.miscellaneous_services_rounded;
    }
  }
}

class _VenueElementItem extends StatelessWidget {
  final VenueElementModel element;
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd, onEdit;
  const _VenueElementItem({required this.element, required this.onDragUpdate, required this.onDragEnd, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onPanUpdate: (details) => onDragUpdate(details.delta),
      onPanEnd: (_) => onDragEnd(),
      onDoubleTap: onEdit,
      child: Container(
        width: element.width, height: element.height,
        decoration: BoxDecoration(
          color: _getColor(isDark), 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [
                  Icon(_getIcon(), color: AppColors.brushedGold.withValues(alpha: 0.8), size: 32), 
                  const SizedBox(height: 8), 
                  Text(
                    element.name.toUpperCase(), 
                    style: const TextStyle(
                      color: AppColors.brushedGold, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ), 
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (element.type) {
      case VenueElementType.danceFloor: return Icons.curtains_rounded;
      case VenueElementType.dj: return Icons.album_rounded;
      case VenueElementType.candyBar: return Icons.cake_rounded;
      case VenueElementType.entrance: return Icons.door_front_door_rounded;
      case VenueElementType.reception: return Icons.desk_rounded;
      case VenueElementType.bar: return Icons.local_bar_rounded;
      case VenueElementType.bathrooms: return Icons.wc_rounded;
      case VenueElementType.kitchen: return Icons.restaurant_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  Color _getColor(bool isDark) {
    return AppColors.brushedGold.withValues(alpha: isDark ? 0.05 : 0.02);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.05)..strokeWidth = 1;
    for (double i = 0; i <= size.width; i += 50) { canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint); }
    for (double i = 0; i <= size.height; i += 50) { canvas.drawLine(Offset(0, i), Offset(size.width, i), paint); }
    final originPaint = Paint()..color = AppColors.brushedGold.withValues(alpha: 0.1)..strokeWidth = 2;
    canvas.drawLine(const Offset(0, 5000), const Offset(10000, 5000), originPaint);
    canvas.drawLine(const Offset(5000, 0), const Offset(5000, 10000), originPaint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AssignGuestDialog extends StatefulWidget {
  final String eventId;
  final TableModel table;
  final List<GuestModel> allGuests;
  final List<TableModel> allTables;
  final List<SeatingAssignment> allAssignments;
  final SupabaseService service;
  const _AssignGuestDialog({required this.eventId, required this.table, required this.allGuests, required this.allTables, required this.allAssignments, required this.service});
  @override
  State<_AssignGuestDialog> createState() => _AssignGuestDialogState();
}

class _AssignGuestDialogState extends State<_AssignGuestDialog> {
  GuestModel? _selectedGuest;
  final Map<String, int> _toAssign = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tableOccupancy = widget.allAssignments.where((a) => a.tableId == widget.table.id).fold(0, (sum, a) => sum + a.total);
    final remainingInTable = widget.table.capacity - tableOccupancy;

    if (_selectedGuest == null) {
      final unassigned = widget.allGuests.where((g) {
        final totalAssigned = widget.allAssignments.where((a) => a.guestId == g.id).fold(0, (sum, a) => sum + a.total);
        return totalAssigned < g.totalSeats;
      }).toList();
      return AlertDialog(
        backgroundColor: isDark ? AppColors.charcoal : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Asignar Invitado', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(width: 400, child: ListView.builder(shrinkWrap: true, itemCount: unassigned.length, itemBuilder: (context, i) {
          final g = unassigned[i];
          final totalAssigned = widget.allAssignments.where((a) => a.guestId == g.id).fold(0, (sum, a) => sum + a.total);
          final remainingForG = g.totalSeats - totalAssigned;
          final canAssignAll = remainingForG <= remainingInTable;

          return ListTile(
            title: Text(g.displayName, style: const TextStyle(fontWeight: FontWeight.bold)), 
            subtitle: Text('$remainingForG asientos pendientes'), 
            trailing: canAssignAll ? TextButton(
              onPressed: () async {
                final Map<String, int> counts = {
                  'adults': g.adults - widget.allAssignments.where((a) => a.guestId == g.id).fold(0, (sum, a) => sum + (a.counts['adults'] ?? 0)),
                  'children': g.children - widget.allAssignments.where((a) => a.guestId == g.id).fold(0, (sum, a) => sum + (a.counts['children'] ?? 0)),
                  'teenagers': g.teenagers - widget.allAssignments.where((a) => a.guestId == g.id).fold(0, (sum, a) => sum + (a.counts['teenagers'] ?? 0)),
                  'disabled': g.disabled - widget.allAssignments.where((a) => a.guestId == g.id).fold(0, (sum, a) => sum + (a.counts['disabled'] ?? 0)),
                };
                g.customCounts.forEach((key, total) {
                  counts[key] = total - widget.allAssignments.where((a) => a.guestId == g.id).fold(0, (sum, a) => sum + (a.counts[key] ?? 0));
                });
                counts.removeWhere((k, v) => v <= 0);

                await widget.service.addAssignment(widget.eventId, SeatingAssignment(
                  id: '',
                  eventId: widget.eventId,
                  guestId: g.id,
                  tableId: widget.table.id,
                  counts: counts,
                ));
                if (mounted) Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                backgroundColor: AppColors.brushedGold.withValues(alpha: 0.1),
                foregroundColor: AppColors.brushedGold,
              ),
              child: const Text('ASIGNAR TODO'),
            ) : const Icon(Icons.chevron_right_rounded),
            onTap: () => setState(() { 
              _selectedGuest = g; 
              _toAssign['adults'] = 0; 
              _toAssign['children'] = 0; 
              _toAssign['teenagers'] = 0; 
              _toAssign['disabled'] = 0; 
              g.customCounts.forEach((k, v) => _toAssign[k] = 0);
            })
          );
        })),
      );
    }
    
    final g = _selectedGuest!;
    final currentTotalToAssign = _toAssign.values.fold(0, (sum, v) => sum + v);

    final List<String> types = ['adults', 'children', 'teenagers', 'disabled'];

    return AlertDialog(
      backgroundColor: isDark ? AppColors.charcoal : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Asignar ${g.displayName}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: types.map((type) {
        int totalOfType = 0;
        if (type == 'adults') totalOfType = g.adults;
        else if (type == 'children') totalOfType = g.children;
        else if (type == 'teenagers') totalOfType = g.teenagers;
        else if (type == 'disabled') totalOfType = g.disabled;

        final assignedOfType = widget.allAssignments.where((a) => a.guestId == g.id).fold(0, (sum, a) => sum + (a.counts[type] ?? 0));
        final remainingForType = totalOfType - assignedOfType;
        
        if (totalOfType == 0) return const SizedBox.shrink();

        return Row(children: [Expanded(child: Text(type.toUpperCase())), IconButton(icon: const Icon(Icons.remove), onPressed: _toAssign[type]! > 0 ? () => setState(() => _toAssign[type] = _toAssign[type]! - 1) : null), Text('${_toAssign[type]}'), IconButton(icon: const Icon(Icons.add), onPressed: (_toAssign[type]! < remainingForType && currentTotalToAssign < remainingInTable) ? () => setState(() => _toAssign[type] = _toAssign[type]! + 1) : null)]);
      }).toList()),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), ElevatedButton(onPressed: currentTotalToAssign > 0 ? () async { await widget.service.addAssignment(widget.eventId, SeatingAssignment(id: '', eventId: widget.eventId, guestId: g.id, tableId: widget.table.id, counts: Map.from(_toAssign)..removeWhere((k,v)=>v==0))); Navigator.pop(context); } : null, child: const Text('Asignar'))],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDelete;
  const _ActionButton({required this.icon, required this.onTap, this.isDelete = false});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark, baseColor = isDark ? Colors.white : Colors.black;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: isDelete ? Colors.redAccent.withValues(alpha: 0.1) : baseColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 18, color: isDelete ? Colors.redAccent : baseColor.withValues(alpha: 0.6))));
  }
}
