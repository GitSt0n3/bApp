import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class AuthService {
  static final _supa = Supabase.instance.client;

  static Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _supa.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      messenger.showSnackBar(const SnackBar(content: Text('Login OK')));
      if (context.mounted) context.go('/hub_barbero');
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  static Future<void> registerBarberBasico({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    bool homeService = false,
    required BuildContext context,
  }) async {
    final supa = Supabase.instance.client;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await supa.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': nombre, 'phone': telefono},
      );
      final user = res.user;
      if (user == null) throw Exception('No se pudo crear el usuario');

      await supa.from('profiles').insert({
        'id': user.id,
        'role': 'barber',
        'full_name': nombre,
        'phone': telefono,
      });

      await supa.from('barbers').insert({
        'profile_id': user.id,
        'bio': nombre,
        'home_service': homeService,
        'radius_km': 8,
      });

      messenger.showSnackBar(const SnackBar(content: Text('Registro OK')));
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
      rethrow;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      rethrow;
    }
  }

  static Future<void> registerBarber({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required bool domicilio,
    required double lat,
    required double lng,
    required String direccion,
    required String nombreBarberia,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await _supa.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {'full_name': nombre, 'phone': telefono},
      );
      final user = res.user;
      if (user == null) throw Exception('No se pudo crear el usuario');

      await _supa.from('profiles').insert({
        'id': user.id,
        'role': 'barber',
        'full_name': nombre,
        'phone': telefono,
      });

      final barber = await _supa.from('barbers').insert({
        'profile_id': user.id,
        'bio': nombre,
        'home_service': domicilio,
        'radius_km': 8,
      });

      final shop =
          await _supa
              .from('barbershops')
              .insert({
                'name': nombreBarberia,
                'address': direccion,
                'lat': lat,
                'lng': lng,
              })
              .select('id')
              .single();

      await _supa.from('barber_barbershop').insert({
        'barber_id': user.id,
        'barbershop_id': shop['id'],
      });

      messenger.showSnackBar(const SnackBar(content: Text('Registro OK')));
    } on AuthException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
