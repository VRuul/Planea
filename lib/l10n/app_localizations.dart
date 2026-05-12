import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Planea'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navGuests.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get navGuests;

  /// No description provided for @navTables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get navTables;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @premiumBadge.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get premiumBadge;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Premium event management'**
  String get loginSubtitle;

  /// No description provided for @loginSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignIn;

  /// No description provided for @loginCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get loginCreateAccount;

  /// No description provided for @loginEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmail;

  /// No description provided for @loginPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPassword;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get loginInvalidEmail;

  /// No description provided for @loginMinPassword.
  ///
  /// In en, this message translates to:
  /// **'Minimum 6 characters'**
  String get loginMinPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'No account? Sign up'**
  String get loginNoAccount;

  /// No description provided for @loginHasAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get loginHasAccount;

  /// No description provided for @celebrationProgress.
  ///
  /// In en, this message translates to:
  /// **'🎉 Celebration Progress'**
  String get celebrationProgress;

  /// No description provided for @confirmedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{confirmed} of {total} confirmed'**
  String confirmedOfTotal(int confirmed, int total);

  /// No description provided for @guestSummary.
  ///
  /// In en, this message translates to:
  /// **'Guest Summary'**
  String get guestSummary;

  /// No description provided for @myEvents.
  ///
  /// In en, this message translates to:
  /// **'My Events'**
  String get myEvents;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get noEventsYet;

  /// No description provided for @noEventsYetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first event to get started.'**
  String get noEventsYetSubtitle;

  /// No description provided for @startPlanning.
  ///
  /// In en, this message translates to:
  /// **'Start planning!'**
  String get startPlanning;

  /// No description provided for @startPlanningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first event and start managing guests.'**
  String get startPlanningSubtitle;

  /// No description provided for @statConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get statConfirmed;

  /// No description provided for @statPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statPending;

  /// No description provided for @statDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get statDeclined;

  /// No description provided for @guestConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get guestConfirmed;

  /// No description provided for @guestPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get guestPending;

  /// No description provided for @guestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get guestDeclined;

  /// No description provided for @rolePadrino.
  ///
  /// In en, this message translates to:
  /// **'✨ Padrino'**
  String get rolePadrino;

  /// No description provided for @roleVip.
  ///
  /// In en, this message translates to:
  /// **'⭐ VIP'**
  String get roleVip;

  /// No description provided for @roleRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get roleRegular;

  /// No description provided for @guestsTitle.
  ///
  /// In en, this message translates to:
  /// **'Guests'**
  String get guestsTitle;

  /// No description provided for @addGuest.
  ///
  /// In en, this message translates to:
  /// **'Add Guest'**
  String get addGuest;

  /// No description provided for @searchGuest.
  ///
  /// In en, this message translates to:
  /// **'Search guest…'**
  String get searchGuest;

  /// No description provided for @noGuests.
  ///
  /// In en, this message translates to:
  /// **'No guests'**
  String get noGuests;

  /// No description provided for @selectEventFirst.
  ///
  /// In en, this message translates to:
  /// **'Select an event first.'**
  String get selectEventFirst;

  /// No description provided for @filterGuests.
  ///
  /// In en, this message translates to:
  /// **'Filter Guests'**
  String get filterGuests;

  /// No description provided for @tablesTitle.
  ///
  /// In en, this message translates to:
  /// **'Table Management'**
  String get tablesTitle;

  /// No description provided for @addTable.
  ///
  /// In en, this message translates to:
  /// **'Add Table'**
  String get addTable;

  /// No description provided for @tableName.
  ///
  /// In en, this message translates to:
  /// **'Table Name (e.g., Table 1)'**
  String get tableName;

  /// No description provided for @tableCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity (People)'**
  String get tableCapacity;

  /// No description provided for @noTables.
  ///
  /// In en, this message translates to:
  /// **'No tables registered'**
  String get noTables;

  /// No description provided for @tableShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get tableShape;

  /// No description provided for @shapeCircular.
  ///
  /// In en, this message translates to:
  /// **'Circular'**
  String get shapeCircular;

  /// No description provided for @shapeSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get shapeSquare;

  /// No description provided for @shapeRectangular.
  ///
  /// In en, this message translates to:
  /// **'Rectangular'**
  String get shapeRectangular;

  /// No description provided for @venueElementDanceFloor.
  ///
  /// In en, this message translates to:
  /// **'Dance Floor'**
  String get venueElementDanceFloor;

  /// No description provided for @venueElementDJ.
  ///
  /// In en, this message translates to:
  /// **'DJ / Audio'**
  String get venueElementDJ;

  /// No description provided for @venueElementCandyBar.
  ///
  /// In en, this message translates to:
  /// **'Candy Bar'**
  String get venueElementCandyBar;

  /// No description provided for @venueElementEntrance.
  ///
  /// In en, this message translates to:
  /// **'Entrance'**
  String get venueElementEntrance;

  /// No description provided for @venueElementReception.
  ///
  /// In en, this message translates to:
  /// **'Reception'**
  String get venueElementReception;

  /// No description provided for @venueElementBar.
  ///
  /// In en, this message translates to:
  /// **'Bar / Drinks'**
  String get venueElementBar;

  /// No description provided for @venueElementBathrooms.
  ///
  /// In en, this message translates to:
  /// **'Bathrooms'**
  String get venueElementBathrooms;

  /// No description provided for @venueElementKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get venueElementKitchen;

  /// No description provided for @venueElementOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get venueElementOther;

  /// No description provided for @spotsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} left'**
  String spotsLeft(int count);

  /// No description provided for @tableFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get tableFull;

  /// No description provided for @filterStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get filterStatus;

  /// No description provided for @filterRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get filterRole;

  /// No description provided for @applyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// No description provided for @tableLabel.
  ///
  /// In en, this message translates to:
  /// **'Table {table}'**
  String tableLabel(String table);

  /// No description provided for @companionsLabel.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String companionsLabel(int count);

  /// No description provided for @addGuestTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Guest'**
  String get addGuestTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullNameLabel;

  /// No description provided for @roleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleLabel;

  /// No description provided for @tableOptional.
  ///
  /// In en, this message translates to:
  /// **'Table (optional)'**
  String get tableOptional;

  /// No description provided for @companionsCount.
  ///
  /// In en, this message translates to:
  /// **'Companions: {count}'**
  String companionsCount(int count);

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @editButton.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButton;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Guest'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this guest? This action cannot be undone.'**
  String get deleteConfirmMessage;

  /// No description provided for @guestDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name (Family or Individual)'**
  String get guestDisplayName;

  /// No description provided for @guestFirstName.
  ///
  /// In en, this message translates to:
  /// **'First Name(s)'**
  String get guestFirstName;

  /// No description provided for @guestLastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name(s)'**
  String get guestLastName;

  /// No description provided for @countAdults.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get countAdults;

  /// No description provided for @countChildren.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get countChildren;

  /// No description provided for @countTeenagers.
  ///
  /// In en, this message translates to:
  /// **'Teenagers'**
  String get countTeenagers;

  /// No description provided for @countDisabled.
  ///
  /// In en, this message translates to:
  /// **'People with disabilities'**
  String get countDisabled;

  /// No description provided for @contactInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInfoSection;

  /// No description provided for @contactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get contactPhone;

  /// No description provided for @contactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get contactEmail;

  /// No description provided for @contactSocial.
  ///
  /// In en, this message translates to:
  /// **'Social Media / Link'**
  String get contactSocial;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes / Observations'**
  String get notesLabel;

  /// No description provided for @dietaryLabel.
  ///
  /// In en, this message translates to:
  /// **'Dietary Restrictions / Allergies'**
  String get dietaryLabel;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @newEvent.
  ///
  /// In en, this message translates to:
  /// **'New Event'**
  String get newEvent;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @eventNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get eventNameLabel;

  /// No description provided for @eventTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get eventTypeLabel;

  /// No description provided for @eventDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String eventDateLabel(String date);

  /// No description provided for @venueOptional.
  ///
  /// In en, this message translates to:
  /// **'Venue (optional)'**
  String get venueOptional;

  /// No description provided for @typeWedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get typeWedding;

  /// No description provided for @typeQuinceanera.
  ///
  /// In en, this message translates to:
  /// **'XV años'**
  String get typeQuinceanera;

  /// No description provided for @typeBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get typeBirthday;

  /// No description provided for @typeCorporate.
  ///
  /// In en, this message translates to:
  /// **'Corporate'**
  String get typeCorporate;

  /// No description provided for @typeGraduation.
  ///
  /// In en, this message translates to:
  /// **'Graduation'**
  String get typeGraduation;

  /// No description provided for @typeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get typeOther;

  /// No description provided for @colorPaletteSection.
  ///
  /// In en, this message translates to:
  /// **'Color Palette'**
  String get colorPaletteSection;

  /// No description provided for @budgetSection.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetSection;

  /// No description provided for @eventDetailsSection.
  ///
  /// In en, this message translates to:
  /// **'Event Details'**
  String get eventDetailsSection;

  /// No description provided for @primaryColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get primaryColorLabel;

  /// No description provided for @accentColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Secondary Color'**
  String get accentColorLabel;

  /// No description provided for @previewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get previewLabel;

  /// No description provided for @totalBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get totalBudgetLabel;

  /// No description provided for @remainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingLabel;

  /// No description provided for @budgetSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent: {amount}'**
  String budgetSpentLabel(String amount);

  /// No description provided for @typeLabelDetail.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabelDetail;

  /// No description provided for @dateLabelDetail.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabelDetail;

  /// No description provided for @venueLabelDetail.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get venueLabelDetail;

  /// No description provided for @chooseColorTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Color'**
  String get chooseColorTitle;

  /// No description provided for @selectColorHeading.
  ///
  /// In en, this message translates to:
  /// **'Select Color'**
  String get selectColorHeading;

  /// No description provided for @adjustToneSubheading.
  ///
  /// In en, this message translates to:
  /// **'Adjust tone'**
  String get adjustToneSubheading;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @chooseColorFor.
  ///
  /// In en, this message translates to:
  /// **'Choose: {label}'**
  String chooseColorFor(String label);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// No description provided for @darkModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkModeLabel;

  /// No description provided for @globalPaletteSection.
  ///
  /// In en, this message translates to:
  /// **'Global Palette'**
  String get globalPaletteSection;

  /// No description provided for @primaryColorSetting.
  ///
  /// In en, this message translates to:
  /// **'Primary Color'**
  String get primaryColorSetting;

  /// No description provided for @accentColorSetting.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColorSetting;

  /// No description provided for @restorePaletteButton.
  ///
  /// In en, this message translates to:
  /// **'Restore Premium Palette'**
  String get restorePaletteButton;

  /// No description provided for @themePreviewSection.
  ///
  /// In en, this message translates to:
  /// **'Theme Preview'**
  String get themePreviewSection;

  /// No description provided for @buttonPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Button'**
  String get buttonPreviewLabel;

  /// No description provided for @outlinePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Outline'**
  String get outlinePreviewLabel;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @signOutLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutLabel;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Planea v1.0.0 · Premium'**
  String get versionLabel;

  /// No description provided for @organizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizerLabel;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get languageLabel;

  /// No description provided for @langAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto (System)'**
  String get langAuto;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langSpanish;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
