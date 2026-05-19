// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Planea';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navGuests => 'Invitados';

  @override
  String get navTables => 'Mesas';

  @override
  String get navEvents => 'Eventos';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get premiumBadge => 'Premium';

  @override
  String get loginSubtitle => 'Gestión premium de eventos';

  @override
  String get loginSignIn => 'Iniciar Sesión';

  @override
  String get loginCreateAccount => 'Crear Cuenta';

  @override
  String get loginEmail => 'Correo electrónico';

  @override
  String get loginPassword => 'Contraseña';

  @override
  String get loginInvalidEmail => 'Correo inválido';

  @override
  String get loginMinPassword => 'Mínimo 6 caracteres';

  @override
  String get loginNoAccount => '¿Sin cuenta? Regístrate';

  @override
  String get loginHasAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get celebrationProgress => '🎉 Progreso de Celebración';

  @override
  String confirmedOfTotal(int confirmed, int total) {
    return '$confirmed de $total confirmados';
  }

  @override
  String get guestSummary => 'Resumen de Invitados';

  @override
  String get myEvents => 'Mis Eventos';

  @override
  String get recentActivity => 'Actividad Reciente';

  @override
  String get noEventsYet => 'Sin eventos aún';

  @override
  String get noEventsYetSubtitle => 'Crea tu primer evento para comenzar.';

  @override
  String get startPlanning => '¡Empieza a planear!';

  @override
  String get startPlanningSubtitle =>
      'Crea tu primer evento y empieza a gestionar invitados.';

  @override
  String get statConfirmed => 'Confirmados';

  @override
  String get statPending => 'Pendientes';

  @override
  String get statDeclined => 'Declinados';

  @override
  String get guestConfirmed => 'Confirmado';

  @override
  String get guestPending => 'Pendiente';

  @override
  String get guestDeclined => 'Declinado';

  @override
  String get rolePadrino => '✨ Padrino';

  @override
  String get roleVip => '⭐ VIP';

  @override
  String get roleRegular => 'Regular';

  @override
  String get guestsTitle => 'Invitados';

  @override
  String get addGuest => 'Agregar Invitado';

  @override
  String get searchGuest => 'Buscar invitado…';

  @override
  String get noGuests => 'Sin invitados';

  @override
  String get selectEventFirst => 'Selecciona un evento primero.';

  @override
  String get filterGuests => 'Filtrar Invitados';

  @override
  String get tablesTitle => 'Gestión de Mesas';

  @override
  String get addTable => 'Agregar Mesa';

  @override
  String get tableName => 'Nombre de la mesa (Ej: Mesa 1)';

  @override
  String get tableCapacity => 'Capacidad (Personas)';

  @override
  String get noTables => 'Sin mesas registradas';

  @override
  String get tableShape => 'Forma';

  @override
  String get shapeCircular => 'Circular';

  @override
  String get shapeSquare => 'Cuadrada';

  @override
  String get shapeRectangular => 'Rectangular';

  @override
  String get venueElementDanceFloor => 'Pista de baile';

  @override
  String get venueElementDJ => 'DJ / Audio';

  @override
  String get venueElementCandyBar => 'Mesa de dulces';

  @override
  String get venueElementEntrance => 'Entrada';

  @override
  String get venueElementReception => 'Recepción';

  @override
  String get venueElementBar => 'Bar / Bebidas';

  @override
  String get venueElementBathrooms => 'Baños';

  @override
  String get venueElementKitchen => 'Cocina';

  @override
  String get venueElementOther => 'Otro';

  @override
  String spotsLeft(int count) {
    return '$count libres';
  }

  @override
  String get tableFull => 'Llena';

  @override
  String get filterStatus => 'Estado';

  @override
  String get filterRole => 'Rol';

  @override
  String get applyFilters => 'Aplicar Filtros';

  @override
  String tableLabel(String table) {
    return 'Mesa $table';
  }

  @override
  String companionsLabel(int count) {
    return '+$count';
  }

  @override
  String get addGuestTitle => 'Agregar Invitado';

  @override
  String get fullNameLabel => 'Nombre completo';

  @override
  String get roleLabel => 'Rol';

  @override
  String get tableOptional => 'Mesa (opcional)';

  @override
  String companionsCount(int count) {
    return 'Acompañantes: $count';
  }

  @override
  String get saveButton => 'Guardar';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get deleteButton => 'Eliminar';

  @override
  String get editButton => 'Editar';

  @override
  String get deleteConfirmTitle => 'Eliminar Invitado';

  @override
  String get deleteConfirmMessage =>
      '¿Estás seguro de que deseas eliminar a este invitado? Esta acción no se puede deshacer.';

  @override
  String get guestDisplayName => 'Nombre para mostrar (Familia o Persona)';

  @override
  String get guestFirstName => 'Nombre(s)';

  @override
  String get guestLastName => 'Apellido(s)';

  @override
  String get countAdults => 'Adultos';

  @override
  String get countChildren => 'Niños';

  @override
  String get countTeenagers => 'Adolescentes';

  @override
  String get countDisabled => 'Personas con discapacidad';

  @override
  String get contactInfoSection => 'Información de Contacto';

  @override
  String get contactPhone => 'Teléfono';

  @override
  String get contactEmail => 'Correo electrónico';

  @override
  String get contactSocial => 'Red Social / Link';

  @override
  String get notesLabel => 'Notas u observaciones';

  @override
  String get dietaryLabel => 'Restricciones alimenticias / Alergias';

  @override
  String get eventsTitle => 'Eventos';

  @override
  String get newEvent => 'Nuevo Evento';

  @override
  String get createEvent => 'Crear Evento';

  @override
  String get eventNameLabel => 'Nombre del evento';

  @override
  String get eventTypeLabel => 'Tipo de evento';

  @override
  String eventDateLabel(String date) {
    return 'Fecha: $date';
  }

  @override
  String get venueOptional => 'Venue (opcional)';

  @override
  String get typeWedding => 'Boda';

  @override
  String get typeQuinceanera => 'XV años';

  @override
  String get typeBirthday => 'Cumpleaños';

  @override
  String get typeCorporate => 'Corporativo';

  @override
  String get typeGraduation => 'Graduación';

  @override
  String get typeOther => 'Otro';

  @override
  String get colorPaletteSection => 'Paleta de Colores';

  @override
  String get budgetSection => 'Presupuesto';

  @override
  String get eventDetailsSection => 'Detalles del Evento';

  @override
  String get primaryColorLabel => 'Color Primario';

  @override
  String get accentColorLabel => 'Color Secundario';

  @override
  String get previewLabel => 'Vista Previa';

  @override
  String get totalBudgetLabel => 'Presupuesto Total';

  @override
  String get remainingLabel => 'Restante';

  @override
  String budgetSpentLabel(String amount) {
    return 'Gastado: $amount';
  }

  @override
  String get typeLabelDetail => 'Tipo';

  @override
  String get dateLabelDetail => 'Fecha';

  @override
  String get venueLabelDetail => 'Venue';

  @override
  String get chooseColorTitle => 'Elige un Color';

  @override
  String get selectColorHeading => 'Seleccionar Color';

  @override
  String get adjustToneSubheading => 'Ajustar tono';

  @override
  String get applyButton => 'Aplicar';

  @override
  String chooseColorFor(String label) {
    return 'Elige: $label';
  }

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get darkModeLabel => 'Modo Oscuro';

  @override
  String get globalPaletteSection => 'Paleta Global';

  @override
  String get primaryColorSetting => 'Color Principal';

  @override
  String get accentColorSetting => 'Color de Acento';

  @override
  String get restorePaletteButton => 'Restaurar Paleta Premium';

  @override
  String get themePreviewSection => 'Vista Previa del Tema';

  @override
  String get buttonPreviewLabel => 'Botón';

  @override
  String get outlinePreviewLabel => 'Outline';

  @override
  String get accountSection => 'Cuenta';

  @override
  String get signOutLabel => 'Cerrar Sesión';

  @override
  String get versionLabel => 'Planea v1.0.0 · Premium';

  @override
  String get organizerLabel => 'Organizador';

  @override
  String get languageSection => 'Idioma';

  @override
  String get languageLabel => 'Idioma de la App';

  @override
  String get langAuto => 'Auto (Sistema)';

  @override
  String get langEnglish => 'Inglés';

  @override
  String get langSpanish => 'Español';

  @override
  String get rsvpTitle => 'Portal RSVP';

  @override
  String get rsvpSubtitle => 'Confirma tu asistencia al evento';

  @override
  String get rsvpEnterCode =>
      'Introduce tu código de invitación para continuar';

  @override
  String get rsvpInviteCode => 'Código de invitación';

  @override
  String get rsvpCodeError => 'Código de invitación no válido o inexistente';

  @override
  String get rsvpSearchName => 'Busca tu nombre en la lista para confirmar';

  @override
  String get rsvpSearchNameHint => 'Escribe tu nombre...';

  @override
  String get rsvpConfirmAttendance => 'Confirmación de Asistencia';

  @override
  String get rsvpSelectMenu => 'Selección de Menú';

  @override
  String get rsvpDietaryRestrictions => 'Restricciones alimenticias / Alergias';

  @override
  String get rsvpSubmit => 'Confirmar RSVP';

  @override
  String get rsvpSuccessTitle => '¡Asistencia Confirmada!';

  @override
  String get rsvpSuccessSubtitle =>
      'Tu pase de acceso digital ha sido generado.';

  @override
  String get rsvpTicketTable => 'Mesa';

  @override
  String get rsvpMenuMeat => '🥩 Tradicional (Corte de Wagyu)';

  @override
  String get rsvpMenuFish => '🐟 Gourmet (Salmón Grillado)';

  @override
  String get rsvpMenuVeg => '🥗 Vegetariano (Risotto de Champiñones)';

  @override
  String get rsvpMenuKids => '👶 Menú Infantil (Chicken & Chips)';

  @override
  String get rsvpChangeCode => 'Cambiar Código';

  @override
  String get rsvpAttendanceArrived => '¡Asistencia registrada!';

  @override
  String get rsvpTicketPass => 'Pase de Acceso';

  @override
  String get rsvpClose => 'Cerrar';
}
