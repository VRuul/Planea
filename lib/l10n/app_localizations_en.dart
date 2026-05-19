// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Planea';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navGuests => 'Guests';

  @override
  String get navTables => 'Tables';

  @override
  String get navEvents => 'Events';

  @override
  String get navSettings => 'Settings';

  @override
  String get premiumBadge => 'Premium';

  @override
  String get loginSubtitle => 'Premium event management';

  @override
  String get loginSignIn => 'Sign In';

  @override
  String get loginCreateAccount => 'Create Account';

  @override
  String get loginEmail => 'Email address';

  @override
  String get loginPassword => 'Password';

  @override
  String get loginInvalidEmail => 'Invalid email';

  @override
  String get loginMinPassword => 'Minimum 6 characters';

  @override
  String get loginNoAccount => 'No account? Sign up';

  @override
  String get loginHasAccount => 'Already have an account? Sign in';

  @override
  String get celebrationProgress => '🎉 Celebration Progress';

  @override
  String confirmedOfTotal(int confirmed, int total) {
    return '$confirmed of $total confirmed';
  }

  @override
  String get guestSummary => 'Guest Summary';

  @override
  String get myEvents => 'My Events';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get noEventsYet => 'No events yet';

  @override
  String get noEventsYetSubtitle => 'Create your first event to get started.';

  @override
  String get startPlanning => 'Start planning!';

  @override
  String get startPlanningSubtitle =>
      'Create your first event and start managing guests.';

  @override
  String get statConfirmed => 'Confirmed';

  @override
  String get statPending => 'Pending';

  @override
  String get statDeclined => 'Declined';

  @override
  String get guestConfirmed => 'Confirmed';

  @override
  String get guestPending => 'Pending';

  @override
  String get guestDeclined => 'Declined';

  @override
  String get rolePadrino => '✨ Padrino';

  @override
  String get roleVip => '⭐ VIP';

  @override
  String get roleRegular => 'Regular';

  @override
  String get guestsTitle => 'Guests';

  @override
  String get addGuest => 'Add Guest';

  @override
  String get searchGuest => 'Search guest…';

  @override
  String get noGuests => 'No guests';

  @override
  String get selectEventFirst => 'Select an event first.';

  @override
  String get filterGuests => 'Filter Guests';

  @override
  String get tablesTitle => 'Table Management';

  @override
  String get addTable => 'Add Table';

  @override
  String get tableName => 'Table Name (e.g., Table 1)';

  @override
  String get tableCapacity => 'Capacity (People)';

  @override
  String get noTables => 'No tables registered';

  @override
  String get tableShape => 'Shape';

  @override
  String get shapeCircular => 'Circular';

  @override
  String get shapeSquare => 'Square';

  @override
  String get shapeRectangular => 'Rectangular';

  @override
  String get venueElementDanceFloor => 'Dance Floor';

  @override
  String get venueElementDJ => 'DJ / Audio';

  @override
  String get venueElementCandyBar => 'Candy Bar';

  @override
  String get venueElementEntrance => 'Entrance';

  @override
  String get venueElementReception => 'Reception';

  @override
  String get venueElementBar => 'Bar / Drinks';

  @override
  String get venueElementBathrooms => 'Bathrooms';

  @override
  String get venueElementKitchen => 'Kitchen';

  @override
  String get venueElementOther => 'Other';

  @override
  String spotsLeft(int count) {
    return '$count left';
  }

  @override
  String get tableFull => 'Full';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterRole => 'Role';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String tableLabel(String table) {
    return 'Table $table';
  }

  @override
  String companionsLabel(int count) {
    return '+$count';
  }

  @override
  String get addGuestTitle => 'Add Guest';

  @override
  String get fullNameLabel => 'Full name';

  @override
  String get roleLabel => 'Role';

  @override
  String get tableOptional => 'Table (optional)';

  @override
  String companionsCount(int count) {
    return 'Companions: $count';
  }

  @override
  String get saveButton => 'Save';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get editButton => 'Edit';

  @override
  String get deleteConfirmTitle => 'Delete Guest';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this guest? This action cannot be undone.';

  @override
  String get guestDisplayName => 'Display Name (Family or Individual)';

  @override
  String get guestFirstName => 'First Name(s)';

  @override
  String get guestLastName => 'Last Name(s)';

  @override
  String get countAdults => 'Adults';

  @override
  String get countChildren => 'Children';

  @override
  String get countTeenagers => 'Teenagers';

  @override
  String get countDisabled => 'People with disabilities';

  @override
  String get contactInfoSection => 'Contact Information';

  @override
  String get contactPhone => 'Phone Number';

  @override
  String get contactEmail => 'Email Address';

  @override
  String get contactSocial => 'Social Media / Link';

  @override
  String get notesLabel => 'Notes / Observations';

  @override
  String get dietaryLabel => 'Dietary Restrictions / Allergies';

  @override
  String get eventsTitle => 'Events';

  @override
  String get newEvent => 'New Event';

  @override
  String get createEvent => 'Create Event';

  @override
  String get eventNameLabel => 'Event name';

  @override
  String get eventTypeLabel => 'Event type';

  @override
  String eventDateLabel(String date) {
    return 'Date: $date';
  }

  @override
  String get venueOptional => 'Venue (optional)';

  @override
  String get typeWedding => 'Wedding';

  @override
  String get typeQuinceanera => 'XV años';

  @override
  String get typeBirthday => 'Birthday';

  @override
  String get typeCorporate => 'Corporate';

  @override
  String get typeGraduation => 'Graduation';

  @override
  String get typeOther => 'Other';

  @override
  String get colorPaletteSection => 'Color Palette';

  @override
  String get budgetSection => 'Budget';

  @override
  String get eventDetailsSection => 'Event Details';

  @override
  String get primaryColorLabel => 'Primary Color';

  @override
  String get accentColorLabel => 'Secondary Color';

  @override
  String get previewLabel => 'Preview';

  @override
  String get totalBudgetLabel => 'Total Budget';

  @override
  String get remainingLabel => 'Remaining';

  @override
  String budgetSpentLabel(String amount) {
    return 'Spent: $amount';
  }

  @override
  String get typeLabelDetail => 'Type';

  @override
  String get dateLabelDetail => 'Date';

  @override
  String get venueLabelDetail => 'Venue';

  @override
  String get chooseColorTitle => 'Choose a Color';

  @override
  String get selectColorHeading => 'Select Color';

  @override
  String get adjustToneSubheading => 'Adjust tone';

  @override
  String get applyButton => 'Apply';

  @override
  String chooseColorFor(String label) {
    return 'Choose: $label';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get darkModeLabel => 'Dark Mode';

  @override
  String get globalPaletteSection => 'Global Palette';

  @override
  String get primaryColorSetting => 'Primary Color';

  @override
  String get accentColorSetting => 'Accent Color';

  @override
  String get restorePaletteButton => 'Restore Premium Palette';

  @override
  String get themePreviewSection => 'Theme Preview';

  @override
  String get buttonPreviewLabel => 'Button';

  @override
  String get outlinePreviewLabel => 'Outline';

  @override
  String get accountSection => 'Account';

  @override
  String get signOutLabel => 'Sign Out';

  @override
  String get versionLabel => 'Planea v1.0.0 · Premium';

  @override
  String get organizerLabel => 'Organizer';

  @override
  String get languageSection => 'Language';

  @override
  String get languageLabel => 'App Language';

  @override
  String get langAuto => 'Auto (System)';

  @override
  String get langEnglish => 'English';

  @override
  String get langSpanish => 'Spanish';

  @override
  String get rsvpTitle => 'RSVP Portal';

  @override
  String get rsvpSubtitle => 'Confirm your attendance to the event';

  @override
  String get rsvpEnterCode => 'Enter your invitation code to continue';

  @override
  String get rsvpInviteCode => 'Invitation Code';

  @override
  String get rsvpCodeError => 'Invalid or non-existent invitation code';

  @override
  String get rsvpSearchName => 'Search your name in the guest list to confirm';

  @override
  String get rsvpSearchNameHint => 'Type your name...';

  @override
  String get rsvpConfirmAttendance => 'Confirm Attendance';

  @override
  String get rsvpSelectMenu => 'Select Catering Menu';

  @override
  String get rsvpDietaryRestrictions => 'Dietary Restrictions / Allergies';

  @override
  String get rsvpSubmit => 'Confirm RSVP';

  @override
  String get rsvpSuccessTitle => 'Attendance Confirmed!';

  @override
  String get rsvpSuccessSubtitle =>
      'Your premium digital access pass has been generated.';

  @override
  String get rsvpTicketTable => 'Table';

  @override
  String get rsvpMenuMeat => '🥩 Traditional (Wagyu Steak)';

  @override
  String get rsvpMenuFish => '🐟 Gourmet (Grilled Salmon)';

  @override
  String get rsvpMenuVeg => '🥗 Vegetarian (Mushroom Risotto)';

  @override
  String get rsvpMenuKids => '👶 Kids Menu (Chicken & Chips)';

  @override
  String get rsvpChangeCode => 'Change Code';

  @override
  String get rsvpAttendanceArrived => 'Attendance registered!';

  @override
  String get rsvpTicketPass => 'Access Pass';

  @override
  String get rsvpClose => 'Close';
}
