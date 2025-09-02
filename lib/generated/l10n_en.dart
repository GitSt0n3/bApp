// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class SEn extends S {
  SEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'BarberiApp';

  @override
  String get bienvenida => 'Welcome to BarberiApp';

  @override
  String get irAMapa => 'Find barbershops';

  @override
  String get irABarberias => 'Barbers';

  @override
  String get irATurnos => 'Available appointments';

  @override
  String get irADomicilio => 'Home barbers';

  @override
  String get soyBarbero => 'I am Barber';

  @override
  String get soporte => 'Support';

  @override
  String get servicios => 'Services';

  @override
  String get buscarServicio => 'Find a service or barbershop...';

  @override
  String get aDomicilio => 'Home service';

  @override
  String get enBarberia => 'At barbershop';

  @override
  String get noHayServiciosDisponibles => 'No services available';

  @override
  String get errorCargandoServicios => 'Error loading services:';

  @override
  String get errorCargandoPerfil => 'Error loading profile';

  @override
  String get errorCargandoBarberia => 'Error loading barbershop';

  @override
  String get ubicacionServiciosDeshabilitados => 'Location services disabled';

  @override
  String get ubicacionNoSePudoObtener => 'Could not get location:';

  @override
  String ubicacionLatLngFmt(Object lat, Object lng) {
    return 'Lat $lat, Lng $lng';
  }

  @override
  String get urlReservasInvalida => 'Invalid booking URL';

  @override
  String get debeDefinirUbicacionBase => 'To offer home service, define your base location';

  @override
  String get perfilActualizado => 'Profile updated';

  @override
  String get errorGuardando => 'Error saving:';

  @override
  String get ofrezcoDomicilio => 'I offer home service';

  @override
  String get direccionBaseLabel => 'Base address (optional)';

  @override
  String get radioKm => 'Radius (km):';

  @override
  String get direccionLugarHolder => 'Street, number, neighborhood…';

  @override
  String get usarmiubicacionctual => 'Use my current location';

  @override
  String get selectorMapaPendiente => 'Map selector: pending';

  @override
  String get barberiaNoEncontrada => 'Barbershop not found';

  @override
  String get reservarExterno => 'Book (external)';

  @override
  String get verServicios => 'View Services';

  @override
  String get elegirEnMapa => 'Pick on map';

  @override
  String get cambiarEnMapa => 'Change on map';

  @override
  String get redesSocialesTitulo => 'Social media';

  @override
  String get instagramLabel => 'Instagram';

  @override
  String get instagramHint => 'https://instagram.com/my_username';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get whatsappHint => '+5989xxxxxxx';

  @override
  String get facebookLabel => 'Facebook';

  @override
  String get facebookHint => 'https://facebook.com/my_page';

  @override
  String get tiktokLabel => 'TikTok';

  @override
  String get tiktokHint => 'https://www.tiktok.com/@my_username';

  @override
  String get appReservasTitulo => 'Booking app';

  @override
  String get proveedorLabel => 'Provider';

  @override
  String get proveedorNinguna => 'None';

  @override
  String get proveedorOtra => 'Other';

  @override
  String get urlReservasLabel => 'Booking URL';

  @override
  String get urlReservasHintWeiBook => 'https://weibook.uy/your_barber';

  @override
  String get urlReservasHintOtra => 'https://my-bookings.com/user';

  @override
  String get guardarBtn => 'Save';

  @override
  String get barberoAuthTitulo => 'Barber access';

  @override
  String get iniciarSesion => 'Sign in';

  @override
  String get continuarConGoogle => 'Continue with Google';

  @override
  String get continuarConApple => 'Continue with Apple';

  @override
  String get cerrarSesion => 'Sign out';

  @override
  String get ingresoExitoso => 'Signed in successfully';

  @override
  String get errorAutenticando => 'Sign-in error';

  @override
  String get registrarme => 'Sign up';

  @override
  String get emailInvalido => 'Invalid email';

  @override
  String get contrasenaLabel => 'Password';

  @override
  String get contrasenaMin6 => 'At least 6 characters';

  @override
  String get entrar => 'Sign in';

  @override
  String get nombreApellidoLabel => 'Full name';

  @override
  String get requerido => 'Required';

  @override
  String get telefonoLabel => 'Phone';

  @override
  String get telefonoInvalido => 'Invalid phone number';

  @override
  String get emailLabel => 'Email';

  @override
  String get repetirContrasenaLabel => 'Repeat password';

  @override
  String get contrasenaNoCoincide => 'Doesn\'t match';

  @override
  String get ofrezcoDomicilioToggle => 'I offer home service';

  @override
  String get toggleDomicilioHint => 'You can enable/disable it later';

  @override
  String get crearCuenta => 'Create account';

  @override
  String get crearBarberia => 'Create barbershop';

  @override
  String get nombre => 'Name';

  @override
  String get direccion => 'Address';

  @override
  String get seleccionaEnMapa => 'Select on the map';

  @override
  String get crear => 'Create';

  @override
  String get seleccionaUbicacion => 'Select location';

  @override
  String get seleccionaBarberiaODomicilio => 'Select a barbershop or choose \"Home service\".';

  @override
  String get duracionMinima30 => 'Minimum duration is 30 minutes.';

  @override
  String get diasEntre1y31 => 'Days must be between 1 and 31.';

  @override
  String get tramoHorarioInsuficiente => 'The daily time window isn\'t long enough for an appointment.';

  @override
  String get turnosGeneradosOk => 'Time slots generated 👌';

  @override
  String get generarTurnosTitulo => 'Generate time slots';

  @override
  String get barberia => 'Barbershop';

  @override
  String get horaInicio => 'Start';

  @override
  String get horaFin => 'End';

  @override
  String get duracionTurnoMin => 'Slot duration (min)';

  @override
  String get diasAGenerarLabel => 'Days to generate (1–31)';

  @override
  String get diasAGenerarHelper => 'Maximum 31 days to match monthly subscription';

  @override
  String get generar => 'Generate';
}
