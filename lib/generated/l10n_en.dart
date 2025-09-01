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
}
