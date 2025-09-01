import 'dart:async';

import 'package:flutter/material.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pantalla: Gestión de Servicios (Barbero)
/// - Lista con filtros
/// - Crear (una barbería / todas mis barberías / a domicilio)
/// - Editar / Duplicar / Borrar
/// - CTA "Generar turnos" si no hay slots futuros
///
/// Requisitos de BD asumidos:
///   services(id, barber_id(uuid), barbershop_id(bigint|null), name text,
///            duration_min int, price numeric, active bool,
///            home_service_surcharge numeric default 0)
///   barbershop_members(barber_id uuid, barbershop_id bigint, role enum)
///   barbershops(id bigint, name text)
///   time_slots(service_id bigint|null, status enum, starts_at timestamptz)
///
/// Notas:
/// - "Todas mis barberías" clona un servicio por cada barbería donde soy miembro.
/// - "A domicilio" => barbershop_id NULL (usa home_service_surcharge)
/// - Borrado: si hay citas (FK) mostrará mensaje y no eliminará.

class ServiciosScreenBarber extends StatefulWidget {
  const ServiciosScreenBarber({super.key});

  @override
  State<ServiciosScreenBarber> createState() => _ServiciosScreenBarberState();
}

enum AlcanceServicio { unaBarberia, todasMisBarberias, domicilio }

class _ServiciosScreenBarberState extends State<ServiciosScreenBarber> {
  final _supa = Supabase.instance.client;

  // Datos en memoria
  bool _loading = true;
  bool _soloActivos = true;
  int? _filtroBarbershopId; // null => Todas | -1 => A domicilio
  Map<int, String> _misBarberias = {}; // id -> nombre
  List<Map<String, dynamic>> _servicios = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await _loadMisBarberias();
      await _loadServicios();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cargando servicios: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMisBarberias() async {
    final uid = _supa.auth.currentUser!.id;
    final members = await _supa
        .from('barbershop_members')
        .select('barbershop_id')
        .eq('barber_id', uid);
    final ids = (members as List)
        .map((e) => e['barbershop_id'] as int)
        .toSet()
        .toList();
    if (ids.isEmpty) {
      _misBarberias = {};
      return;
    }
final shops = await _supa
    .from('barbershops')
    .select('id, name')
    .filter('id', 'in', '(${ids.join(',')})'); // <- funciona sin extensions
    _misBarberias = {
      for (final r in (shops as List)) r['id'] as int: (r['name'] as String)
    };
  }

Future<void> _loadServicios() async {
  final uid = _supa.auth.currentUser!.id;

  var qb = _supa
      .from('services')
      .select('id, barber_id, barbershop_id, name, duration_min, price, active, home_service_surcharge')
      .eq('barber_id', uid);

  if (_soloActivos) {
    qb = qb.eq('active', true);
  }

  if (_filtroBarbershopId == -1) {
    // A domicilio
    qb = qb.filter('barbershop_id', 'is', null);
  } else {
    // promoción nula segura
    final shopId = _filtroBarbershopId;
    if (shopId != null) {
      qb = qb.eq('barbershop_id', shopId);
    }
  }

  // no reasignamos qb a otro tipo
  final rows = await qb
      .order('active', ascending: false)
      .order('name');

  _servicios = List<Map<String, dynamic>>.from(rows as List);
}


  String _nombreBarberiaDe(int? barbershopId) {
    if (barbershopId == null) return 'A domicilio';
    return _misBarberias[barbershopId] ?? 'Barbería #$barbershopId';
  }

