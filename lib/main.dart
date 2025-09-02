import 'package:barberiapp/screens/pantalla_barberias_mapa.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'generated/l10n.dart';
import 'screens/pantalla_inicio.dart';
import 'screens/pantalla_barberias.dart';
import 'screens/pantalla_domicilio_hub.dart';
import 'screens/splash_screen.dart';
import 'screens/barbero_auth_screen.dart';
import 'screens/pantalla_barberos_domicilio.dart';
// import 'screens/gestion_screen.dart';
import 'screens/hub_barbero.dart';
import 'screens/crear_barberia.dart';
import 'screens/mis_barberias_tab.dart';
import 'screens/generar_turnos.dart';
import 'screens/pantalla_turnos_barbero.dart';
import 'screens/pantalla_turnos_cliente.dart';
import 'screens/servicios_screen.dart';
import 'screens/pantalla_servicio_barber.dart';
import 'screens/perfil_barberia.dart';
import 'screens/perfil_barbero.dart';
import 'package:barberiapp/config/env_private.dart'; // ajusta el path si cambia


// const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
// const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey:
       supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      title: 'BarberiApps',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color.fromARGB(255, 214, 7, 7),
        ),
      ),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      locale: const Locale('es'),
    );
  }
}

final _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    // tu ruta principal
    GoRoute(path: '/', builder: (context, state) => const PantallaInicio()),
    GoRoute(
      path: '/barberias',
      builder: (context, state) => const PantallaBarberias(),
    ),
    // GoRoute(
    //   path: '/turnos',
    //   builder: (context, state) => const PantallaTurnos(),
    // ),
    GoRoute(
      path: '/domicilio',
      builder: (context, state) => const PantallaDomicilioHub(),
    ),
    GoRoute(
      path: '/barberos_domicilio',
      builder: (context, state) => const PantallaBarberosDomicilio(),
    ),
    GoRoute(
      path: '/mapa',
      builder: (context, state) => const PantallaBarberiasMapa(),
    ),
    GoRoute(
      path: '/perfil_b/:barberId',
      name: 'perfilBarbero',
      builder: (context, state) {
        final barberId = state.pathParameters['barberId']!;
        return Scaffold(
          appBar: AppBar(title: const Text('Mi perfil')),
          body: PerfilBarberoDomicilioYRedes(barberProfileId: barberId),
        );
      },
    ),

    GoRoute(path: '/hub_barbero', builder: (_, __) => const HubBarbero()),
    GoRoute(path: '/barbero/auth', builder: (_, _) => const BarberAuthScreen()),
    // GoRoute(path: '/gestion', builder: (_, __) => const GestionScreen()),
    // GoRoute(path: '/gestion', builder: (_, __) => const GestionScreen()),
    GoRoute(
      path: '/mis_barberias_tab',
      builder: (_, __) => const MisBarberiasTab(),
    ),
    GoRoute(
      path: '/crear_barberia',
      builder: (_, __) => const CrearBarberiaScreen(),
    ),
    GoRoute(
      path: '/gestion/turnos/generar',
      builder: (context, state) => const PantallaGenerarTurnos(),
    ),
    GoRoute(
      path: '/turnos_barbero',
      builder: (context, state) => const PantallaTurnosBarbero(),
    ),
    GoRoute(
      path: '/servicios',
      builder: (context, state) {
        final extra = (state.extra as Map<String, dynamic>?) ?? const {};
        final barbershopId = extra['barbershopId'] as int?; // puede venir null
        return ServiciosScreen(barbershopId: barbershopId);
      },
    ),
    GoRoute(
      path: '/servicios_domicilio',
      builder: (_, __) => const ServiciosScreen(onlyHomeInitial: true),
    ),
    GoRoute(
      path: '/servicios_b',
      builder: (context, state) => const ServiciosScreenBarber(),
    ),
    GoRoute(
      path: '/perfil_barberia/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PantallaPerfilBarberia(barbershopId: id);
      },
    ),
    GoRoute(
      path: '/turnos',
      name: 'turnos',
      builder: (context, state) {
        final extra = (state.extra as Map<String, dynamic>?) ?? const {};
        final barberId = extra['barber_id'] as String?;
        final serviceId = extra['service_id'] as int?;
        final barbershopId = extra['barbershop_id'] as int?;
        final durationMin = extra['duration_min'] as int;

        if (barberId == null || serviceId == null) {
          return const Scaffold(
            body: Center(child: Text('Faltan parámetros para abrir Turnos')),
          );
        }

        return PantallaTurnosCliente(
          durationMin: durationMin,
          serviceId: serviceId,
          barbershopId: barbershopId, // puede ser null
        );
      },
    ),
  ],
);
