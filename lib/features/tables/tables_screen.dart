import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planea/l10n/app_localizations.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/event_provider.dart';
import '../../data/models/table_model.dart';
import '../../data/models/venue_element_model.dart';
import '../../data/models/seating_data_model.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/guest_model.dart';
import '../../data/models/seating_assignment_model.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _service = FirestoreService();
  bool _isLayoutMode = false;

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
    final l = AppLocalizations.of(context);
    final eventProvider = context.watch<EventProvider>();
    final eventId = eventProvider.currentEventId;

    if (eventId == null) {
      return Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            l.tablesTitle,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text(
            'Selecciona un evento primero',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l.tablesTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
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
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brushedGold));
          }

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
                labelColor: AppColors.brushedGold,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: "Mesas"),
                  Tab(text: "Asignar"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _TablesList(
                      eventId: eventId,
                      tables: data.tables,
                      service: _service,
                    ),
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
      floatingActionButton: !_isLayoutMode ? FloatingActionButton(
        onPressed: () => _showTableDialog(context, eventId, showDimensions: false),
        backgroundColor: AppColors.brushedGold,
        child: const Icon(Icons.add, color: AppColors.charcoal),
      ) : null,
    );
  }
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brushedGold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppColors.charcoal : Colors.white70,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.charcoal : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LayoutCanvas extends StatefulWidget {
  final String eventId;
  final List<TableModel> tables;
  final List<VenueElementModel> venueElements;
  final FirestoreService service;

  const _LayoutCanvas({
    required this.eventId,
    required this.tables,
    required this.venueElements,
    required this.service,
  });

  @override
  State<_LayoutCanvas> createState() => _LayoutCanvasState();
}

class _LayoutCanvasState extends State<_LayoutCanvas> {
  final Map<String, Offset> _dragPositions = {};
  final TransformationController _transformController = TransformationController();
  bool _isDragging = false;

