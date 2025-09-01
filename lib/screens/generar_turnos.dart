import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaGenerarTurnos extends StatefulWidget {
  const PantallaGenerarTurnos({super.key});

  @override
  State<PantallaGenerarTurnos> createState() => _PantallaGenerarTurnosState();
}

class _PantallaGenerarTurnosState extends State<PantallaGenerarTurnos> {
  final _supa = Supabase.instance.client;

  bool _esDomicilio = false;
  int? _barbershopId; // null si es a domicilio
  TimeOfDay _inicio = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _fin    = const TimeOfDay(hour: 18, minute: 0);
  int _duracion = 30; // >= 30
  int _dias = 14;     // 1..31
  bool _loading = false;

  List<Map<String, dynamic>> _misBarberias = [];

  @override
  void initState() {
    super.initState();
    _cargarMisBarberias();
  }

  Future<void> _cargarMisBarberias() async {
    try {
      final uid = _supa.auth.currentUser!.id;

      // Si tenés barbershop_members, preferirla. Si no, usar barbershop legacy.
      final rows = await _supa
          .from('barbershop_members')
          .select('barbershops(id,name)')
          .eq('barber_id', uid);

      final shops = <Map<String, dynamic>>[];
      for (final r in (rows as List)) {
        final shop = r['barbershops'];
        if (shop != null) shops.add(Map<String, dynamic>.from(shop));
      }
      setState(() => _misBarberias = shops);
    } catch (_) {
      final rows = await _supa
          .from('barbershops')
          .select('id,name')
          .order('name');
      setState(() => _misBarberias = (rows as List).cast<Map<String, dynamic>>());
    }
  }

  Future<void> _pickHoraInicio() async {
    final t = await showTimePicker(context: context, initialTime: _inicio);
    if (t != null) setState(() => _inicio = t);
  }

  Future<void> _pickHoraFin() async {
    final t = await showTimePicker(context: context, initialTime: _fin);
    if (t != null) setState(() => _fin = t);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _generar() async {
    // Validaciones UI
    if (!_esDomicilio && _barbershopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una barbería o marca "A domicilio".')),
      );
      return;
    }
    if (_duracion < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La duración mínima es 30 minutos.')),
      );
      return;
    }
    if (_dias < 1 || _dias > 31) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los días deben estar entre 1 y 31.')),
      );
      return;
    }
    final iniMins = _inicio.hour * 60 + _inicio.minute;
    final finMins = _fin.hour * 60 + _fin.minute;
    if (finMins - iniMins < _duracion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El tramo horario diario no alcanza para un turno.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final uid = _supa.auth.currentUser!.id;

      final params = {
        'p_barber': uid,
        'p_shop': _esDomicilio ? null : _barbershopId,
        'p_service': null, // opcional si luego agregamos servicios
        'p_day_start': _fmt(_inicio),  // 'HH:mm'
        'p_day_end': _fmt(_fin),
        'p_minutes': _duracion,        // >= 30
        'p_days': _dias,               // <= 31
      };

      await _supa.rpc('generate_slots', params: params);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turnos generados 👌')),
      );
      Navigator.pop(context, true); // -> para refrescar la lista
    } on PostgrestException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar turnos')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('A domicilio'),
            value: _esDomicilio,
            onChanged: (v) => setState(() {
              _esDomicilio = v;
              if (v) _barbershopId = null;
            }),
          ),
          if (!_esDomicilio)
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: 'Barbería'),
              value: _barbershopId,
              items: _misBarberias
                  .map((s) => DropdownMenuItem(
                        value: s['id'] as int,
                        child: Text(s['name'] as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _barbershopId = v),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Inicio'),
                  subtitle: Text(_fmt(_inicio)),
                  trailing: const Icon(Icons.schedule),
                  onTap: _pickHoraInicio,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fin'),
                  subtitle: Text(_fmt(_fin)),
                  trailing: const Icon(Icons.schedule),
                  onTap: _pickHoraFin,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: 'Duración del turno (min)'),
            value: _duracion,
            items: const [30, 45, 60, 90, 120]
                .map((m) => DropdownMenuItem(value: m, child: Text('$m')))
                .toList(),
            onChanged: (v) => setState(() => _duracion = v ?? 30),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Días a generar (1-31)',
              helperText: 'Máximo 31 días para controlar la suscripción mensual',
            ),
            initialValue: '14',
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final n = int.tryParse(v) ?? 14;
              _dias = n.clamp(1, 31);
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading ? null : _generar,
            icon: _loading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_fix_high),
            label: const Text('Generar'),
          ),
        ],
      ),
    );
  }
}
