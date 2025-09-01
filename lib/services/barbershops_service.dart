import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BarbershopsService {
  static final _supa = Supabase.instance.client;

  // Crear barbería y quedar como OWNER
  static Future<int> crearBarberiaPropia({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required BuildContext context,
  }) async {
    final uid = _supa.auth.currentUser!.id;
    final messenger = ScaffoldMessenger.of(context);

    try {
      final shop = await _supa
          .from('barbershops')
          .insert({'name': name, 'address': address, 'lat': lat, 'lng': lng})
          .select('id')
          .single();

      final shopId = shop['id'] as int;

      // te transformás en OWNER de esa barbería
      await _supa.from('barbershop_members').insert({
        'barber_id': uid,
        'barbershop_id': shopId,
        'role': 'owner',
      });

      messenger.showSnackBar(const SnackBar(content: Text('Barbería creada')));
      return shopId;
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
      return -1;
    }
  }

  // Agregar staff por email (solo OWNER)
  static Future<void> agregarStaffPorEmail({
    required int shopId,
    required String email,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // buscá profile del barbero por email
      final prof = await _supa
          .from('profiles')
          .select('id')
          .ilike('email', email) // si guardás email en profiles, si no: busca en auth
          .maybeSingle();

      if (prof == null) throw 'No existe un usuario con ese email';

      await _supa.from('barbershop_members').insert({
        'barber_id': prof['id'],
        'barbershop_id': shopId,
        'role': 'staff',
      });

      messenger.showSnackBar(const SnackBar(content: Text('Staff agregado')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Quitar miembro (solo OWNER)
  static Future<void> quitarMiembro({
    required int shopId,
    required String barberId,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _supa
          .from('barbershop_members')
          .delete()
          .eq('barbershop_id', shopId)
          .eq('barber_id', barberId);

      messenger.showSnackBar(const SnackBar(content: Text('Miembro removido')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Eliminar/archivar barbería (recomendado: archivar)
  static Future<void> eliminarBarberia({
    required int shopId,
    required BuildContext context,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Duro: borrar. Mejor V2: tener columna is_active y hacer update.
      await _supa.from('barbershops').delete().eq('id', shopId);
      messenger.showSnackBar(const SnackBar(content: Text('Barbería eliminada')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Mis barberías (rol incluido)
  static Future<List<Map<String, dynamic>>> misBarberias() async {
    final uid = _supa.auth.currentUser!.id;
    final rows = await _supa
        .from('barbershop_members')
        .select('role, barbershop_id, barbershops(id,name,address,lat,lng)')
        .eq('barber_id', uid);
    return List<Map<String, dynamic>>.from(rows);
  }

   static Future<List<Map<String, dynamic>>> listarPublicas({
    String? q,                // texto a buscar (opcional)
    int limit = 100,          // límite
  }) async {
    var query = _supa
        .from('barbershops')
        .select('id, name, address, lat, lng')
        .order('name')
        .limit(limit);

    // if (q != null && q.trim().isNotEmpty) {
    //   // Búsqueda por nombre (podés sumar por address si querés)
    //   query = query.ilike('name', '%${q.trim()}%');
    // }

    final rows = await query;
    return (rows as List).cast<Map<String, dynamic>>();
  
  }
}