  static const double _canvasSize = 10000.0;
  static const double _canvasOrigin = 5000.0;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _centerView(BoxConstraints constraints) {
    if (!mounted) return;
    
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    
    bool hasElements = widget.tables.isNotEmpty || widget.venueElements.isNotEmpty;

    if (!hasElements) {
      final targetX = constraints.maxWidth / 2 - _canvasOrigin;
      final targetY = constraints.maxHeight / 2 - _canvasOrigin;
      _transformController.value = Matrix4.identity()..setTranslationRaw(targetX, targetY, 0.0);
      return;
    }

    for (var t in widget.tables) {
      final pos = _dragPositions[t.id] ?? Offset(t.posX, t.posY);
      final baseSize = 100.0 + (t.capacity * 5.0);
      final w = t.width ?? (t.shape == TableShape.rectangular ? baseSize * 2 : baseSize);
      final h = t.height ?? baseSize;
      
      if (pos.dx < minX) minX = pos.dx;
      if (pos.dy < minY) minY = pos.dy;
      if (pos.dx + w > maxX) maxX = pos.dx + w;
      if (pos.dy + h > maxY) maxY = pos.dy + h;
    }

    for (var e in widget.venueElements) {
      final pos = _dragPositions[e.id] ?? Offset(e.posX, e.posY);
      if (pos.dx < minX) minX = pos.dx;
      if (pos.dy < minY) minY = pos.dy;
      if (pos.dx + e.width > maxX) maxX = pos.dx + e.width;
      if (pos.dy + e.height > maxY) maxY = pos.dy + e.height;
    }

    final centerX = (minX + maxX) / 2 + _canvasOrigin;
    final centerY = (minY + maxY) / 2 + _canvasOrigin;
    
    final targetX = constraints.maxWidth / 2 - centerX;
    final targetY = constraints.maxHeight / 2 - centerY;
    
    _transformController.value = Matrix4.identity()..setTranslationRaw(targetX, targetY, 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_transformController.value.isIdentity()) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _centerView(constraints));
        }

        return Stack(
          children: [
            Container(
              color: const Color(0xFF1A1A1A),
              child: InteractiveViewer(
                transformationController: _transformController,
                boundaryMargin: const EdgeInsets.all(double.infinity),
                minScale: 0.05,
                maxScale: 2.0,
                constrained: false,
                panEnabled: !_isDragging,
                scaleEnabled: !_isDragging,
                child: SizedBox(
                  width: _canvasSize,
                  height: _canvasSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _GridPainter()),
                      ),
                      ...widget.venueElements.map((e) {
                        final currentPos = _dragPositions[e.id] ?? Offset(e.posX, e.posY);
                        return Positioned(
                          left: currentPos.dx + _canvasOrigin,
                          top: currentPos.dy + _canvasOrigin,
                          child: _VenueElementItem(
                            element: e,
                            onDragUpdate: (delta) {
                              if (!mounted) return;
                              final scale = _transformController.value.getMaxScaleOnAxis();
                              setState(() {
                                _isDragging = true;
                                _dragPositions[e.id] = Offset(
                                  currentPos.dx + delta.dx / scale,
                                  currentPos.dy + delta.dy / scale,
                                );
                              });
                            },
                            onDragEnd: () {
                              if (!mounted) return;
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
                          left: currentPos.dx + _canvasOrigin,
                          top: currentPos.dy + _canvasOrigin,
                          child: _DraggableTable(
                            table: t,
                            onDragUpdate: (delta) {
                              if (!mounted) return;
                              final scale = _transformController.value.getMaxScaleOnAxis();
                              setState(() {
                                _isDragging = true;
                                _dragPositions[t.id] = Offset(
                                  currentPos.dx + delta.dx / scale,
                                  currentPos.dy + delta.dy / scale,
                                );
                              });
                            },
                            onDragEnd: () {
                              if (!mounted) return;
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
              left: 24,
              bottom: 24,
              child: FloatingActionButton.extended(
                heroTag: 'center_fab',
                onPressed: () => _centerView(constraints),
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Centrar'),
                backgroundColor: AppColors.brushedGold.withValues(alpha: 0.8),
                foregroundColor: AppColors.charcoal,
              ),
            ),
            Positioned(
              right: 24,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FloatingActionButton.extended(
                    heroTag: 'element_fab',
                    onPressed: () => _showVenueElementDialog(context, widget.eventId),
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Agregar Elemento'),
                    backgroundColor: AppColors.charcoal,
                    foregroundColor: AppColors.brushedGold,
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.extended(
                    heroTag: 'table_fab',
                    onPressed: () => _showTableDialog(context, widget.eventId, showDimensions: true),
                    icon: const Icon(Icons.table_restaurant),
                    label: const Text('Agregar Mesa'),
                    backgroundColor: AppColors.brushedGold,
                    foregroundColor: AppColors.charcoal,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DraggableTable extends StatelessWidget {
  final TableModel table;
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onEdit;

  const _DraggableTable({
    required this.table,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final baseSize = 100.0 + (table.capacity * 5.0);
    final isCircular = table.shape == TableShape.circular;
    final isRectangular = table.shape == TableShape.rectangular;
    
    final width = table.width ?? (isRectangular ? baseSize * 2.0 : baseSize);
    final height = table.height ?? baseSize;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onDragUpdate(details.delta),
      onPanEnd: (_) => onDragEnd(),
      onDoubleTap: onEdit,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.charcoal.withValues(alpha: 0.9),
          shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: isCircular ? null : BorderRadius.circular(12),
          border: Border.all(color: AppColors.brushedGold, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    table.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${table.capacity}',
                    style: TextStyle(
                      color: AppColors.brushedGold.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 14, color: Colors.white24),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
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
  final FirestoreService service;

  const _TablesList({
    required this.eventId,
    required this.tables,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.table_bar_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text('No hay mesas creadas', style: TextStyle(color: Colors.white60)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showTableDialog(context, eventId, showDimensions: false),
              icon: const Icon(Icons.add),
              label: const Text('Crear primera mesa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brushedGold,
                foregroundColor: AppColors.charcoal,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return Card(
          color: Colors.white.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.brushedGold,
              child: Text(
                table.name.substring(0, 1),
                style: const TextStyle(color: AppColors.charcoal, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(table.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Capacidad: ${table.capacity}', style: const TextStyle(color: Colors.white60)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  onPressed: () => _showTableDialog(context, eventId, table: table, showDimensions: false),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _confirmDeleteTable(context, eventId, table),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteTable(BuildContext context, String eventId, TableModel table) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.charcoal,
        title: const Text('Eliminar Mesa', style: TextStyle(color: Colors.white)),
        content: Text('¿Estás seguro de eliminar la ${table.name}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
          ),
          TextButton(
            onPressed: () {
              service.deleteTable(eventId, table.id);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _AssignmentView extends StatelessWidget {
  final String eventId;
  final List<TableModel> tables;
  final List<GuestModel> guests;
  final List<SeatingAssignment> assignments;
  final FirestoreService service;

  const _AssignmentView({
    required this.eventId,
    required this.tables,
    required this.guests,
    required this.assignments,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final unassignedGuests = guests.where((g) {
      final guestAssignments = assignments.where((a) => a.guestId == g.id);
      final totalAssigned = guestAssignments.fold(0, (sum, a) => sum + a.total);
      return totalAssigned < g.totalSeats;
    }).toList();
    final totalSeats = tables.fold(0, (sum, t) => sum + t.capacity);
    final occupiedSeats = assignments.length;
    final occupancyPercent = totalSeats > 0 ? (occupiedSeats / totalSeats) : 0.0;

    return Column(
      children: [
        // Premium Header Summary
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
          ),
          child: Row(
            children: [
              _CircularProgress(
                percent: occupancyPercent,
                size: 50,
                color: AppColors.brushedGold,
                child: Center(
                  child: Text(
                    '${(occupancyPercent * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estado de Asignación',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      '${unassignedGuests.length} personas sin mesa de ${guests.length} totales',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (unassignedGuests.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => _autoAssign(context),
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('Auto', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brushedGold,
                    foregroundColor: AppColors.charcoal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
            ],
          ),
        ),

        // Grid of Tables
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 320,
              mainAxisExtent: 220,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              final tableAssignments = assignments.where((a) => a.tableId == table.id).toList();
              final count = tableAssignments.fold(0, (sum, a) => sum + a.total);
              final isFull = count >= table.capacity;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isFull 
                        ? Colors.redAccent.withValues(alpha: 0.3) 
                        : AppColors.brushedGold.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          table.name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$count / ${table.capacity}',
                          style: TextStyle(
                            color: isFull ? Colors.redAccent : Colors.white54,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: tableAssignments.map((assignment) {
                            final guest = guests.firstWhere((g) => g.id == assignment.guestId,
                                orElse: () => GuestModel(
                                    id: '',
                                    eventId: '',
                                    firstName: '?',
                                    lastName: '',
                                    displayName: '?',
                                    role: GuestRole.regular,
                                    status: GuestStatus.pending,
                                    adults: 0,
                                    children: 0,
                                    teenagers: 0,
                                    disabled: 0));
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.person, size: 10, color: Colors.white.withValues(alpha: 0.5)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${guest.displayName} (${assignment.total})',
                                      style: const TextStyle(color: Colors.white, fontSize: 11),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => service.deleteAssignment(eventId, assignment.id),
                                    child: Icon(Icons.close, size: 12, color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Center(
                      child: IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.brushedGold, size: 20),
                        onPressed: () => _showAssignGuestPicker(context, table, unassignedGuests),
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

  void _showAssignGuestPicker(BuildContext context, TableModel table, List<GuestModel> unassignedGuests) {
    showDialog(
      context: context,
      builder: (context) => _AssignGuestDialog(
        eventId: eventId,
        table: table,
        allGuests: guests,
        allTables: tables,
        allAssignments: assignments,
        service: service,
      ),
    );
  }

  Future<void> _autoAssign(BuildContext context) async {
    final pending = guests.where((g) {
      final guestAssignments = assignments.where((a) => a.guestId == g.id);
      final totalAssigned = guestAssignments.fold(0, (sum, a) => sum + a.total);
      return totalAssigned < g.totalSeats;
    }).toList();
    
    if (pending.isEmpty) return;

    final List<SeatingAssignment> newAssignments = [];

    for (var guest in pending) {
      final guestAssignments = assignments.where((a) => a.guestId == guest.id);
      final totalAssigned = guestAssignments.fold(0, (sum, a) => sum + a.total);
      int remainingToAssign = guest.totalSeats - totalAssigned;

      for (var table in tables) {
        if (remainingToAssign <= 0) break;

        // Considerar también las nuevas asignaciones que aún no están en Firestore pero sí en nuestro lote local
        final batchOccupiedInTable = newAssignments.where((a) => a.tableId == table.id).fold(0, (sum, a) => sum + a.total);
        final tableAssignments = assignments.where((a) => a.tableId == table.id);
        final occupiedInTable = tableAssignments.fold(0, (sum, a) => sum + a.total) + batchOccupiedInTable;
        final freeInTable = table.capacity - occupiedInTable;

        if (freeInTable > 0) {
          int toSit = remainingToAssign > freeInTable ? freeInTable : remainingToAssign;
          
          Map<String, int> assignedCounts = {};
          int totalSat = 0;
          
          void tryFill(String type, int totalInGuest) {
            final alreadySatType = guestAssignments.fold<int>(0, (sum, a) => sum + (a.counts[type] ?? 0)) +
                                   newAssignments.where((a) => a.guestId == guest.id).fold<int>(0, (sum, a) => sum + (a.counts[type] ?? 0));
            int stillNeeds = totalInGuest - alreadySatType;
            if (stillNeeds > 0 && totalSat < toSit) {
              int canSit = (toSit - totalSat) > stillNeeds ? stillNeeds : (toSit - totalSat);
              if (canSit > 0) {
                assignedCounts[type] = canSit;
                totalSat += canSit;
              }
            }
          }

          tryFill('Adultos', guest.adults);
          tryFill('Niños', guest.children);
          tryFill('Jóvenes', guest.teenagers);
          tryFill('Especial', guest.disabled);
          guest.customCounts.forEach((k, v) => tryFill(k, v));

          if (assignedCounts.isNotEmpty) {
            newAssignments.add(SeatingAssignment(
              id: '', 
              tableId: table.id, 
              guestId: guest.id,
              counts: assignedCounts,
            ));
            remainingToAssign -= totalSat;
          }
        }
      }
    }

    if (newAssignments.isNotEmpty) {
      await service.addAssignmentsBatch(eventId, newAssignments);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invitados asignados automáticamente'), backgroundColor: AppColors.brushedGold)
    );
  }
}

class _CircularProgress extends StatelessWidget {
  final double percent;
  final double size;
  final Color color;
  final Widget child;

  const _CircularProgress({
    required this.percent,
    required this.size,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          Positioned.fill(
            child: CircularProgressIndicator(
              value: percent,
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _TableIndicator extends StatelessWidget {
  final double percent;
  final bool isFull;

  const _TableIndicator({required this.percent, required this.isFull});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isFull ? Colors.redAccent : AppColors.brushedGold.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 14 * percent,
          height: 14 * percent,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFull ? Colors.redAccent : AppColors.brushedGold,
          ),
        ),
      ),
    );
  }
}

class _GuestPill extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;

  const _GuestPill({required this.name, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, size: 12, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 12, color: Colors.white.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }
}

void _showVenueElementDialog(BuildContext context, String eventId, [VenueElementModel? element]) {
  showDialog(
    context: context,
    builder: (context) => _VenueElementDialog(eventId: eventId, element: element),
  );
}

void _showTableDialog(BuildContext context, String eventId, {TableModel? table, bool showDimensions = false}) {
  showDialog(
    context: context,
    builder: (context) => _TableDialog(eventId: eventId, table: table, showDimensions: showDimensions),
  );
}

class _VenueElementDialog extends StatefulWidget {
  final String eventId;
  final VenueElementModel? element;

  const _VenueElementDialog({required this.eventId, this.element});

  @override
  State<_VenueElementDialog> createState() => _VenueElementDialogState();
}

class _VenueElementDialogState extends State<_VenueElementDialog> {
  final FirestoreService _service = FirestoreService();
  late TextEditingController _nameController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
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
    final l = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.charcoal,
      title: Text(widget.element == null ? 'Agregar Elemento' : 'Editar Elemento', style: const TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<VenueElementType>(
                value: _type,
                dropdownColor: AppColors.charcoal,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tipo de Elemento',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
                items: VenueElementType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getLocalizedTypeName(type, l)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _type = val);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nombre (opcional)',
                  labelStyle: TextStyle(color: Colors.white60),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Ancho',
                        labelStyle: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Alto',
                        labelStyle: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white60)),
        ),
        if (widget.element != null)
          TextButton(
            onPressed: () async {
              await _service.deleteVenueElement(widget.eventId, widget.element!.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brushedGold,
            foregroundColor: AppColors.charcoal,
          ),
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final width = double.tryParse(_widthController.text.trim()) ?? 200.0;
    final height = double.tryParse(_heightController.text.trim()) ?? 200.0;
    
    setState(() => _saving = true);
    try {
      final element = VenueElementModel(
        id: widget.element?.id ?? '',
        eventId: widget.eventId,
        name: name.isEmpty ? _type.name : name,
        type: _type,
        width: width,
        height: height,
        posX: widget.element?.posX ?? 0.0,
        posY: widget.element?.posY ?? 0.0,
      );

      if (widget.element == null) {
        await _service.addVenueElement(widget.eventId, element);
      } else {
        await _service.updateVenueElement(widget.eventId, element);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
}

class _VenueElementItem extends StatelessWidget {
  final VenueElementModel element;
  final Function(Offset) onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onEdit;

  const _VenueElementItem({
    required this.element,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onEdit,
  });

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

  Color _getColor() {
    switch (element.type) {
      case VenueElementType.danceFloor: return Colors.purple.withValues(alpha: 0.3);
      case VenueElementType.dj: return Colors.blue.withValues(alpha: 0.3);
      case VenueElementType.candyBar: return Colors.pink.withValues(alpha: 0.3);
      case VenueElementType.entrance: return Colors.green.withValues(alpha: 0.3);
      case VenueElementType.reception: return Colors.amber.withValues(alpha: 0.3);
      case VenueElementType.bar: return Colors.red.withValues(alpha: 0.3);
      case VenueElementType.bathrooms: return Colors.cyan.withValues(alpha: 0.3);
      case VenueElementType.kitchen: return Colors.orange.withValues(alpha: 0.3);
      default: return Colors.grey.withValues(alpha: 0.3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => onDragUpdate(details.delta),
      onPanEnd: (_) => onDragEnd(),
      onDoubleTap: onEdit,
      child: Container(
        width: element.width,
        height: element.height,
        decoration: BoxDecoration(
          color: _getColor(),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.5), width: 2),
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getIcon(), color: Colors.white70, size: 32),
                  const SizedBox(height: 4),
                  Text(
                    element.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 14, color: Colors.white24),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const spacing = 50.0;

    for (double i = 0; i <= size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i <= size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    final originPaint = Paint()
      ..color = AppColors.brushedGold.withValues(alpha: 0.1)
      ..strokeWidth = 2;
    
    canvas.drawLine(const Offset(0, 5000), const Offset(10000, 5000), originPaint);
    canvas.drawLine(const Offset(5000, 0), const Offset(5000, 10000), originPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TableDialog extends StatefulWidget {
  final String eventId;
  final TableModel? table;
  final bool showDimensions;

  const _TableDialog({
    required this.eventId, 
    this.table, 
    this.showDimensions = false,
  });

  @override
  State<_TableDialog> createState() => _TableDialogState();
}

class _TableDialogState extends State<_TableDialog> {
  final FirestoreService _service = FirestoreService();
  late TextEditingController _nameController;
  late TextEditingController _capacityController;
  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TableShape _shape;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialCapacity = widget.table?.capacity ?? 10;
    
    // Si estamos en modo plano y es mesa nueva, calculamos dimensiones por defecto
    String? initialWidth = widget.table?.width?.toString();
    String? initialHeight = widget.table?.height?.toString();
    
    if (widget.showDimensions && widget.table == null) {
      final baseSize = 100.0 + (initialCapacity * 5.0);
      initialWidth = baseSize.toString();
      initialHeight = baseSize.toString();
    }

    _nameController = TextEditingController(text: widget.table?.name ?? '');
    _capacityController = TextEditingController(text: initialCapacity.toString());
    _widthController = TextEditingController(text: initialWidth ?? '');
    _heightController = TextEditingController(text: initialHeight ?? '');
    _shape = widget.table?.shape ?? TableShape.circular;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: AppColors.charcoal,
      title: Text(widget.table == null ? 'Crear Mesa' : 'Editar Mesa', style: const TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l.tableName,
                labelStyle: const TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l.tableCapacity,
                labelStyle: const TextStyle(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TableShape>(
              value: _shape,
              dropdownColor: AppColors.charcoal,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: l.tableShape,
                labelStyle: const TextStyle(color: Colors.white60),
              ),
              items: [
                DropdownMenuItem(value: TableShape.circular, child: Text(l.shapeCircular)),
                DropdownMenuItem(value: TableShape.square, child: Text(l.shapeSquare)),
                DropdownMenuItem(value: TableShape.rectangular, child: Text(l.shapeRectangular)),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _shape = val);
              },
            ),
            if (widget.showDimensions) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widthController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Ancho (px)',
                        labelStyle: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Alto (px)',
                        labelStyle: TextStyle(color: Colors.white60),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancelButton, style: const TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.brushedGold,
            foregroundColor: AppColors.charcoal,
          ),
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(l.saveButton),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final capacity = int.tryParse(_capacityController.text.trim()) ?? 10;
    final width = double.tryParse(_widthController.text.trim());
    final height = double.tryParse(_heightController.text.trim());

    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final table = TableModel(
        id: widget.table?.id ?? '',
        eventId: widget.eventId,
        name: name,
        capacity: capacity,
        shape: _shape,
        width: width,
        height: height,
        posX: widget.table?.posX ?? 0.0,
        posY: widget.table?.posY ?? 0.0,
      );

      if (widget.table == null) {
        await _service.addTable(widget.eventId, table);
      } else {
        await _service.updateTable(widget.eventId, table);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AssignGuestDialog extends StatefulWidget {
  final String eventId;
  final TableModel table;
  final List<GuestModel> allGuests;
  final List<TableModel> allTables;
  final List<SeatingAssignment> allAssignments;
  final FirestoreService service;

  const _AssignGuestDialog({
    required this.eventId,
    required this.table,
    required this.allGuests,
    required this.allTables,
    required this.allAssignments,
    required this.service,
  });

  @override
  State<_AssignGuestDialog> createState() => _AssignGuestDialogState();
}

class _AssignGuestDialogState extends State<_AssignGuestDialog> {
  String _searchQuery = '';
  GuestModel? _selectedGuest;
  final Map<String, int> _toAssign = {};

  @override
  Widget build(BuildContext context) {
    final tableAssignments = widget.allAssignments.where((a) => a.tableId == widget.table.id).toList();
    final occupiedInTable = tableAssignments.fold(0, (sum, a) => sum + a.total);
    final remainingInTable = widget.table.capacity - occupiedInTable;

    if (_selectedGuest != null) {
      return _buildCountPicker(remainingInTable);
    }

    final availableGuests = widget.allGuests.where((g) {
      final guestAssignments = widget.allAssignments.where((a) => a.guestId == g.id);
      final totalAssigned = guestAssignments.fold(0, (sum, a) => sum + a.total);
      final matchesSearch = g.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      return totalAssigned < g.totalSeats && matchesSearch;
    }).toList();

    return AlertDialog(
      backgroundColor: AppColors.charcoal,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Asignar a ${widget.table.name}', style: const TextStyle(color: Colors.white, fontSize: 18)),
          Text('$occupiedInTable / ${widget.table.capacity} asientos ocupados', 
            style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Buscar invitado...',
                hintStyle: TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.search, color: Colors.white24),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: availableGuests.isEmpty
                  ? const Center(child: Text('No hay invitados pendientes', style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableGuests.length,
                      itemBuilder: (context, index) {
                        final guest = availableGuests[index];
                        final guestAssignments = widget.allAssignments.where((a) => a.guestId == guest.id);
                        final alreadyAssigned = guestAssignments.fold(0, (sum, a) => sum + a.total);
                        
                        return ListTile(
                          title: Text(guest.displayName, style: const TextStyle(color: Colors.white)),
                          subtitle: Text('Quedan ${guest.totalSeats - alreadyAssigned} boletos', 
                            style: const TextStyle(color: Colors.white60, fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.group_add, color: AppColors.brushedGold),
                                tooltip: 'Asignar todos',
                                onPressed: () async {
                                  final guestAssignments = widget.allAssignments.where((a) => a.guestId == guest.id);
                                  final alreadyAssigned = guestAssignments.fold<int>(0, (sum, a) => sum + a.total);
                                  int guestRemaining = guest.totalSeats - alreadyAssigned;
                                  
                                  if (guestRemaining <= remainingInTable) {
                                    // Cerramos el diálogo primero para evitar colisiones gráficas en web
                                    Navigator.pop(context);

                                    Map<String, int> toSit = {};
                                    void fill(String type, int totalInGuest) {
                                      final sat = guestAssignments.fold<int>(0, (sum, a) => sum + (a.counts[type] ?? 0));
                                      if (totalInGuest - sat > 0) toSit[type] = totalInGuest - sat;
                                    }

                                    fill('Adultos', guest.adults);
                                    fill('Niños', guest.children);
                                    fill('Jóvenes', guest.teenagers);
                                    fill('Especial', guest.disabled);
                                    guest.customCounts.forEach((k, v) => fill(k, v));

                                    await widget.service.addAssignment(widget.eventId, SeatingAssignment(
                                      id: '',
                                      guestId: guest.id,
                                      tableId: widget.table.id,
                                      counts: toSit,
                                    ));
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('No caben todos en esta mesa'))
                                    );
                                  }
                                },
                              ),
                              const Icon(Icons.chevron_right, color: Colors.white24),
                            ],
                          ),
                          onTap: () {
                            setState(() {
                              _selectedGuest = guest;
                              _toAssign.clear();
                              _toAssign['Adultos'] = 0;
                              if (guest.children > 0) _toAssign['Niños'] = 0;
                              if (guest.teenagers > 0) _toAssign['Jóvenes'] = 0;
                              if (guest.disabled > 0) _toAssign['Especial'] = 0;
                              for (var key in guest.customCounts.keys) {
                                _toAssign[key] = 0;
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar', style: TextStyle(color: Colors.white60)),
        ),
      ],
    );
  }

  Widget _buildCountPicker(int remainingInTable) {
    final g = _selectedGuest!;
    final guestAssignments = widget.allAssignments.where((a) => a.guestId == g.id);
    
    // Calcular cuánto se ha asignado de cada categoría en OTRAS mesas
    Map<String, int> assignedPerType = {
      'Adultos': 0, 'Niños': 0, 'Jóvenes': 0, 'Especial': 0,
    };
    for (var a in guestAssignments) {
      a.counts.forEach((key, val) {
        assignedPerType[key] = (assignedPerType[key] ?? 0) + val;
      });
    }

    int currentTotalToAssign = _toAssign.values.fold(0, (sum, v) => sum + v);

    return AlertDialog(
      backgroundColor: AppColors.charcoal,
      title: Text('¿Cuántos de ${g.displayName}?', style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: SizedBox(
        width: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _toAssign.keys.map((type) {
          int maxForType = 0;
          if (type == 'Adultos') {
            maxForType = g.adults;
          } else if (type == 'Niños') {
            maxForType = g.children;
          } else if (type == 'Jóvenes') {
            maxForType = g.teenagers;
          } else if (type == 'Especial') {
            maxForType = g.disabled;
          } else {
            maxForType = g.customCounts[type] ?? 0;
          }

          int remainingForType = maxForType - (assignedPerType[type] ?? 0);
          if (remainingForType <= 0) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(type, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      Text('$remainingForType disponibles', 
                        style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white24),
                  onPressed: _toAssign[type]! > 0 ? () => setState(() => _toAssign[type] = _toAssign[type]! - 1) : null,
                ),
                SizedBox(
                  width: 30,
                  child: Center(
                    child: Text('${_toAssign[type]}', 
                      style: const TextStyle(color: AppColors.brushedGold, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.brushedGold),
                  onPressed: (_toAssign[type]! < remainingForType && currentTotalToAssign < remainingInTable) 
                      ? () => setState(() => _toAssign[type] = _toAssign[type]! + 1) 
                      : null,
                ),
              ],
            ),
          );
        }).toList(),
      ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _selectedGuest = null),
          child: const Text('Atrás', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: currentTotalToAssign > 0 ? () async {
            final counts = Map<String, int>.from(_toAssign)..removeWhere((k, v) => v == 0);
            
            // Cerrar primero para estabilidad en Web
            Navigator.pop(context);

            await widget.service.addAssignment(widget.eventId, SeatingAssignment(
              id: '',
              guestId: g.id,
              tableId: widget.table.id,
              counts: counts,
            ));
          } : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brushedGold, foregroundColor: AppColors.charcoal),
          child: const Text('Asignar'),
        ),
      ],
    );
  }
}
