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
  String get errorCargandoBarberia => 'Error cargando barberia';

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

  @override
  String get usarmiubicacionctual => 'Usar mi ubicación actual';

  @override
  String get selectorMapaPendiente => 'Selector de mapa: pendiente';

  @override
  String get barberiaNoEncontrada => 'Barbería no encontrada';

  @override
  String get reservarExterno => 'Reservar (externo)';

  @override
  String get verServicios => 'Ver Servicios';

  @override
  String get elegirEnMapa => 'Elegir en mapa';

  @override
  String get cambiarEnMapa => 'Cambiar en mapa';

  @override
  String get redesSocialesTitulo => 'Redes sociales';

  @override
  String get instagramLabel => 'Instagram';

  @override
  String get instagramHint => 'https://instagram.com/mi_usuario';

  @override
  String get whatsappLabel => 'WhatsApp';

  @override
  String get whatsappHint => '+5989xxxxxxx';

  @override
  String get facebookLabel => 'Facebook';

  @override
  String get facebookHint => 'https://facebook.com/mi_pagina';

  @override
  String get tiktokLabel => 'TikTok';

  @override
  String get tiktokHint => 'https://www.tiktok.com/@mi_usuario';

  @override
  String get appReservasTitulo => 'App de reservas';

  @override
  String get proveedorLabel => 'Proveedor';

  @override
  String get proveedorNinguna => 'Ninguna';

  @override
  String get proveedorOtra => 'Otra';

  @override
  String get urlReservasLabel => 'URL de reservas';

  @override
  String get urlReservasHintWeiBook => 'https://weibook.uy/tu_barber';

  @override
  String get urlReservasHintOtra => 'https://mi-reservas.com/usuario';

  @override
  String get guardarBtn => 'Guardar';
}
