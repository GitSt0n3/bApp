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
  String get errorCargandoTurnos => 'Error cargando Turnos';

  @override
  String get errorGuardando => 'Error guardando:';

  @override
  String get errorAutenticando => 'Error autenticando';

  @override
  String get errorCargandoBarberosDomicilio => 'Error cargando barberos a domicilio';

  @override
  String get errorDesconocido => 'Error desconocido';

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
  String get newService => 'Nuevo servicio';

  @override
  String get serviceHintExample => 'Ej: Corte clásico';

  @override
  String get enterName => 'Ingresá un nombre';

  @override
  String get durationMinutes => 'Duración (min)';

  @override
  String get priceLabel => 'Precio (UYU)';

  @override
  String get enterPrice => 'Ingresá un precio';

  @override
  String get invalidPrice => 'Precio inválido';

  @override
  String get verPerfil => 'Ver Perfil';

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

  @override
  String get barberoAuthTitulo => 'Acceso para barbero';

  @override
  String get iniciarSesion => 'Iniciar sesión';

  @override
  String get continuarConGoogle => 'Continuar con Google';

  @override
  String get continuarConApple => 'Continuar con Apple';

  @override
  String get cerrarSesion => 'Cerrar sesión';

  @override
  String get ingresoExitoso => 'Ingreso exitoso';

  @override
  String get registrarme => 'Registrarme';

  @override
  String get emailInvalido => 'Email inválido';

  @override
  String get contrasenaLabel => 'Contraseña';

  @override
  String get contrasenaMin6 => 'Mínimo 6 caracteres';

  @override
  String get entrar => 'Entrar';

  @override
  String get nombreApellidoLabel => 'Nombre y apellido';

  @override
  String get requerido => 'Requerido';

  @override
  String get telefonoLabel => 'Teléfono';

  @override
  String get telefonoInvalido => 'Teléfono inválido';

  @override
  String get emailLabel => 'Email';

  @override
  String get repetirContrasenaLabel => 'Repetir contraseña';

  @override
  String get contrasenaNoCoincide => 'No coincide';

  @override
  String get ofrezcoDomicilioToggle => 'Ofrezco servicio a domicilio';

  @override
  String get toggleDomicilioHint => 'Podrás activarlo/desactivarlo luego';

  @override
  String get crearCuenta => 'Crear cuenta';

  @override
  String get crearBarberia => 'Crear Barberia';

  @override
  String get nombre => 'Nombre';

  @override
  String get direccion => 'Dirección';

  @override
  String get seleccionaEnMapa => 'Seleccioná en el mapa';

  @override
  String get crear => 'Crear';

  @override
  String get seleccionaUbicacion => 'Seleccioná ubicación';

  @override
  String get seleccionaBarberiaODomicilio => 'Seleccioná una barbería o marcá \"A domicilio\".';

  @override
  String get duracionMinima30 => 'La duración mínima es 30 minutos.';

  @override
  String get diasEntre1y31 => 'Los días deben estar entre 1 y 31.';

  @override
  String get tramoHorarioInsuficiente => 'El tramo horario diario no alcanza para un turno.';

  @override
  String get turnosGeneradosOk => 'Turnos generados 👌';

  @override
  String get generarTurnosTitulo => 'Generar turnos';

  @override
  String get barberia => 'Barberia';

  @override
  String get horaInicio => 'Inicio';

  @override
  String get horaFin => 'Fin';

  @override
  String get duracionTurnoMin => 'Duración del turno (min)';

  @override
  String get diasAGenerarLabel => 'Días a generar (1-31)';

  @override
  String get diasAGenerarHelper => 'Máximo 31 días para controlar la suscripción mensual';

  @override
  String get generar => 'Generar';

  @override
  String get panelBarberoTitulo => 'Panel barbero';

  @override
  String get misBarberias => 'Mis barberías';

  @override
  String get configurarMiBarberia => 'Configurar mi barbería';

  @override
  String get turnos => 'Turnos';

  @override
  String get miPerfil => 'Mi perfil';

  @override
  String get configurarMiBarberiaTitulo => 'Configurar mi barbería';

  @override
  String get sinBarberiasVinculadas => 'Aún no tenés barberías vinculadas';

  @override
  String get crearMiBarberia => 'Crear mi barbería';

  @override
  String get solicitarVinculoProximamente => 'Solicitar vínculo (próximamente)';

  @override
  String get noPudimosCargarBarberias => 'No pudimos cargar las barberías';

  @override
  String get verEnMapa => 'Ver en mapa';

  @override
  String get sinBarberosDomicilioCerca => 'No hay barberos a domicilio cerca.';

  @override
  String get distanciaLabel => 'Distancia:';

  @override
  String get recargoDomicilioLabel => 'Recargo a domicilio:';

  @override
  String get homeServiciosDomicilioTitle => 'Servicios a domicilio';

  @override
  String get homeServiciosDomicilioSubtitle => 'Cortes, afeitado, combos — cerca de tu ubicación';

  @override
  String get homeBarberosDomicilioTitle => 'Barberos a domicilio';

  @override
  String get homeBarberosDomicilioSubtitle => 'Barberos que atienden en tu zona';

  @override
  String get servicioGuardado => 'Servicio guardado';

  @override
  String get noSePudoGuardar => 'No se pudo guardar';

  @override
  String get eliminarServicioTitulo => 'Eliminar servicio';

  @override
  String get eliminarServicioPregunta => '¿Seguro que querés eliminar este servicio?';

  @override
  String get cancelar => 'Cancelar';

  @override
  String get eliminar => 'Eliminar';

  @override
  String get activos => 'Activos';

  @override
  String get actionConfirmar => 'Confirmar';

  @override
  String get activo => 'Activo';

  @override
  String get inactiveChip => 'Inactivo';

  @override
  String get edit => 'Editar';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get delete => 'Borrar';

  @override
  String get vinculacion => 'Vinculación';

  @override
  String get servicioEliminado => 'Servicio eliminado';

  @override
  String get noSePuedeBorrarTieneCitas => 'No se puede borrar porque tiene citas asociadas. Desactivá el servicio para ocultarlo.';

  @override
  String get noSePudoBorrarPermisoRestriccion => 'No se pudo borrar (permiso o restricción)';

  @override
  String get noSePudoBorrar => 'No se pudo borrar';

  @override
  String get integrarGenerarTurnosHint => 'Integrar navegación a \"Generar turnos\"';

  @override
  String get minutesShort => 'min';

  @override
  String get surchargePlus => '+ Recargo';

  @override
  String get chooseBarbershop => 'Elegí una barbería';

  @override
  String get allMyBarbershops => 'Todas mis barberías';

  @override
  String get noBarbershopsMember => 'No sos miembro de barberías';

  @override
  String get invalidAmount => 'Monto inválido';

  @override
  String waMensajeOrigenApp(Object appName) {
    return 'Hola, vengo de $appName.';
  }

  @override
  String get barberosSeccionTitulo => 'Barberos';

  @override
  String get barberPublicTitle => 'Perfil del barbero';

  @override
  String get unknownBarber => 'Barbero';

  @override
  String distanceKm(Object km) {
    return 'A $km km';
  }

  @override
  String coverRadiusKm(Object km) {
    return 'Cubre hasta $km km';
  }

  @override
  String homeSurchargeFrom(Object amount) {
    return 'Recargo domicilio desde $amount';
  }

  @override
  String get instagram => 'Instagram';

  @override
  String get servicesTitle => 'Servicios';

  @override
  String get noServicesYet => 'Este barbero aún no tiene servicios publicados.';

  @override
  String durationMin(Object min) {
    return '$min min';
  }

  @override
  String homeSurchargeShort(Object amount) {
    return '+ $amount dom.';
  }

  @override
  String get reserveInWeiBook => 'Reservar en WeiBook';

  @override
  String get viewServicesCta => 'Ver servicios';

  @override
  String get reserveHomeCta => 'Reservar a domicilio';

  @override
  String errLoadingProfile(Object msg) {
    return 'Error cargando perfil: $msg';
  }

  @override
  String get screenTurnosTitulo => 'Elegí tu turno';

  @override
  String get emptyTurnos => 'No hay turnos contiguos para este servicio.\nPodés solicitar agenda o contactar a la barbería.';

  @override
  String lugarBarberiaConNombre(Object name) {
    return 'En barbería $name';
  }

  @override
  String get btnReservar => 'Reservar';

  @override
  String get formGuestTitle => 'Tus datos para la reserva';

  @override
  String get fieldNombreError => 'Ingresá tu nombre';

  @override
  String get fieldCelular => 'Celular';

  @override
  String get fieldCelularError => 'Ingresá tu celular';

  @override
  String get fieldEmailOptional => 'Email (opcional)';

  @override
  String get snackReservaConfirmada => '¡Reserva confirmada!';

  @override
  String snackReservaError(Object error) {
    return 'No se pudo reservar: $error';
  }

  @override
  String get oContinuarCon => 'o continuar con';

  @override
  String get profile_section_integrations => 'Integraciones';
}
