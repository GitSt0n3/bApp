import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'l10n_en.dart';
import 'l10n_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/l10n.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
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
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S? of(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'BarberiApp'**
  String get appTitle;

  /// No description provided for @bienvenida.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BarberiApp'**
  String get bienvenida;

  /// No description provided for @irAMapa.
  ///
  /// In en, this message translates to:
  /// **'Find barbershops'**
  String get irAMapa;

  /// No description provided for @irABarberias.
  ///
  /// In en, this message translates to:
  /// **'Barbers'**
  String get irABarberias;

  /// No description provided for @irATurnos.
  ///
  /// In en, this message translates to:
  /// **'Available appointments'**
  String get irATurnos;

  /// No description provided for @irADomicilio.
  ///
  /// In en, this message translates to:
  /// **'Home barbers'**
  String get irADomicilio;

  /// No description provided for @soyBarbero.
  ///
  /// In en, this message translates to:
  /// **'I am Barber'**
  String get soyBarbero;

  /// No description provided for @soporte.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get soporte;

  /// No description provided for @servicios.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get servicios;

  /// No description provided for @buscarServicio.
  ///
  /// In en, this message translates to:
  /// **'Find a service or barbershop...'**
  String get buscarServicio;

  /// No description provided for @aDomicilio.
  ///
  /// In en, this message translates to:
  /// **'Home service'**
  String get aDomicilio;

  /// No description provided for @enBarberia.
  ///
  /// In en, this message translates to:
  /// **'At barbershop'**
  String get enBarberia;

  /// No description provided for @noHayServiciosDisponibles.
  ///
  /// In en, this message translates to:
  /// **'No services available'**
  String get noHayServiciosDisponibles;

  /// No description provided for @errorCargandoServicios.
  ///
  /// In en, this message translates to:
  /// **'Error loading services:'**
  String get errorCargandoServicios;

  /// No description provided for @errorCargandoPerfil.
  ///
  /// In en, this message translates to:
  /// **'Error loading profile'**
  String get errorCargandoPerfil;

  /// No description provided for @errorCargandoBarberia.
  ///
  /// In en, this message translates to:
  /// **'Error loading barbershop'**
  String get errorCargandoBarberia;

  /// No description provided for @ubicacionServiciosDeshabilitados.
  ///
  /// In en, this message translates to:
  /// **'Location services disabled'**
  String get ubicacionServiciosDeshabilitados;

  /// No description provided for @ubicacionNoSePudoObtener.
  ///
  /// In en, this message translates to:
  /// **'Could not get location:'**
  String get ubicacionNoSePudoObtener;

  /// No description provided for @ubicacionLatLngFmt.
  ///
  /// In en, this message translates to:
  /// **'Lat {lat}, Lng {lng}'**
  String ubicacionLatLngFmt(Object lat, Object lng);

  /// No description provided for @urlReservasInvalida.
  ///
  /// In en, this message translates to:
  /// **'Invalid booking URL'**
  String get urlReservasInvalida;

  /// No description provided for @debeDefinirUbicacionBase.
  ///
  /// In en, this message translates to:
  /// **'To offer home service, define your base location'**
  String get debeDefinirUbicacionBase;

  /// No description provided for @perfilActualizado.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get perfilActualizado;

  /// No description provided for @errorGuardando.
  ///
  /// In en, this message translates to:
  /// **'Error saving:'**
  String get errorGuardando;

  /// No description provided for @ofrezcoDomicilio.
  ///
  /// In en, this message translates to:
  /// **'I offer home service'**
  String get ofrezcoDomicilio;

  /// No description provided for @direccionBaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Base address (optional)'**
  String get direccionBaseLabel;

  /// No description provided for @radioKm.
  ///
  /// In en, this message translates to:
  /// **'Radius (km):'**
  String get radioKm;

  /// No description provided for @direccionLugarHolder.
  ///
  /// In en, this message translates to:
  /// **'Street, number, neighborhood…'**
  String get direccionLugarHolder;

  /// No description provided for @usarmiubicacionctual.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get usarmiubicacionctual;

  /// No description provided for @selectorMapaPendiente.
  ///
  /// In en, this message translates to:
  /// **'Map selector: pending'**
  String get selectorMapaPendiente;

  /// No description provided for @barberiaNoEncontrada.
  ///
  /// In en, this message translates to:
  /// **'Barbershop not found'**
  String get barberiaNoEncontrada;

  /// No description provided for @reservarExterno.
  ///
  /// In en, this message translates to:
  /// **'Book (external)'**
  String get reservarExterno;

  /// No description provided for @verServicios.
  ///
  /// In en, this message translates to:
  /// **'View Services'**
  String get verServicios;

  /// No description provided for @newService.
  ///
  /// In en, this message translates to:
  /// **'New service'**
  String get newService;

  /// No description provided for @serviceHintExample.
  ///
  /// In en, this message translates to:
  /// **'Ej: Corte clásico'**
  String get serviceHintExample;

  /// No description provided for @enterName.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get enterName;

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get durationMinutes;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (UYU)'**
  String get priceLabel;

  /// No description provided for @enterPrice.
  ///
  /// In en, this message translates to:
  /// **'Enter a price'**
  String get enterPrice;

  /// No description provided for @invalidPrice.
  ///
  /// In en, this message translates to:
  /// **'Invalid price'**
  String get invalidPrice;

  /// No description provided for @verPerfil.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get verPerfil;

  /// No description provided for @elegirEnMapa.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get elegirEnMapa;

  /// No description provided for @cambiarEnMapa.
  ///
  /// In en, this message translates to:
  /// **'Change on map'**
  String get cambiarEnMapa;

  /// No description provided for @redesSocialesTitulo.
  ///
  /// In en, this message translates to:
  /// **'Social media'**
  String get redesSocialesTitulo;

  /// No description provided for @instagramLabel.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get instagramLabel;

  /// No description provided for @instagramHint.
  ///
  /// In en, this message translates to:
  /// **'https://instagram.com/my_username'**
  String get instagramHint;

  /// No description provided for @whatsappLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get whatsappLabel;

  /// No description provided for @whatsappHint.
  ///
  /// In en, this message translates to:
  /// **'+5989xxxxxxx'**
  String get whatsappHint;

  /// No description provided for @facebookLabel.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get facebookLabel;

  /// No description provided for @facebookHint.
  ///
  /// In en, this message translates to:
  /// **'https://facebook.com/my_page'**
  String get facebookHint;

  /// No description provided for @tiktokLabel.
  ///
  /// In en, this message translates to:
  /// **'TikTok'**
  String get tiktokLabel;

  /// No description provided for @tiktokHint.
  ///
  /// In en, this message translates to:
  /// **'https://www.tiktok.com/@my_username'**
  String get tiktokHint;

  /// No description provided for @appReservasTitulo.
  ///
  /// In en, this message translates to:
  /// **'Booking app'**
  String get appReservasTitulo;

  /// No description provided for @proveedorLabel.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get proveedorLabel;

  /// No description provided for @proveedorNinguna.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get proveedorNinguna;

  /// No description provided for @proveedorOtra.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get proveedorOtra;

  /// No description provided for @urlReservasLabel.
  ///
  /// In en, this message translates to:
  /// **'Booking URL'**
  String get urlReservasLabel;

  /// No description provided for @urlReservasHintWeiBook.
  ///
  /// In en, this message translates to:
  /// **'https://weibook.uy/your_barber'**
  String get urlReservasHintWeiBook;

  /// No description provided for @urlReservasHintOtra.
  ///
  /// In en, this message translates to:
  /// **'https://my-bookings.com/user'**
  String get urlReservasHintOtra;

  /// No description provided for @guardarBtn.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get guardarBtn;

  /// No description provided for @barberoAuthTitulo.
  ///
  /// In en, this message translates to:
  /// **'Barber access'**
  String get barberoAuthTitulo;

  /// No description provided for @iniciarSesion.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get iniciarSesion;

  /// No description provided for @continuarConGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continuarConGoogle;

  /// No description provided for @continuarConApple.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continuarConApple;

  /// No description provided for @cerrarSesion.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get cerrarSesion;

  /// No description provided for @ingresoExitoso.
  ///
  /// In en, this message translates to:
  /// **'Signed in successfully'**
  String get ingresoExitoso;

  /// No description provided for @errorAutenticando.
  ///
  /// In en, this message translates to:
  /// **'Sign-in error'**
  String get errorAutenticando;

  /// No description provided for @registrarme.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get registrarme;

  /// No description provided for @emailInvalido.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get emailInvalido;

  /// No description provided for @contrasenaLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get contrasenaLabel;

  /// No description provided for @contrasenaMin6.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get contrasenaMin6;

  /// No description provided for @entrar.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get entrar;

  /// No description provided for @nombreApellidoLabel.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get nombreApellidoLabel;

  /// No description provided for @requerido.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requerido;

  /// No description provided for @telefonoLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get telefonoLabel;

  /// No description provided for @telefonoInvalido.
  ///
  /// In en, this message translates to:
  /// **'Invalid phone number'**
  String get telefonoInvalido;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @repetirContrasenaLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get repetirContrasenaLabel;

  /// No description provided for @contrasenaNoCoincide.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t match'**
  String get contrasenaNoCoincide;

  /// No description provided for @ofrezcoDomicilioToggle.
  ///
  /// In en, this message translates to:
  /// **'I offer home service'**
  String get ofrezcoDomicilioToggle;

  /// No description provided for @toggleDomicilioHint.
  ///
  /// In en, this message translates to:
  /// **'You can enable/disable it later'**
  String get toggleDomicilioHint;

  /// No description provided for @crearCuenta.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get crearCuenta;

  /// No description provided for @crearBarberia.
  ///
  /// In en, this message translates to:
  /// **'Create barbershop'**
  String get crearBarberia;

  /// No description provided for @nombre.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nombre;

  /// No description provided for @direccion.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get direccion;

  /// No description provided for @seleccionaEnMapa.
  ///
  /// In en, this message translates to:
  /// **'Select on the map'**
  String get seleccionaEnMapa;

  /// No description provided for @crear.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get crear;

  /// No description provided for @seleccionaUbicacion.
  ///
  /// In en, this message translates to:
  /// **'Select location'**
  String get seleccionaUbicacion;

  /// No description provided for @seleccionaBarberiaODomicilio.
  ///
  /// In en, this message translates to:
  /// **'Select a barbershop or choose \"Home service\".'**
  String get seleccionaBarberiaODomicilio;

  /// No description provided for @duracionMinima30.
  ///
  /// In en, this message translates to:
  /// **'Minimum duration is 30 minutes.'**
  String get duracionMinima30;

  /// No description provided for @diasEntre1y31.
  ///
  /// In en, this message translates to:
  /// **'Days must be between 1 and 31.'**
  String get diasEntre1y31;

  /// No description provided for @tramoHorarioInsuficiente.
  ///
  /// In en, this message translates to:
  /// **'The daily time window isn\'t long enough for an appointment.'**
  String get tramoHorarioInsuficiente;

  /// No description provided for @turnosGeneradosOk.
  ///
  /// In en, this message translates to:
  /// **'Time slots generated 👌'**
  String get turnosGeneradosOk;

  /// No description provided for @generarTurnosTitulo.
  ///
  /// In en, this message translates to:
  /// **'Generate time slots'**
  String get generarTurnosTitulo;

  /// No description provided for @barberia.
  ///
  /// In en, this message translates to:
  /// **'Barbershop'**
  String get barberia;

  /// No description provided for @horaInicio.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get horaInicio;

  /// No description provided for @horaFin.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get horaFin;

  /// No description provided for @duracionTurnoMin.
  ///
  /// In en, this message translates to:
  /// **'Slot duration (min)'**
  String get duracionTurnoMin;

  /// No description provided for @diasAGenerarLabel.
  ///
  /// In en, this message translates to:
  /// **'Days to generate (1–31)'**
  String get diasAGenerarLabel;

  /// No description provided for @diasAGenerarHelper.
  ///
  /// In en, this message translates to:
  /// **'Maximum 31 days to match monthly subscription'**
  String get diasAGenerarHelper;

  /// No description provided for @generar.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get generar;

  /// No description provided for @panelBarberoTitulo.
  ///
  /// In en, this message translates to:
  /// **'Barber panel'**
  String get panelBarberoTitulo;

  /// No description provided for @misBarberias.
  ///
  /// In en, this message translates to:
  /// **'My barbershops'**
  String get misBarberias;

  /// No description provided for @configurarMiBarberia.
  ///
  /// In en, this message translates to:
  /// **'Set up my barbershop'**
  String get configurarMiBarberia;

  /// No description provided for @turnos.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get turnos;

  /// No description provided for @miPerfil.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get miPerfil;

  /// No description provided for @configurarMiBarberiaTitulo.
  ///
  /// In en, this message translates to:
  /// **'Set up my barbershop'**
  String get configurarMiBarberiaTitulo;

  /// No description provided for @sinBarberiasVinculadas.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any linked barbershops yet'**
  String get sinBarberiasVinculadas;

  /// No description provided for @crearMiBarberia.
  ///
  /// In en, this message translates to:
  /// **'Create my barbershop'**
  String get crearMiBarberia;

  /// No description provided for @solicitarVinculoProximamente.
  ///
  /// In en, this message translates to:
  /// **'Request link (coming soon)'**
  String get solicitarVinculoProximamente;

  /// No description provided for @noPudimosCargarBarberias.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load barbershops'**
  String get noPudimosCargarBarberias;

  /// No description provided for @verEnMapa.
  ///
  /// In en, this message translates to:
  /// **'View on map'**
  String get verEnMapa;

  /// No description provided for @errorCargandoBarberosDomicilio.
  ///
  /// In en, this message translates to:
  /// **'Error loading home barbers'**
  String get errorCargandoBarberosDomicilio;

  /// No description provided for @sinBarberosDomicilioCerca.
  ///
  /// In en, this message translates to:
  /// **'No hay barberos a domicilio cerca.'**
  String get sinBarberosDomicilioCerca;

  /// No description provided for @distanciaLabel.
  ///
  /// In en, this message translates to:
  /// **'Distance:'**
  String get distanciaLabel;

  /// No description provided for @recargoDomicilioLabel.
  ///
  /// In en, this message translates to:
  /// **'Home service surcharge:'**
  String get recargoDomicilioLabel;

  /// No description provided for @homeServiciosDomicilioTitle.
  ///
  /// In en, this message translates to:
  /// **'Home services'**
  String get homeServiciosDomicilioTitle;

  /// No description provided for @homeServiciosDomicilioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Haircuts, shaving, combos — near your location'**
  String get homeServiciosDomicilioSubtitle;

  /// No description provided for @homeBarberosDomicilioTitle.
  ///
  /// In en, this message translates to:
  /// **'Home barbers'**
  String get homeBarberosDomicilioTitle;

  /// No description provided for @homeBarberosDomicilioSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Barbers serving your area'**
  String get homeBarberosDomicilioSubtitle;

  /// No description provided for @servicioGuardado.
  ///
  /// In en, this message translates to:
  /// **'Service saved'**
  String get servicioGuardado;

  /// No description provided for @noSePudoGuardar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save'**
  String get noSePudoGuardar;

  /// No description provided for @errorDesconocido.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get errorDesconocido;

  /// No description provided for @eliminarServicioTitulo.
  ///
  /// In en, this message translates to:
  /// **'Delete service'**
  String get eliminarServicioTitulo;

  /// No description provided for @eliminarServicioPregunta.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this service?'**
  String get eliminarServicioPregunta;

  /// No description provided for @cancelar.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelar;

  /// No description provided for @eliminar.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get eliminar;

  /// No description provided for @activos.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activos;

  /// No description provided for @activo.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activo;

  /// No description provided for @inactiveChip.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactiveChip;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @vinculacion.
  ///
  /// In en, this message translates to:
  /// **'Linking'**
  String get vinculacion;

  /// No description provided for @servicioEliminado.
  ///
  /// In en, this message translates to:
  /// **'Service deleted'**
  String get servicioEliminado;

  /// No description provided for @noSePuedeBorrarTieneCitas.
  ///
  /// In en, this message translates to:
  /// **'Can\'t delete because it has associated appointments. Disable the service to hide it.'**
  String get noSePuedeBorrarTieneCitas;

  /// No description provided for @noSePudoBorrarPermisoRestriccion.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete (permission or constraint)'**
  String get noSePudoBorrarPermisoRestriccion;

  /// No description provided for @noSePudoBorrar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete'**
  String get noSePudoBorrar;

  /// No description provided for @integrarGenerarTurnosHint.
  ///
  /// In en, this message translates to:
  /// **'Hook up navigation to \"Generate time slots\"'**
  String get integrarGenerarTurnosHint;

  /// No description provided for @minutesShort.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minutesShort;

  /// No description provided for @surchargePlus.
  ///
  /// In en, this message translates to:
  /// **'+ Surcharge'**
  String get surchargePlus;

  /// No description provided for @chooseBarbershop.
  ///
  /// In en, this message translates to:
  /// **'Choose a barbershop'**
  String get chooseBarbershop;

  /// No description provided for @allMyBarbershops.
  ///
  /// In en, this message translates to:
  /// **'All my barbershops'**
  String get allMyBarbershops;

  /// No description provided for @noBarbershopsMember.
  ///
  /// In en, this message translates to:
  /// **'You are not a member of any barbershop'**
  String get noBarbershopsMember;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return SEn();
    case 'es': return SEs();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