  Future<bool> _tieneSlotsFuturos(int serviceId) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final rows = await _supa
        .from('time_slots')
        .select('id')
        .eq('service_id', serviceId)
        .eq('status', 'free')
        .gte('starts_at', nowIso)
        .limit(1);
    return (rows as List).isNotEmpty;
  }

  Future<void> _crearOEditar({
    Map<String, dynamic>? original, // si viene => editar/duplicar
    bool duplicar = false,
  }) async {
    final result = await showModalBottomSheet<_ServicioFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ServicioFormSheet(
        misBarberias: _misBarberias,
        original: original,
        duplicar: duplicar,
      ),
    );
    if (result == null) return;

    try {
      if (result.alcance == AlcanceServicio.unaBarberia) {
        await _supa.from('services').insert({
          'barber_id': _supa.auth.currentUser!.id,
          'barbershop_id': result.barbershopId,
          'name': result.nombre,
          'duration_min': result.duracionMin,
          'price': result.precio,
          'active': result.activo,
          'home_service_surcharge': 0,
        });
      } else if (result.alcance == AlcanceServicio.todasMisBarberias) {
        if (_misBarberias.isEmpty) {
          throw 'No sos miembro de ninguna barbería';
        }
        final rows = _misBarberias.keys.map((sid) => {
              'barber_id': _supa.auth.currentUser!.id,
              'barbershop_id': sid,
              'name': result.nombre,
              'duration_min': result.duracionMin,
              'price': result.precio,
              'active': result.activo,
              'home_service_surcharge': 0,
            });
        await _supa.from('services').insert(rows.toList());
      } else {
        // domicilio
        await _supa.from('services').insert({
          'barber_id': _supa.auth.currentUser!.id,
          'barbershop_id': null,
          'name': result.nombre,
          'duration_min': result.duracionMin,
          'price': result.precio,
          'active': result.activo,
          'home_service_surcharge': result.recargoDomicilio ?? 0,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Servicio guardado')));
      }
      await _loadServicios();
      setState(() {});
    } on PostgrestException catch (e) {
      final msg = e.message ?? e.code ?? 'Error desconocido';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $msg')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
    }
  }

  Future<void> _borrarServicio(int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar servicio'),
        content: const Text('¿Seguro que querés eliminar este servicio?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await _supa.from('services').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Servicio eliminado')));
      }
      await _loadServicios();
      setState(() {});
    } on PostgrestException catch (e) {
      final msg = e.message ?? '';
      // Heurística: si hay citas/slots reservados, la FK o RLS suelen quejarse
      final friendly = (msg.contains('foreign key') || msg.contains('violates'))
          ? 'No se puede borrar porque tiene citas asociadas. Desactivá el servicio para ocultarlo.'
          : msg.isEmpty
              ? 'No se pudo borrar (permiso o restricción)'
              : msg;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendly)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo borrar: $e')),
      );
    }
  }

  void _irAGenerarTurnos(Map<String, dynamic> s) async {
    // Integrá con tu pantalla de generar turnos.
    // Por ejemplo: Navigator.pushNamed(context, '/generarTurnos', arguments: {...})
    // Dejo un snackbar para que no rompa si aún no está el route.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Integrar navegación a "Generar turnos"')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Servicios'),
        actions: [
          // Filtro activos
          Row(children: [
            const Text('Activos'),
            Switch(
              value: _soloActivos,
              onChanged: (v) async {
                setState(() => _soloActivos = v);
                await _loadServicios();
                if (mounted) setState(() {});
              },
            ),
          ]),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _filtroBarbershopId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Filtro barbería'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todas')),
                      const DropdownMenuItem(value: -1, child: Text('A domicilio')),
                      ..._misBarberias.entries.map((e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          )),
                    ],
                    onChanged: (v) async {
                      setState(() => _filtroBarbershopId = v);
                      await _loadServicios();
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Recargar',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _servicios.isEmpty
                    ? const Center(child: Text('No tenés servicios aún.'))
                    : ListView.builder(
                        itemCount: _servicios.length,
                        itemBuilder: (_, i) => _ServicioCard(
                          servicio: _servicios[i],
                          nombreBarberia: _nombreBarberiaDe(_servicios[i]['barbershop_id'] as int?),
                          onEditar: () => _crearOEditar(original: _servicios[i]),
                          onDuplicar: () => _crearOEditar(original: _servicios[i], duplicar: true),
                          onBorrar: () => _borrarServicio(_servicios[i]['id'] as int),
                          onGenerarTurnos: () => _irAGenerarTurnos(_servicios[i]),
                          tieneSlotsFuturos: () => _tieneSlotsFuturos(_servicios[i]['id'] as int),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _crearOEditar(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo servicio'),
      ),
    );
  }
}

