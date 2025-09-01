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
  String get bienvenida => 'Bienvenido a BarberiApp';

  @override
  String get irABarberias => 'Ver barberías';

  @override
  String get irATurnos => 'Ver turnos';

  @override
  String get irADomicilio => 'Barberos a domicilio';
}
