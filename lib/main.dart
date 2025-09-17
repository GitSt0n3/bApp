import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:barberiapp/config/env_private.dart';
import 'generated/l10n.dart';

// Pantallas
import 'screens/pantalla_inicio.dart';
import 'screens/splash_screen.dart';
import 'screens/barbero_auth_screen.dart';
import 'screens/hub_barbero.dart';
import 'screens/pantalla_barberias.dart';
import 'screens/pantalla_barberias_mapa.dart';
import 'screens/pantalla_domicilio_hub.dart';
import 'screens/pantalla_barberos_domicilio.dart';
import 'screens/mis_barberias_tab.dart';
import 'screens/crear_barberia.dart';
import 'screens/generar_turnos.dart';
import 'screens/pantalla_turnos_barbero.dart';
import 'screens/pantalla_turnos_cliente.dart';
import 'screens/servicios_screen.dart';
import 'screens/pantalla_servicio_barber.dart';
import 'screens/perfil_barberia.dart';
import 'screens/perfil_barbero.dart';
import 'screens/perfil_barbero_public.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

late final GoRouter _router;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: true),
  );
  final sp = Supabase.instance.client;

  // 🔎 LOG TEMPORAL DE AUTH
  sp.auth.onAuthStateChange.listen((data) {
    debugPrint(
      'auth> event=${data.event} | hasSession=${data.session != null} | user=${data.session?.user.id}',
    );
  });

  // Rutas que SÍ requieren sesión (mundo barbero)
  const guardedPrefixes = <String>{
    '/hub_barbero',
    '/mis_barberias_tab',
    '/crear_barberia',
    '/gestion/turnos/generar',
    '/turnos_barbero',
    '/servicios_b',
    '/perfil_b', // prefijo (/perfil_b/:id)
  };


  _router = GoRouter(
    // 👇 la app del CLIENTE empieza aquí
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(sp.auth.onAuthStateChange),
    redirect: (context, state) {
      final session = sp.auth.currentSession;
      final path = state.uri.path; // <- usa uri.path (no subloc)

      final needsAuth = guardedPrefixes.any(
        (p) => path == p || path.startsWith('$p/'),
      );
      final isAuth = path == '/barbero/auth';

      // Sin sesión: deja navegar libre por el mundo cliente;
      // sólo forza login si intenta entrar a algo protegido.
      if (session == null && needsAuth)
       return '/barbero/auth';

      // Con sesión: si está en la pantalla de login, redirige al hub de barbero.
      if (session != null) 
      return '/hub_barbero';

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const PantallaInicio()),
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/barbero/auth',
        builder: (_, __) => const BarberAuthScreen(),
      ),

      // Mundo cliente (público)
      GoRoute(
        path: '/barberias',
        builder: (_, __) => const PantallaBarberias(),
      ),
      GoRoute(path: '/mapa', builder: (_, __) => const PantallaBarberiasMapa()),
      GoRoute(
        path: '/domicilio',
        builder: (_, __) => const PantallaDomicilioHub(),
      ),
      GoRoute(
        path: '/barberos_domicilio',
        builder: (_, __) => const PantallaBarberosDomicilio(),
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
          final serviceId = extra['service_id'] as int?;
          final barbershopId = extra['barbershop_id'] as int?;
          final durationMin = extra['duration_min'] as int? ?? 30;
          if (serviceId == null) {
            final loc = S.of(context)!;
            return Scaffold(body: Center(child: Text(loc.errorCargandoTurnos)));
          }
          return PantallaTurnosCliente(
            durationMin: durationMin,
            serviceId: serviceId,
            barbershopId: barbershopId,
          );
        },
      ),
      GoRoute(
        name: 'barbero',
        path: '/barbero/:id',
        builder:
            (context, state) =>
                PerfilBarberoPublic(barberId: state.pathParameters['id']!),
      ),

      // Mundo barbero (protegido)
      GoRoute(path: '/hub_barbero', builder: (_, __) => const HubBarbero()),
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
        builder: (_, __) => const PantallaGenerarTurnos(),
      ),
      GoRoute(
        path: '/turnos_barbero',
        builder: (_, __) => const PantallaTurnosBarbero(),
      ),
      GoRoute(
        path: '/servicios_b',
        builder: (_, __) => const ServiciosScreenBarber(),
      ),
      GoRoute(
        path: '/perfil_b/:barberId',
        name: 'perfilBarbero',
        builder:
            (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Mi perfil')),
              body: PerfilBarberoDomicilioYRedes(
                barberProfileId: state.pathParameters['barberId']!,
              ),
            ),
      ),
      GoRoute(
        path: '/servicios',
        builder: (context, state) {
          final extra = (state.extra as Map<String, dynamic>?) ?? const {};
          final barbershopId = extra['barbershopId'] as int?;
          return ServiciosScreen(barbershopId: barbershopId);
        },
      ),
      GoRoute(
        path: '/servicios_domicilio',
        builder: (_, __) => const ServiciosScreen(onlyHomeInitial: true),
      ),
    ],
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
        colorScheme: const ColorScheme.dark(
          primary: Color.fromARGB(255, 214, 7, 7),
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
