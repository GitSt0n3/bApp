// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class SEs extends S {
  SEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'BarberiApp';

  @override
  String get bienvenida => 'Bienvenido a BarberiApps';

  @override
  String get irAMapa => 'Mapa Barberías';

  @override
  String get irABarberias => 'Barberias';

  @override
  String get irATurnos => 'Ver turnos';

  @override
  String get irADomicilio => 'Barberos a domicilio';

  @override
  String get soyBarbero => 'Soy Barbero';

  @override
  String get soporte => 'Soporte';

  @override
  String get servicios => 'Servicios';

  @override
  String get buscarServicio => 'Buscar servicio o barberia...';

  @override
  String get aDomicilio => 'A domicilio';

  @override
  String get enBarberia => 'A Barberia';

  @override
  String get noHayServiciosDisponibles => 'No servicios disponibles';

  @override
  String get errorCargandoServicios => 'Error cargando servicios:';

  @override
  String get errorCargandoPerfil => 'Error cargando Perfil';

  @override
  String get ubicacionServiciosDeshabilitados => 'Servicios de ubicación deshabilitados';

  @override
  String get ubicacionNoSePudoObtener => 'No se pudo obtener ubicación:';

  @override
  String ubicacionLatLngFmt(Object lat, Object lng) {
    return 'Lat $lat, Lng $lng';
  }

  @override
  String get urlReservasInvalida => 'URL de reservas inválida';

  @override
  String get debeDefinirUbicacionBase => 'Para ofrecer a domicilio, define tu ubicación base';

  @override
  String get perfilActualizado => 'Perfil actualizado';

  @override
  String get errorGuardando => 'Error guardando:';

  @override
  String get ofrezcoDomicilio => 'Ofrezco trabajo a domicilio';

  @override
  String get direccionBaseLabel => 'Dirección base (opcional)';

  @override
  String get radioKm => 'Radio (km):';

  @override
  String get direccionLugarHolder => 'Calle, nro, barrio…';
}
