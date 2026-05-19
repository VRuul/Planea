import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../data/models/event_model.dart';
import '../../data/models/guest_model.dart';
import '../../data/services/supabase_service.dart';

class RsvpsScreen extends StatefulWidget {
  final String? initialCode;

  const RsvpsScreen({super.key, this.initialCode});

  @override
  State<RsvpsScreen> createState() => _RsvpsScreenState();
}

class _RsvpsScreenState extends State<RsvpsScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService();
  final _codeController = TextEditingController();
  final _searchController = TextEditingController();
  final _notesController = TextEditingController();
  final _dietaryController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();

  // State Variables
  bool _loading = false;
  String? _error;
  EventModel? _currentEvent;
  List<GuestModel> _eventGuests = [];
  List<GuestModel> _filteredGuests = [];
  GuestModel? _selectedGuest;
  
  // RSVP Form fields
  GuestStatus _rsvpStatus = GuestStatus.confirmed;
  String? _selectedMenu;
  int _adultsCount = 1;
  int _childrenCount = 0;
  int _teenagersCount = 0;
  int _disabledCount = 0;

  bool _submittedSuccess = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();

    if (widget.initialCode != null && widget.initialCode!.isNotEmpty) {
      _codeController.text = widget.initialCode!;
      _lookupEventCode(widget.initialCode!);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _searchController.dispose();
    _notesController.dispose();
    _dietaryController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _lookupEventCode(String code) async {
    setState(() {
      _loading = true;
      _error = null;
      _currentEvent = null;
      _selectedGuest = null;
    });

    try {
      final trimmedCode = code.trim().toUpperCase();
      final event = await _supabaseService.findEventByInviteCode(trimmedCode);
      if (event == null) {
        setState(() {
          _error = context.l10n.rsvpCodeError;
          _loading = false;
        });
        return;
      }

      // Load all guests for this event
      final guestsStream = _supabaseService.watchGuests(event.id);
      final guestsList = await guestsStream.first;

      setState(() {
        _currentEvent = event;
        _eventGuests = guestsList;
        _filteredGuests = guestsList;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _filterGuests(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredGuests = _eventGuests;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredGuests = _eventGuests.where((g) {
        final fullName = '${g.displayName} ${g.firstName ?? ''} ${g.lastName ?? ''}'.toLowerCase();
        return fullName.contains(lowercaseQuery);
      }).toList();
    });
  }

  void _selectGuest(GuestModel guest) {
    setState(() {
      _selectedGuest = guest;
      _rsvpStatus = guest.status == GuestStatus.pending ? GuestStatus.confirmed : guest.status;
      _selectedMenu = guest.menuSelection ?? (_currentEvent!.menus.isNotEmpty ? _currentEvent!.menus.first.id : 'meat');
      _adultsCount = guest.adults;
      _childrenCount = guest.children;
      _teenagersCount = guest.teenagers;
      _disabledCount = guest.disabled;
      _notesController.text = guest.notes ?? '';
      _dietaryController.text = guest.dietaryRestrictions ?? '';
    });
  }

  Future<void> _submitRsvp() async {
    if (_selectedGuest == null || _currentEvent == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final updatedGuest = _selectedGuest!.copyWith(
        status: _rsvpStatus,
        menuSelection: _selectedMenu,
        adults: _adultsCount,
        children: _childrenCount,
        teenagers: _teenagersCount,
        disabled: _disabledCount,
        notes: _notesController.text.trim(),
        dietaryRestrictions: _dietaryController.text.trim(),
      );

      await _supabaseService.updateGuest(_currentEvent!.id, updatedGuest);

      setState(() {
        _selectedGuest = updatedGuest;
        _submittedSuccess = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      _selectedGuest = null;
      _submittedSuccess = false;
      _notesController.clear();
      _dietaryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.rsvpTitle, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop() 
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            )
          : null,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.darkGradient,
            ),
          ),
          // Luxury Gold Blobs
          Positioned(top: -100, right: -50, child: _GoldBlob(size: 350)),
          Positioned(bottom: -100, left: -50, child: _GoldBlob(size: 300)),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildMainContent(theme, l),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, AppLocalizations l) {
    if (_submittedSuccess) {
      return _buildTicketPass(theme, l);
    }

    if (_currentEvent == null) {
      return _buildCodeEntry(theme, l);
    }

    if (_selectedGuest == null) {
      return _buildGuestSelection(theme, l);
    }

    return _buildRsvpForm(theme, l);
  }

  // Phase 1: Code Entry
  Widget _buildCodeEntry(ThemeData theme, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _glassDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 64, color: AppColors.brushedGold),
          const SizedBox(height: 24),
          Text(
            l.rsvpTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.rsvpSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 36),
          Text(
            l.rsvpEnterCode,
            style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: Colors.white, letterSpacing: 3, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'PLA-XXXXXX',
              hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 3),
              prefixIcon: const Icon(Icons.qr_code, color: AppColors.brushedGold),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            height: 54,
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brushedGold))
                : ElevatedButton(
                    onPressed: () => _lookupEventCode(_codeController.text),
                    child: Text(theme.platform == TargetPlatform.iOS || theme.platform == TargetPlatform.android
                        ? 'CONTINUAR'
                        : 'CONTINUE'),
                  ),
          ),
        ],
      ),
    );
  }

  // Phase 2: Guest Selection
  Widget _buildGuestSelection(ThemeData theme, AppLocalizations l) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _glassDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: AppColors.brushedGold, size: 20),
                onPressed: () {
                  setState(() {
                    _currentEvent = null;
                    _error = null;
                  });
                },
              ),
              Expanded(
                child: Text(
                  _currentEvent!.name,
                  style: theme.textTheme.titleLarge?.copyWith(color: AppColors.brushedGold, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.rsvpSearchName,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _filterGuests,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: l.rsvpSearchNameHint,
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.03),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: _filteredGuests.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No se encontraron invitados con ese nombre.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: _filteredGuests.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.white.withValues(alpha: 0.05)),
                    itemBuilder: (context, index) {
                      final guest = _filteredGuests[index];
                      String roleTag = '';
                      if (guest.role == GuestRole.padrino) roleTag = ' ✨ Padrino';
                      if (guest.role == GuestRole.vip) roleTag = ' ⭐ VIP';

                      return ListTile(
                        title: Text(
                          guest.displayName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${guest.firstName ?? ''} ${guest.lastName ?? ''}$roleTag'.trim(),
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        trailing: Icon(
                          guest.status == GuestStatus.confirmed 
                              ? Icons.check_circle 
                              : guest.status == GuestStatus.declined 
                                  ? Icons.cancel 
                                  : Icons.arrow_forward_ios,
                          color: guest.status == GuestStatus.confirmed 
                              ? AppColors.confirmed 
                              : guest.status == GuestStatus.declined 
                                  ? AppColors.declined 
                                  : AppColors.brushedGold,
                          size: 18,
                        ),
                        onTap: () => _selectGuest(guest),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Phase 3: RSVP Form
  Widget _buildRsvpForm(ThemeData theme, AppLocalizations l) {
    final List<Map<String, String>> menuOptions;
    if (_currentEvent != null && _currentEvent!.menus.isNotEmpty) {
      menuOptions = _currentEvent!.menus.map((m) => {
        'value': m.id,
        'label': '${m.icon ?? '🍽️'} ${m.name}',
      }).toList();
    } else {
      menuOptions = [
        {'value': 'meat', 'label': l.rsvpMenuMeat},
        {'value': 'fish', 'label': l.rsvpMenuFish},
        {'value': 'veg', 'label': l.rsvpMenuVeg},
        {'value': 'kids', 'label': l.rsvpMenuKids},
      ];
    }

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _glassDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: AppColors.brushedGold, size: 20),
                  onPressed: () {
                    setState(() {
                      _selectedGuest = null;
                    });
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¡Hola, ${(_selectedGuest!.firstName ?? _selectedGuest!.displayName).split(' ').first}!',
                        style: theme.textTheme.titleMedium?.copyWith(color: AppColors.brushedGold, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Completa tu confirmación a continuación:',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Attendance Segmented Selector
            Text(
              l.rsvpConfirmAttendance,
              style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildAttendanceTab(
                    label: 'ASISTIRÉ',
                    icon: Icons.check_circle_outline,
                    isSelected: _rsvpStatus == GuestStatus.confirmed,
                    selectedColor: AppColors.confirmed,
                    onTap: () => setState(() => _rsvpStatus = GuestStatus.confirmed),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAttendanceTab(
                    label: 'NO ASISTIRÉ',
                    icon: Icons.cancel_outlined,
                    isSelected: _rsvpStatus == GuestStatus.declined,
                    selectedColor: AppColors.declined,
                    onTap: () => setState(() => _rsvpStatus = GuestStatus.declined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_rsvpStatus == GuestStatus.confirmed) ...[
              // Companions Counts
              const Text(
                'Acompañantes en tu grupo familiar:',
                style: TextStyle(color: Color(0xDDFFFFFF), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildCounterRow(label: l.countAdults, count: _adultsCount, onChanged: (v) => setState(() => _adultsCount = v)),
              _buildCounterRow(label: l.countTeenagers, count: _teenagersCount, onChanged: (v) => setState(() => _teenagersCount = v)),
              _buildCounterRow(label: l.countChildren, count: _childrenCount, onChanged: (v) => setState(() => _childrenCount = v)),
              _buildCounterRow(label: l.countDisabled, count: _disabledCount, onChanged: (v) => setState(() => _disabledCount = v)),
              const SizedBox(height: 24),

              // Menu Options Selection
              Text(
                l.rsvpSelectMenu,
                style: const TextStyle(color: Color(0xDDFFFFFF), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Column(
                children: menuOptions.map((opt) {
                  final isSelected = _selectedMenu == opt['value'];
                  MenuModel? matchedMenu;
                  if (_currentEvent != null && _currentEvent!.menus.isNotEmpty) {
                    final index = _currentEvent!.menus.indexWhere((m) => m.id == opt['value']);
                    if (index != -1) matchedMenu = _currentEvent!.menus[index];
                  }

                  return Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.brushedGold.withValues(alpha: 0.08) : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? AppColors.brushedGold : Colors.white.withValues(alpha: 0.1),
                            width: isSelected ? 1.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text(
                            opt['label']!,
                            style: TextStyle(
                              color: isSelected ? AppColors.brushedGold : Colors.white70,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                          trailing: isSelected 
                              ? const Icon(Icons.radio_button_checked, color: AppColors.brushedGold, size: 18)
                              : const Icon(Icons.radio_button_off, color: Colors.white24, size: 18),
                          onTap: () => setState(() => _selectedMenu = opt['value']),
                        ),
                      ),
                      if (isSelected && matchedMenu != null && matchedMenu.courses.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: matchedMenu.courses.map((course) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.brushedGold.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        course.name,
                                        style: const TextStyle(color: AppColors.brushedGold, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            course.dishName,
                                            style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                          if (course.description != null && course.description!.isNotEmpty)
                                            Text(
                                              course.description!,
                                              style: const TextStyle(color: Colors.white30, fontSize: 9),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Dietary Restrictions Field
              TextFormField(
                controller: _dietaryController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  labelText: l.rsvpDietaryRestrictions,
                  prefixIcon: const Icon(Icons.restaurant, size: 18),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Add notes field
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: l.notesLabel,
                prefixIcon: const Icon(Icons.rate_review_outlined, size: 18),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.brushedGold))
                  : ElevatedButton(
                      onPressed: _submitRsvp,
                      child: Text(l.rsvpSubmit.toUpperCase()),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Phase 4: Access Ticket Pass
  Widget _buildTicketPass(ThemeData theme, AppLocalizations l) {
    String menuName = 'Sin seleccionar';
    if (_selectedGuest!.menuSelection != null) {
      final selectedId = _selectedGuest!.menuSelection;
      if (_currentEvent != null && _currentEvent!.menus.isNotEmpty) {
        final index = _currentEvent!.menus.indexWhere((m) => m.id == selectedId);
        if (index != -1) {
          final matchedMenu = _currentEvent!.menus[index];
          menuName = '${matchedMenu.icon ?? '🍽️'} ${matchedMenu.name}';
        } else {
          menuName = selectedId!;
        }
      } else {
        if (selectedId == 'meat') menuName = l.rsvpMenuMeat;
        else if (selectedId == 'fish') menuName = l.rsvpMenuFish;
        else if (selectedId == 'veg') menuName = l.rsvpMenuVeg;
        else if (selectedId == 'kids') menuName = l.rsvpMenuKids;
        else menuName = selectedId!;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Premium Ticket Card
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.brushedGold.withValues(alpha: 0.12),
                blurRadius: 50,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                // Golden Ticket Background Design
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brushedGold.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Main Ticket Body
                Container(
                  color: const Color(0xFF1E1E1E),
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Image.asset('assets/logo.png', height: 22, errorBuilder: (_, __, ___) => const Icon(Icons.brightness_5, color: AppColors.brushedGold)),
                              const SizedBox(width: 8),
                              const Text(
                                'PLANEA',
                                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.brushedGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l.rsvpTicketPass.toUpperCase(),
                              style: const TextStyle(color: AppColors.brushedGold, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Event Name & Celebrants
                      Text(
                        _currentEvent!.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.brushedGold, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                      if (_currentEvent!.celebrantNames != null && _currentEvent!.celebrantNames!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _currentEvent!.celebrantNames!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 20),
                      
                      // Dotted Ticket Divider
                      Row(
                        children: List.generate(20, (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0 ? Colors.transparent : Colors.white.withValues(alpha: 0.15),
                            height: 1,
                          ),
                        )),
                      ),
                      const SizedBox(height: 20),

                      // Guest Display Name
                      Text(
                        _selectedGuest!.displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedGuest!.role == GuestRole.padrino
                            ? l.rolePadrino
                            : _selectedGuest!.role == GuestRole.vip
                                ? l.roleVip
                                : 'Invitado Regular',
                        style: const TextStyle(color: AppColors.brushedGold, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),

                      // QR Code Simulated (Luxury Gold look)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.2), width: 1.2),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.qr_code_2_rounded,
                              size: 130,
                              color: AppColors.brushedGold,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedGuest!.id.substring(0, 8).toUpperCase(),
                              style: const TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 3, fontFamily: 'Courier'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Details columns
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailColumn('CANTIDAD', '${_selectedGuest!.totalSeats} PERS'),
                          if (_selectedGuest!.status == GuestStatus.confirmed)
                            _buildDetailColumn('MENÚ', menuName.split(' ').first),
                          _buildDetailColumn('ESTADO', _selectedGuest!.status == GuestStatus.confirmed ? 'CONFIRMADO' : 'DECLINADO'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Return button
        OutlinedButton(
          onPressed: _reset,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: AppColors.brushedGold.withValues(alpha: 0.3)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(l.rsvpChangeCode.toUpperCase(), style: const TextStyle(color: AppColors.brushedGold)),
        ),
      ],
    );
  }

  Widget _buildAttendanceTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? selectedColor : Colors.white38, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterRow({
    required String label,
    required int count,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.brushedGold, size: 22),
                onPressed: count > 0 ? () => onChanged(count - 1) : null,
              ),
              Container(
                constraints: const BoxConstraints(minWidth: 24),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.brushedGold, size: 22),
                onPressed: () => onChanged(count + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      color: Colors.black.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.brushedGold.withValues(alpha: 0.15), width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 40,
        ),
      ],
    );
  }
}

class _GoldBlob extends StatelessWidget {
  final double size;
  const _GoldBlob({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          AppColors.brushedGold.withValues(alpha: 0.10),
          AppColors.brushedGold.withValues(alpha: 0),
        ]),
      ),
    );
  }
}
