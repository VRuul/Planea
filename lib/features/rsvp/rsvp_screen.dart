import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../data/models/event_model.dart';
import '../../data/models/guest_model.dart';
import '../../data/services/supabase_service.dart';
import '../../data/models/seating_data_model.dart';
import '../../data/models/seating_assignment_model.dart';
import '../../data/models/table_model.dart';
import '../../data/models/venue_element_model.dart';

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
    final rTheme = _currentEvent != null
        ? RsvpTheme.fromStyle(_currentEvent!.rsvpConfig.themeStyle)
        : RsvpTheme.fromStyle('classic_gold');

    return Scaffold(
      backgroundColor: rTheme.backgroundColor,
      appBar: AppBar(
        title: Text(l.rsvpTitle, style: TextStyle(fontWeight: FontWeight.bold, color: rTheme.primaryTextColor, letterSpacing: 1)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop() 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: rTheme.primaryTextColor),
              onPressed: () => context.pop(),
            )
          : null,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: rTheme.backgroundGradient,
            ),
          ),
          // Blobs
          Positioned(top: -100, right: -50, child: _GoldBlob(size: 350, color: rTheme.blobColor)),
          Positioned(bottom: -100, left: -50, child: _GoldBlob(size: 300, color: rTheme.blobColor)),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 550),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildMainContent(theme, l, rTheme),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ThemeData theme, AppLocalizations l, RsvpTheme rTheme) {
    if (_currentEvent == null) {
      return _buildCodeEntry(theme, l, rTheme);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Cover & Header Card
        _buildInvitationHeader(rTheme, theme),
        const SizedBox(height: 16),

        // 2. Countdown Timer
        if (_currentEvent!.rsvpConfig.showCountdown) ...[
          RsvpCountdown(eventDate: _currentEvent!.date, theme: rTheme),
          const SizedBox(height: 16),
        ],

        // 3. Event Details Card
        _buildInvitationDetailsCard(rTheme, theme, l),
        const SizedBox(height: 16),

        // 4. Gift Registry Button
        if (_currentEvent!.rsvpConfig.registryUrl != null && _currentEvent!.rsvpConfig.registryUrl!.isNotEmpty) ...[
          _buildGiftRegistryCard(rTheme, theme),
          const SizedBox(height: 16),
        ],

        // 5. Table Locator Card
        if (_selectedGuest != null && _currentEvent!.rsvpConfig.showMap) ...[
          _buildTableLocatorCard(rTheme, theme),
          const SizedBox(height: 16),
        ],

        // 6. Confirmation Flow
        if (_submittedSuccess)
          _buildTicketPass(theme, l, rTheme)
        else if (_selectedGuest == null)
          _buildGuestSelection(theme, l, rTheme)
        else
          _buildRsvpForm(theme, l, rTheme),
      ],
    );
  }

  // Phase 1: Code Entry
  Widget _buildCodeEntry(ThemeData theme, AppLocalizations l, RsvpTheme rTheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: _glassDecoration(rTheme),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.mark_email_read_outlined, size: 64, color: rTheme.accentColor),
          const SizedBox(height: 24),
          Text(
            l.rsvpTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: rTheme.primaryTextColor,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.rsvpSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: rTheme.secondaryTextColor.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 36),
          Text(
            l.rsvpEnterCode,
            style: TextStyle(color: rTheme.primaryTextColor.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: TextStyle(color: rTheme.primaryTextColor, letterSpacing: 3, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'PLA-XXXXXX',
              hintStyle: TextStyle(color: rTheme.secondaryTextColor.withValues(alpha: 0.3), letterSpacing: 3),
              prefixIcon: Icon(Icons.qr_code, color: rTheme.accentColor),
              filled: true,
              fillColor: rTheme.primaryTextColor.withValues(alpha: 0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: rTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: rTheme.accentColor, width: 1.5),
              ),
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
                ? Center(child: CircularProgressIndicator(color: rTheme.accentColor))
                : ElevatedButton(
                    onPressed: () => _lookupEventCode(_codeController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: rTheme.accentColor,
                      foregroundColor: rTheme.backgroundColor == const Color(0xFFF9F6F0) ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
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
  Widget _buildGuestSelection(ThemeData theme, AppLocalizations l, RsvpTheme rTheme) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: _glassDecoration(rTheme),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: rTheme.accentColor, size: 20),
                onPressed: () {
                  setState(() {
                    _currentEvent = null;
                    _error = null;
                  });
                },
              ),
              Expanded(
                child: Text(
                  "Busca tu Nombre",
                  style: rTheme.titleStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.rsvpSearchName,
            style: TextStyle(color: rTheme.secondaryTextColor.withValues(alpha: 0.8), fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _filterGuests,
            style: TextStyle(color: rTheme.primaryTextColor),
            decoration: InputDecoration(
              hintText: l.rsvpSearchNameHint,
              hintStyle: TextStyle(color: rTheme.secondaryTextColor.withValues(alpha: 0.3)),
              prefixIcon: Icon(Icons.search, color: rTheme.secondaryTextColor.withValues(alpha: 0.5)),
              filled: true,
              fillColor: rTheme.primaryTextColor.withValues(alpha: 0.03),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: rTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: rTheme.accentColor, width: 1.5),
              ),
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
                    separatorBuilder: (_, __) => Divider(color: rTheme.borderColor.withValues(alpha: 0.2)),
                    itemBuilder: (context, index) {
                      final guest = _filteredGuests[index];
                      String roleTag = '';
                      if (guest.role == GuestRole.padrino) roleTag = ' ✨ Padrino';
                      if (guest.role == GuestRole.vip) roleTag = ' ⭐ VIP';

                      return ListTile(
                        title: Text(
                          guest.displayName,
                          style: TextStyle(color: rTheme.primaryTextColor, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${guest.firstName ?? ''} ${guest.lastName ?? ''}$roleTag'.trim(),
                          style: TextStyle(color: rTheme.secondaryTextColor.withValues(alpha: 0.6), fontSize: 12),
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
                                  : rTheme.accentColor,
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
  Widget _buildRsvpForm(ThemeData theme, AppLocalizations l, RsvpTheme rTheme) {
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
      decoration: _glassDecoration(rTheme),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios, color: rTheme.accentColor, size: 20),
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
                        style: rTheme.titleStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Completa tu confirmación a continuación:',
                        style: TextStyle(color: rTheme.secondaryTextColor.withValues(alpha: 0.6), fontSize: 12),
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
              style: TextStyle(color: rTheme.primaryTextColor.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
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
                    theme: rTheme,
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
                    theme: rTheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_rsvpStatus == GuestStatus.confirmed) ...[
              // Companions Counts (Read-Only Info Box)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: rTheme.primaryTextColor.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: rTheme.borderColor.withValues(alpha: 0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people_outline, color: rTheme.accentColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'LUGARES RESERVADOS',
                          style: TextStyle(
                            color: rTheme.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildReadOnlyCountRow('Adultos', _adultsCount, rTheme),
                    if (_teenagersCount > 0) ...[
                      const Divider(color: Colors.white10, height: 16),
                      _buildReadOnlyCountRow('Adolescentes', _teenagersCount, rTheme),
                    ],
                    if (_childrenCount > 0) ...[
                      const Divider(color: Colors.white10, height: 16),
                      _buildReadOnlyCountRow('Niños', _childrenCount, rTheme),
                    ],
                    if (_disabledCount > 0) ...[
                      const Divider(color: Colors.white10, height: 16),
                      _buildReadOnlyCountRow('Accesos Especiales', _disabledCount, rTheme),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu Selection (Read-Only Info Box)
              if (_selectedMenu != null && _selectedMenu!.isNotEmpty) ...[
                Text(
                  'PLATILLO ASIGNADO',
                  style: TextStyle(
                    color: rTheme.primaryTextColor.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Builder(
                  builder: (context) {
                    final selectedOpt = menuOptions.firstWhere(
                      (opt) => opt['value'] == _selectedMenu,
                      orElse: () => {'value': '', 'label': 'No especificado'},
                    );
                    
                    MenuModel? matchedMenu;
                    if (_currentEvent != null && _currentEvent!.menus.isNotEmpty) {
                      final index = _currentEvent!.menus.indexWhere((m) => m.id == _selectedMenu);
                      if (index != -1) matchedMenu = _currentEvent!.menus[index];
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: rTheme.primaryTextColor.withValues(alpha: 0.02),
                        border: Border.all(color: rTheme.borderColor),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListTile(
                            dense: true,
                            leading: Icon(Icons.restaurant, color: rTheme.accentColor, size: 20),
                            title: Text(
                              selectedOpt['label']!,
                              style: TextStyle(
                                color: rTheme.accentColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (matchedMenu != null && matchedMenu.courses.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 12, right: 12, bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: rTheme.backgroundColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: rTheme.borderColor.withValues(alpha: 0.2)),
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
                                            color: rTheme.accentColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            course.name,
                                            style: TextStyle(color: rTheme.accentColor, fontSize: 8, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                course.dishName,
                                                style: TextStyle(color: rTheme.primaryTextColor.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                              if (course.description != null && course.description!.isNotEmpty)
                                                Text(
                                                  course.description!,
                                                  style: TextStyle(color: rTheme.secondaryTextColor.withValues(alpha: 0.5), fontSize: 9),
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
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Dietary Restrictions Field (Still editable, as food allergies are critical)
              TextFormField(
                controller: _dietaryController,
                style: TextStyle(color: rTheme.primaryTextColor, fontSize: 14),
                decoration: _inputDecoration(l.rsvpDietaryRestrictions, Icons.restaurant, rTheme),
              ),
              const SizedBox(height: 16),
            ],

            // Add notes field
            TextFormField(
              controller: _notesController,
              maxLines: 2,
              style: TextStyle(color: rTheme.primaryTextColor, fontSize: 14),
              decoration: _inputDecoration(l.notesLabel, Icons.rate_review_outlined, rTheme),
            ),
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: rTheme.accentColor))
                  : ElevatedButton(
                      onPressed: _submitRsvp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rTheme.accentColor,
                        foregroundColor: rTheme.backgroundColor == const Color(0xFFF9F6F0) ? Colors.white : Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(l.rsvpSubmit.toUpperCase()),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Phase 4: Access Ticket Pass
  Widget _buildTicketPass(ThemeData theme, AppLocalizations l, RsvpTheme rTheme) {
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
            border: Border.all(color: rTheme.borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: rTheme.accentColor.withValues(alpha: 0.12),
                blurRadius: 50,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                // Ticket Background Design
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rTheme.accentColor.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                // Main Ticket Body
                Container(
                  color: rTheme.backgroundColor == const Color(0xFFF9F6F0) ? Colors.white : const Color(0xFF1E1E1E),
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
                              Icon(Icons.brightness_5, color: rTheme.accentColor, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'PLANEA',
                                style: TextStyle(color: rTheme.secondaryTextColor, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 2),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: rTheme.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              l.rsvpTicketPass.toUpperCase(),
                              style: TextStyle(color: rTheme.accentColor, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Event Name
                      Text(
                        _currentEvent!.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: rTheme.accentColor, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                      ),
                      if (_currentEvent!.celebrantNames != null && _currentEvent!.celebrantNames!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          _currentEvent!.celebrantNames!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: rTheme.secondaryTextColor, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 20),
                      
                      // Dotted Ticket Divider
                      Row(
                        children: List.generate(20, (index) => Expanded(
                          child: Container(
                            color: index % 2 == 0 ? Colors.transparent : rTheme.secondaryTextColor.withValues(alpha: 0.15),
                            height: 1,
                          ),
                        )),
                      ),
                      const SizedBox(height: 20),

                      // Guest Display Name
                      Text(
                        _selectedGuest!.displayName,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: rTheme.primaryTextColor, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedGuest!.role == GuestRole.padrino
                            ? l.rolePadrino
                            : _selectedGuest!.role == GuestRole.vip
                                ? l.roleVip
                                : 'Invitado Regular',
                        style: TextStyle(color: rTheme.accentColor, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 24),

                      // QR Code Simulated
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: rTheme.primaryTextColor.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: rTheme.borderColor, width: 1.2),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.qr_code_2_rounded,
                              size: 130,
                              color: rTheme.accentColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _selectedGuest!.id.substring(0, 8).toUpperCase(),
                              style: TextStyle(color: rTheme.secondaryTextColor.withValues(alpha: 0.4), fontSize: 9, letterSpacing: 3, fontFamily: 'Courier'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Details columns
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDetailColumn('CANTIDAD', '${_selectedGuest!.totalSeats} PERS', rTheme),
                          if (_selectedGuest!.status == GuestStatus.confirmed)
                            _buildDetailColumn('MENÚ', menuName.split(' ').first, rTheme),
                          _buildDetailColumn('ESTADO', _selectedGuest!.status == GuestStatus.confirmed ? 'CONFIRMADO' : 'DECLINADO', rTheme),
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
            side: BorderSide(color: rTheme.accentColor.withValues(alpha: 0.3)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(l.rsvpChangeCode.toUpperCase(), style: TextStyle(color: rTheme.accentColor)),
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
    required RsvpTheme theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? selectedColor : theme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? selectedColor : theme.secondaryTextColor.withValues(alpha: 0.4), size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.primaryTextColor : theme.secondaryTextColor.withValues(alpha: 0.5),
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

  Widget _buildReadOnlyCountRow(String label, int count, RsvpTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: theme.secondaryTextColor, fontSize: 13)),
        Text(
          '$count',
          style: TextStyle(color: theme.primaryTextColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDetailColumn(String label, String value, RsvpTheme theme) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: theme.secondaryTextColor.withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: theme.primaryTextColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  BoxDecoration _glassDecoration(RsvpTheme theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: theme.borderColor, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 40,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, RsvpTheme theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: theme.secondaryTextColor.withValues(alpha: 0.5), fontSize: 13),
      prefixIcon: Icon(icon, color: theme.accentColor, size: 20),
      filled: true,
      fillColor: theme.primaryTextColor.withValues(alpha: 0.02),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.borderColor)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.borderColor)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: theme.accentColor, width: 1.5)),
    );
  }

  Widget _buildCoverPhoto(RsvpTheme rTheme) {
    var coverUrl = _currentEvent?.rsvpConfig.coverPhotoUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      if (kIsWeb && (coverUrl.contains('drive.google.com') || coverUrl.contains('docs.google.com') || coverUrl.contains('googleusercontent.com'))) {
        final encodedUrl = Uri.encodeComponent(coverUrl);
        coverUrl = 'https://images.weserv.nl/?url=$encodedUrl';
      }
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: rTheme.cardColor,
            child: Center(
              child: CircularProgressIndicator(color: rTheme.accentColor),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildDefaultIllustration(rTheme);
        },
      );
    }
    return _buildDefaultIllustration(rTheme);
  }

  Widget _buildDefaultIllustration(RsvpTheme rTheme) {
    IconData icon = Icons.celebration_outlined;
    String title = 'INVITACIÓN ESPECIAL';
    
    if (_currentEvent != null) {
      switch (_currentEvent!.type) {
        case EventType.wedding:
          icon = Icons.favorite_border_rounded;
          title = 'NUESTRA BODA';
          break;
        case EventType.quinceanera:
          icon = Icons.auto_awesome_outlined;
          title = 'MIS XV AÑOS';
          break;
        case EventType.birthday:
          icon = Icons.cake_outlined;
          title = 'MI CUMPLEAÑOS';
          break;
        case EventType.corporate:
          icon = Icons.business_center_outlined;
          title = 'EVENTO CORPORATIVO';
          break;
        case EventType.graduation:
          icon = Icons.school_outlined;
          title = 'GRADUACIÓN';
          break;
        default:
          icon = Icons.celebration_outlined;
          title = 'CELEBRACIÓN';
      }
    }

    final isLight = _currentEvent?.rsvpConfig.themeStyle == 'minimal_light';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLight
              ? [const Color(0xFFF3E5AB).withValues(alpha: 0.2), const Color(0xFFD4AF37).withValues(alpha: 0.1)]
              : [rTheme.accentColor.withValues(alpha: 0.15), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: rTheme.accentColor),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: rTheme.accentColor,
                fontWeight: FontWeight.w900,
                fontSize: 14,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatEventDate(DateTime date) {
    const months = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'];
    const weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return "${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]} de ${date.year}";
  }

  String _formatEventTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute hrs";
  }

  Widget _buildInvitationHeader(RsvpTheme rTheme, ThemeData theme) {
    final nameStyle = rTheme.titleStyle.copyWith(
      fontSize: 24,
      letterSpacing: 2,
    );

    return Container(
      decoration: BoxDecoration(
        color: rTheme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: rTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(27)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: _buildCoverPhoto(rTheme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Text(
                  _currentEvent!.name.toUpperCase(),
                  style: TextStyle(
                    color: rTheme.accentColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                if (_currentEvent!.celebrantNames != null && _currentEvent!.celebrantNames!.isNotEmpty) ...[
                  Text(
                    _currentEvent!.celebrantNames!,
                    style: nameStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  "¡Te invitamos a celebrar con nosotros!",
                  style: TextStyle(
                    color: rTheme.secondaryTextColor.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationDetailsCard(RsvpTheme rTheme, ThemeData theme, AppLocalizations l) {
    final dateStr = _formatEventDate(_currentEvent!.date);
    final timeStr = _formatEventTime(_currentEvent!.date);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: rTheme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: rTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "DETALLES DEL EVENTO",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: rTheme.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Date and Time
          _buildDetailRow(
            icon: Icons.calendar_today_outlined,
            title: "Fecha",
            subtitle: dateStr,
            theme: rTheme,
          ),
          const Divider(color: Colors.white12, height: 24),
          _buildDetailRow(
            icon: Icons.access_time,
            title: "Hora",
            subtitle: timeStr,
            theme: rTheme,
          ),

          // Venue details (Map locations)
          Builder(
            builder: (context) {
              final config = _currentEvent!.rsvpConfig;
              final hasChurch = config.churchMapUrl != null && config.churchMapUrl!.isNotEmpty;
              final hasVenue = config.venueMapUrl != null && config.venueMapUrl!.isNotEmpty;
              final hasCustom = config.customMapUrl != null && config.customMapUrl!.isNotEmpty;
              
              if (hasChurch || hasVenue || hasCustom) {
                return Column(
                  children: [
                    if (hasChurch) ...[
                      const Divider(color: Colors.white12, height: 24),
                      _buildDetailRow(
                        icon: Icons.church_outlined,
                        title: "Ceremonia / Iglesia",
                        subtitle: _currentEvent!.venue ?? "Ver ubicación en el mapa",
                        theme: rTheme,
                        trailing: IconButton(
                          icon: Icon(Icons.map_outlined, color: rTheme.accentColor),
                          onPressed: () async {
                            final url = Uri.parse(config.churchMapUrl!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),
                    ],
                    if (hasVenue) ...[
                      const Divider(color: Colors.white12, height: 24),
                      _buildDetailRow(
                        icon: Icons.business_outlined,
                        title: "Recepción / Salón",
                        subtitle: _currentEvent!.venue ?? "Ver ubicación en el mapa",
                        theme: rTheme,
                        trailing: IconButton(
                          icon: Icon(Icons.map_outlined, color: rTheme.accentColor),
                          onPressed: () async {
                            final url = Uri.parse(config.venueMapUrl!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),
                    ],
                    if (hasCustom) ...[
                      const Divider(color: Colors.white12, height: 24),
                      _buildDetailRow(
                        icon: Icons.map_outlined,
                        title: config.customMapLabel ?? "Ubicación Especial",
                        subtitle: "Ver ubicación en el mapa",
                        theme: rTheme,
                        trailing: IconButton(
                          icon: Icon(Icons.map_outlined, color: rTheme.accentColor),
                          onPressed: () async {
                            final url = Uri.parse(config.customMapUrl!);
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                );
              }
              
              // Fallback to default search query
              if (_currentEvent!.venue != null && _currentEvent!.venue!.isNotEmpty) {
                return Column(
                  children: [
                    const Divider(color: Colors.white12, height: 24),
                    _buildDetailRow(
                      icon: Icons.location_on_outlined,
                      title: "Lugar",
                      subtitle: _currentEvent!.venue!,
                      theme: rTheme,
                      trailing: IconButton(
                        icon: Icon(Icons.map_outlined, color: rTheme.accentColor),
                        onPressed: () async {
                          final query = Uri.encodeComponent(_currentEvent!.venue!);
                          final url = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                    ),
                  ],
                );
              }
              
              return const SizedBox.shrink();
            },
          ),

          // Dress code
          if (_currentEvent!.rsvpConfig.dressCode != null && _currentEvent!.rsvpConfig.dressCode!.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildDetailRow(
              icon: Icons.checkroom_outlined,
              title: "Código de Vestimenta",
              subtitle: _currentEvent!.rsvpConfig.dressCode!,
              theme: rTheme,
            ),
          ],

          // Custom host notes
          if (_currentEvent!.rsvpConfig.customNotes != null && _currentEvent!.rsvpConfig.customNotes!.isNotEmpty) ...[
            const Divider(color: Colors.white12, height: 24),
            _buildDetailRow(
              icon: Icons.info_outline,
              title: "Notas Especiales",
              subtitle: _currentEvent!.rsvpConfig.customNotes!,
              theme: rTheme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required RsvpTheme theme,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: theme.accentColor, size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.secondaryTextColor.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.primaryTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildGiftRegistryCard(RsvpTheme rTheme, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: rTheme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: rTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.card_giftcard_outlined, size: 36, color: rTheme.accentColor),
          const SizedBox(height: 12),
          Text(
            "MESA DE REGALOS",
            style: TextStyle(
              color: rTheme.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Tu presencia es nuestro mayor regalo, pero si deseas tener un detalle con nosotros, te compartimos nuestra mesa de regalos.",
            style: TextStyle(
              color: rTheme.secondaryTextColor.withValues(alpha: 0.7),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(_currentEvent!.rsvpConfig.registryUrl!);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: rTheme.accentColor,
              foregroundColor: rTheme.backgroundColor == const Color(0xFFF9F6F0) ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: const Text("Ver Mesa de Regalos", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTableLocatorCard(RsvpTheme rTheme, ThemeData theme) {
    return StreamBuilder<SeatingData>(
      stream: _supabaseService.watchSeatingData(_currentEvent!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: rTheme.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: rTheme.borderColor),
            ),
            child: Center(
              child: CircularProgressIndicator(color: rTheme.accentColor),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!;
        SeatingAssignment? assignment;
        for (final a in data.assignments) {
          if (a.guestId == _selectedGuest!.id) {
            assignment = a;
            break;
          }
        }

        if (assignment == null) {
          return const SizedBox.shrink();
        }

        TableModel? table;
        for (final t in data.tables) {
          if (t.id == assignment.tableId) {
            table = t;
            break;
          }
        }

        if (table == null) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: rTheme.cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: rTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "TU UBICACIÓN EN EL SALÓN",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rTheme.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Te hemos asignado un lugar en la mesa:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rTheme.secondaryTextColor.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                table.name.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: rTheme.primaryTextColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              SeatingMapVisualizer(
                tables: data.tables,
                venueElements: data.venueElements,
                assignedTable: table,
                theme: rTheme,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GoldBlob extends StatelessWidget {
  final double size;
  final Color color;
  const _GoldBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          color.withValues(alpha: 0.10),
          color.withValues(alpha: 0),
        ]),
      ),
    );
  }
}

class RsvpTheme {
  final Color backgroundColor;
  final Gradient backgroundGradient;
  final Color blobColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color cardColor;
  final Color borderColor;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;

  RsvpTheme({
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.blobColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.cardColor,
    required this.borderColor,
    required this.titleStyle,
    required this.bodyStyle,
  });

  factory RsvpTheme.fromStyle(String? style) {
    switch (style) {
      case 'romantic_rose':
        return RsvpTheme(
          backgroundColor: const Color(0xFF2E0814),
          backgroundGradient: const LinearGradient(
            colors: [Color(0xFF2E0814), Color(0xFF0B0104)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          blobColor: const Color(0xFFFFB7B2),
          primaryTextColor: Colors.white,
          secondaryTextColor: const Color(0xFFFFE5EC),
          accentColor: const Color(0xFFFF85A1),
          cardColor: const Color(0xFF1F040C).withValues(alpha: 0.6),
          borderColor: const Color(0xFFFF85A1).withValues(alpha: 0.25),
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF85A1)),
          bodyStyle: const TextStyle(color: Colors.white70),
        );
      case 'midnight_luxury':
        return RsvpTheme(
          backgroundColor: const Color(0xFF0F172A),
          backgroundGradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF020617)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          blobColor: const Color(0xFF94A3B8),
          primaryTextColor: Colors.white,
          secondaryTextColor: const Color(0xFFCBD5E1),
          accentColor: const Color(0xFF38BDF8),
          cardColor: const Color(0xFF1E293B).withValues(alpha: 0.6),
          borderColor: const Color(0xFF38BDF8).withValues(alpha: 0.2),
          titleStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF38BDF8)),
          bodyStyle: const TextStyle(color: Colors.white70),
        );
      case 'minimal_light':
        return RsvpTheme(
          backgroundColor: const Color(0xFFF9F6F0),
          backgroundGradient: const LinearGradient(
            colors: [Color(0xFFF8F4EC), Color(0xFFFFFDF9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          blobColor: const Color(0xFFD4AF37).withValues(alpha: 0.15),
          primaryTextColor: const Color(0xFF1E1E1E),
          secondaryTextColor: const Color(0xFF4A4A4A),
          accentColor: const Color(0xFFC5A85A),
          cardColor: Colors.white.withValues(alpha: 0.7),
          borderColor: const Color(0xFFD4AF37).withValues(alpha: 0.3),
          titleStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC5A85A)),
          bodyStyle: const TextStyle(color: Colors.black87),
        );
      case 'classic_gold':
      default:
        return RsvpTheme(
          backgroundColor: const Color(0xFF111111),
          backgroundGradient: AppColors.darkGradient,
          blobColor: AppColors.brushedGold,
          primaryTextColor: Colors.white,
          secondaryTextColor: Colors.white70,
          accentColor: AppColors.brushedGold,
          cardColor: Colors.black.withValues(alpha: 0.45),
          borderColor: AppColors.brushedGold.withValues(alpha: 0.15),
          titleStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brushedGold),
          bodyStyle: const TextStyle(color: Colors.white70),
        );
    }
  }
}

class RsvpCountdown extends StatefulWidget {
  final DateTime eventDate;
  final RsvpTheme theme;
  const RsvpCountdown({super.key, required this.eventDate, required this.theme});

  @override
  State<RsvpCountdown> createState() => _RsvpCountdownState();
}

class _RsvpCountdownState extends State<RsvpCountdown> {
  late Duration _timeLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _calculateTimeLeft();
        });
      }
    });
  }

  void _calculateTimeLeft() {
    final now = DateTime.now();
    if (widget.eventDate.isAfter(now)) {
      _timeLeft = widget.eventDate.difference(now);
    } else {
      _timeLeft = Duration.zero;
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.inSeconds == 0) {
      return const SizedBox.shrink();
    }

    final days = _timeLeft.inDays;
    final hours = _timeLeft.inHours % 24;
    final minutes = _timeLeft.inMinutes % 60;
    final seconds = _timeLeft.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.theme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            "CUENTA REGRESIVA",
            style: TextStyle(
              color: widget.theme.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeUnit(days, "Días"),
              _buildTimeUnit(hours, "Horas"),
              _buildTimeUnit(minutes, "Min"),
              _buildTimeUnit(seconds, "Seg"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(int value, String label) {
    return Column(
      children: [
        Text(
          value.toString().padLeft(2, '0'),
          style: TextStyle(
            color: widget.theme.primaryTextColor,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: widget.theme.secondaryTextColor.withValues(alpha: 0.6),
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class SeatingMapVisualizer extends StatelessWidget {
  final List<TableModel> tables;
  final List<VenueElementModel> venueElements;
  final TableModel assignedTable;
  final RsvpTheme theme;

  const SeatingMapVisualizer({
    super.key,
    required this.tables,
    required this.venueElements,
    required this.assignedTable,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    if (tables.isEmpty) return const SizedBox.shrink();

    // Calculate bounds
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    for (final t in tables) {
      if (t.posX < minX) minX = t.posX;
      if (t.posY < minY) minY = t.posY;
      if (t.posX > maxX) maxX = t.posX;
      if (t.posY > maxY) maxY = t.posY;
    }

    for (final ve in venueElements) {
      if (ve.posX < minX) minX = ve.posX;
      if (ve.posY < minY) minY = ve.posY;
      if (ve.posX > maxX) maxX = ve.posX;
      if (ve.posY > maxY) maxY = ve.posY;
    }

    const double padding = 40.0;
    minX -= padding;
    minY -= padding;
    maxX += padding;
    maxY += padding;

    final double mapWidth = maxX - minX;
    final double mapHeight = maxY - minY;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double viewWidth = constraints.maxWidth;
        const double viewHeight = 220.0;

        final double scaleX = viewWidth / (mapWidth > 0 ? mapWidth : 1);
        final double scaleY = viewHeight / (mapHeight > 0 ? mapHeight : 1);
        final double scale = scaleX < scaleY ? scaleX : scaleY;

        final double offsetX = (viewWidth - (mapWidth * scale)) / 2 - (minX * scale);
        final double offsetY = (viewHeight - (mapHeight * scale)) / 2 - (minY * scale);

        return Container(
          height: viewHeight,
          width: viewWidth,
          decoration: BoxDecoration(
            color: theme.backgroundColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderColor.withValues(alpha: 0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // Render Venue Elements
                ...venueElements.map((ve) {
                  final double x = ve.posX * scale + offsetX;
                  final double y = ve.posY * scale + offsetY;
                  final double w = ve.width * scale;
                  final double h = ve.height * scale;

                  return Positioned(
                    left: x,
                    top: y,
                    width: w,
                    height: h,
                    child: Container(
                      decoration: BoxDecoration(
                        color: (ve.color ?? theme.accentColor).withValues(alpha: 0.08),
                        border: Border.all(color: (ve.color ?? theme.accentColor).withValues(alpha: 0.2), width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          ve.name,
                          style: TextStyle(
                            color: (ve.color ?? theme.accentColor).withValues(alpha: 0.6),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }),

                // Render Tables
                ...tables.map((t) {
                  final double x = t.posX * scale + offsetX;
                  final double y = t.posY * scale + offsetY;
                  final double r = (t.width ?? 60.0) * scale;
                  final isAssigned = t.id == assignedTable.id;

                  return Positioned(
                    left: x,
                    top: y,
                    width: r,
                    height: r,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: t.shape == TableShape.circular ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: t.shape == TableShape.circular ? null : BorderRadius.circular(8),
                        color: isAssigned 
                            ? theme.accentColor.withValues(alpha: 0.25)
                            : (t.color != null ? Color(t.color!) : theme.accentColor).withValues(alpha: 0.04),
                        border: Border.all(
                          color: isAssigned 
                              ? theme.accentColor
                              : (t.color != null ? Color(t.color!) : theme.accentColor).withValues(alpha: 0.3),
                          width: isAssigned ? 2 : 1,
                        ),
                        boxShadow: isAssigned ? [
                          BoxShadow(
                            color: theme.accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          )
                        ] : null,
                      ),
                      child: Center(
                        child: Text(
                          t.name,
                          style: TextStyle(
                            color: isAssigned ? theme.accentColor : theme.primaryTextColor.withValues(alpha: 0.7),
                            fontWeight: isAssigned ? FontWeight.w900 : FontWeight.normal,
                            fontSize: isAssigned ? 10 : 8,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