class _ServicioCard extends StatefulWidget {
  final Map<String, dynamic> servicio;
  final String nombreBarberia;
  final VoidCallback onEditar;
  final VoidCallback onDuplicar;
  final VoidCallback onBorrar;
  final VoidCallback onGenerarTurnos;
  final Future<bool> Function() tieneSlotsFuturos;

  const _ServicioCard({
    required this.servicio,
    required this.nombreBarberia,
    required this.onEditar,
    required this.onDuplicar,
    required this.onBorrar,
    required this.onGenerarTurnos,
    required this.tieneSlotsFuturos,
  });

  @override
  State<_ServicioCard> createState() => _ServicioCardState();
}

class _ServicioCardState extends State<_ServicioCard> {
  bool _checkingSlots = false;
  bool _hasSlots = true;

  @override
  void initState() {
    super.initState();
    _checkSlots();
  }

  Future<void> _checkSlots() async {
    setState(() => _checkingSlots = true);
    try {
      _hasSlots = await widget.tieneSlotsFuturos();
    } finally {
      if (mounted) setState(() => _checkingSlots = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.servicio;
    final activo = s['active'] as bool? ?? true;
    final isHome = s['barbershop_id'] == null;
    final precio = (s['price'] as num).toDouble();
    final recargo = (s['home_service_surcharge'] as num?)?.toDouble() ?? 0;

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    s['name'] as String,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (!activo)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Chip(label: Text('Inactivo')),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(isHome
                      ? 'A domicilio'
                      : 'Shop: ${widget.nombreBarberia}'),
                ),
                Chip(label: Text('${s['duration_min']} min')),
                Chip(label: Text('UYU ${precio.toStringAsFixed(0)}')),
                if (isHome && recargo > 0)
                  Chip(label: Text('+ Recargo ${recargo.toStringAsFixed(0)}')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onEditar,
                  icon: const Icon(Icons.edit),
                  label: const Text('Editar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.onDuplicar,
                  icon: const Icon(Icons.copy),
                  label: const Text('Duplicar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: widget.onBorrar,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Borrar'),
                ),
                const Spacer(),
                if (_checkingSlots)
                  const Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (!_hasSlots)
                  FilledButton.icon(
                    onPressed: widget.onGenerarTurnos,
                    icon: const Icon(Icons.event_available),
                    label: const Text('Generar turnos'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ====== Sheet de creación/edición ======

class ServicioFormSheet extends StatefulWidget {
  final Map<int, String> misBarberias;
  final Map<String, dynamic>? original;
  final bool duplicar;

  const ServicioFormSheet({
    super.key,
    required this.misBarberias,
    this.original,
    this.duplicar = false,
  });

  @override
  State<ServicioFormSheet> createState() => _ServicioFormSheetState();
}

class _ServicioFormSheetState extends State<ServicioFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _precioCtrl = TextEditingController(text: '0');
  final _recargoCtrl = TextEditingController(text: '0');
  int _duracion = 30;
  bool _activo = true;
  AlcanceServicio _alcance = AlcanceServicio.unaBarberia;
  int? _barbershopId;

  @override
  void initState() {
    super.initState();
    final o = widget.original;
    if (o != null) {
      _nameCtrl.text = (o['name'] as String?) ?? '';
      _duracion = (o['duration_min'] as int?) ?? 30;
      _precioCtrl.text = ((o['price'] as num?)?.toString() ?? '0');
      _activo = (o['active'] as bool?) ?? true;
      final isHome = o['barbershop_id'] == null;
      if (isHome) {
        _alcance = AlcanceServicio.domicilio;
        _recargoCtrl.text = ((o['home_service_surcharge'] as num?)?.toString() ?? '0');
      } else {
        _alcance = AlcanceServicio.unaBarberia;
        _barbershopId = o['barbershop_id'] as int?;
      }
      if (widget.duplicar) {
        // Cuando duplicamos, mantenemos valores pero no el id.
      }
    } else {
      // Defaults: si no hay barberías, por defecto a domicilio.
      if (widget.misBarberias.isEmpty) {
        _alcance = AlcanceServicio.domicilio;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _precioCtrl.dispose();
    _recargoCtrl.dispose();
    super.dispose();
  }

  List<int> _duracionesValidas() {
    final out = <int>[];
    for (int m = 15; m <= 720; m += 15) out.add(m);
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.original == null
                      ? 'Nuevo servicio'
                      : (widget.duplicar ? 'Duplicar servicio' : 'Editar servicio'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej: Corte clásico',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ingresá un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _duracion,
                      decoration: const InputDecoration(labelText: 'Duración (min)'),
                      items: _duracionesValidas()
                          .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                          .toList(),
                      onChanged: (v) => setState(() => _duracion = v ?? 30),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Precio (UYU)'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Ingresá un precio';
                        final n = double.tryParse(v.replaceAll(',', '.'));
                        if (n == null || n < 0) return 'Precio inválido';
                        return null;
                      },
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _activo,
                  onChanged: (v) => setState(() => _activo = v),
                  title: const Text('Activo'),
                ),
                const SizedBox(height: 8),
                const Text('Vinculación'),
                const SizedBox(height: 6),
                RadioListTile<AlcanceServicio>(
                  value: AlcanceServicio.unaBarberia,
                  groupValue: _alcance,
                  onChanged: (v) => setState(() => _alcance = v!),
                  title: const Text('Una barbería'),
                ),
                if (_alcance == AlcanceServicio.unaBarberia)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8, bottom: 8),
                    child: DropdownButtonFormField<int>(
                      value: _barbershopId,
                      decoration: const InputDecoration(labelText: 'Barbería'),
                      items: widget.misBarberias.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                          .toList(),
                      onChanged: (v) => setState(() => _barbershopId = v),
                      validator: (_) => _barbershopId == null ? 'Elegí una barbería' : null,
                    ),
                  ),
                RadioListTile<AlcanceServicio>(
                  value: AlcanceServicio.todasMisBarberias,
                  groupValue: _alcance,
                  onChanged: widget.misBarberias.isEmpty
                      ? null
                      : (v) => setState(() => _alcance = v!),
                  title: const Text('Todas mis barberías'),
                  subtitle: widget.misBarberias.isEmpty
                      ? const Text('No sos miembro de barberías')
                      : Text('${widget.misBarberias.length} barberías'),
                ),
                RadioListTile<AlcanceServicio>(
                  value: AlcanceServicio.domicilio,
                  groupValue: _alcance,
                  onChanged: (v) => setState(() => _alcance = v!),
                  title: const Text('A domicilio'),
                ),
                if (_alcance == AlcanceServicio.domicilio)
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8, bottom: 8),
                    child: TextFormField(
                      controller: _recargoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Recargo domicilio (UYU)'),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return null; // opcional
                        final n = double.tryParse(t.replaceAll(',', '.'));
                        if (n == null || n < 0) return 'Monto inválido';
                        return null;
                      },
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nameCtrl.text.trim();
    final precio = double.parse(_precioCtrl.text.replaceAll(',', '.'));
    final double? recargo = _alcance == AlcanceServicio.domicilio
        ? double.tryParse(_recargoCtrl.text.replaceAll(',', '.')) ?? 0
        : null;

    final result = _ServicioFormResult(
      nombre: nombre,
      duracionMin: _duracion,
      precio: precio,
      activo: _activo,
      alcance: _alcance,
      barbershopId: _alcance == AlcanceServicio.unaBarberia ? _barbershopId : null,
      recargoDomicilio: recargo,
    );

    Navigator.pop(context, result);
  }
}

class _ServicioFormResult {
  final String nombre;
  final int duracionMin;
  final double precio;
  final bool activo;
  final AlcanceServicio alcance;
  final int? barbershopId;
  final double? recargoDomicilio;

  _ServicioFormResult({
    required this.nombre,
    required this.duracionMin,
    required this.precio,
    required this.activo,
    required this.alcance,
    this.barbershopId,
    this.recargoDomicilio,
  });
}
