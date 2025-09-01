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
  String get irABarberias => 'Find barbershops';

  @override
  String get irATurnos => 'Available appointments';

  @override
  String get irADomicilio => 'Home barbers';
}
