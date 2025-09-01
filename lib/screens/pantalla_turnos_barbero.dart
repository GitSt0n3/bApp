import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:postgrest/postgrest.dart';
import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/text_styles.dart';
import 'package:barberiapp/core/button_styles.dart';
// import 'package:barberiapp/services/appointments_service.dart';

class PantallaTurnosBarbero extends StatefulWidget {
  const PantallaTurnosBarbero({super.key});

  @override
  State<PantallaTurnosBarbero> createState() => _PantallaTurnosBarberoState();
}

class ClientContact {
  final String name;
  final String? phone;
  final String? email;
  const ClientContact({required this.name, this.phone, this.email});
}

Future<ClientContact?> fetchGuestContactForSlotId(int slotId) async {
  final sb = Supabase.instance.client;

  final row =
      await sb
          .from('appointment_slots')
          .select('appointments(contact_name, contact_phone, contact_email)')
          .eq('slot_id', slotId)
          .maybeSingle();

  if (row == null) return null;
  final appt = row['appointments'] as Map<String, dynamic>?;

  final name = (appt?['contact_name'] as String?)?.trim();
  return ClientContact(
    name: (name != null && name.isNotEmpty) ? name : 'Invitado',
    phone: appt?['contact_phone'] as String?,
    email: appt?['contact_email'] as String?,
  );
}

class _PantallaTurnosBarberoState extends State<PantallaTurnosBarbero> {
  final _supa = Supabase.instance.client;

  bool _loading = true;
  bool _onlyHome = false;
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now().add(const Duration(days: 14));

  int? _barbershopId; // null = todas
  List<Map<String, dynamic>> _misBarberias = [];
  List<Map<String, dynamic>> _slots = [];

  int? _apptId(Map<String, dynamic> s) {
    final list = s['appointment_slots'] as List<dynamic>?;
    if (list == null || list.isEmpty) return null;
    return list.first['appointment_id'] as int?;
  }

  ClientContact? _selectedClient; // guarda el cliente actual consultado
  Map<String, dynamic>?
  _selectedSlot; // si querés guardar también el slot tocado

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  void _showClientSheet(BuildContext context, ClientContact c) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true, // importante para que el scroll funcione bien
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4, // tamaño inicial (40% de la pantalla)
          minChildSize: 0.3, // mínimo al arrastrar hacia abajo
          maxChildSize: 0.9, // máximo al arrastrar hacia arriba
          builder: (_, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos del cliente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.name,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  if (c.phone != null && c.phone!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Tel: ${c.phone}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  if (c.email != null && c.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Email: ${c.email}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _bootstrap() async {
    await _cargarMisBarberias();
    await _cargarSlots();
  }

  Future<void> _cargarMisBarberias() async {
    try {
      final uid = _supa.auth.currentUser!.id;
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
      // si no hay members, no rompas: deja vacío
      setState(() => _misBarberias = []);
    }
  }

  Future<void> _cargarSlots() async {
    setState(() => _loading = true);
    try {
      final uid = _supa.auth.currentUser!.id;

      var query = _supa
          .from('time_slots')
          .select(
            'id, barber_id, starts_at, ends_at, status, is_home_service, '
            'barbershop_id, barbershops(name),'
            'appointment_slots(appointment_id)',
          )
          .eq('barber_id', uid)
          .gte('starts_at', _from.toIso8601String())
          .lte('starts_at', _to.toIso8601String());

      if (_onlyHome) {
        query = query
            .filter('barbershop_id', 'is', null)
            .eq('is_home_service', true);
      } else {
        final shopId = _barbershopId;
        if (shopId != null) {
          query = query.eq('barbershop_id', shopId);
          // o incluir también genéricos:
          // query = query.or('barbershop_id.eq.$shopId,barbershop_id.is.null');
        }
      }

      final rows = await query.order('starts_at', ascending: true);
      if (!mounted) return;

      setState(() => _slots = (rows as List).cast<Map<String, dynamic>>());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // UI helpers
  String _fmtDay(DateTime d) => DateFormat('EEE d MMM', 'es').format(d);
  String _fmtTime(DateTime d) => DateFormat('HH:mm').format(d);
  Color _statusColor(String s) {
    switch (s) {
      case 'free':
        return Colors.greenAccent;
      case 'blocked':
        return Colors.amberAccent;
      case 'booked':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 31)),
      helpText: 'Desde',
    );
    if (picked != null) {
      setState(() => _from = DateTime(picked.year, picked.month, picked.day));
      await _cargarSlots();
    }
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 31)),
      helpText: 'Hasta',
    );
    if (picked != null) {
      setState(
        () => _to = DateTime(picked.year, picked.month, picked.day, 23, 59),
      );
      await _cargarSlots();
    }
  }

  Future<void> _toggleEstado(Map<String, dynamic> slot) async {
    final id = slot['id'] as int;
    final status = slot['status'] as String;
    if (status == 'booked') return;

    final nuevo = status == 'free' ? 'blocked' : 'free';
    try {
      await _supa.from('time_slots').update({'status': nuevo}).eq('id', id);
      setState(() {
        final i = _slots.indexWhere((s) => s['id'] == id);
        if (i >= 0) _slots[i]['status'] = nuevo;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar el estado: $e')),
      );
    }
  }

  Future<void> _toggleEstadoRun(Map<String, dynamic> run) async {
    final String status = run['status'] as String;
    if (status == 'booked') return; // no tocar reservas

    final String nuevo = (status == 'free') ? 'blocked' : 'free';
    final uid = _supa.auth.currentUser!.id;

    // Aseguramos mismas referencias temporales que guardaste en el run
    final DateTime start = run['start'] as DateTime;
    final DateTime end = run['end'] as DateTime;

    // Si tu BD guarda timestamptz en UTC, convertí a UTC antes de enviar
    final startIso = start.toUtc().toIso8601String();
    final endIso = end.toUtc().toIso8601String();

    try {
      // Actualizo TODOS los slots del barbero en ese rango con el mismo status actual
      await _supa
          .from('time_slots')
          .update({'status': nuevo})
          .eq('barber_id', uid)
          .gte('starts_at', startIso)
          .lte('ends_at', endIso)
          .eq('status', status); // <-- evita tocar booked u otros estados

      // Refresco estado local para que la UI cambie sin re-consultar
      setState(() {
        for (final s in _slots) {
          final st = DateTime.parse(s['starts_at'] as String);
          final en = DateTime.parse(s['ends_at'] as String);
          final stLoc = st.isUtc ? st.toLocal() : st;
          final enLoc = en.isUtc ? en.toLocal() : en;

          final dentro =
              (stLoc.isAtSameMomentAs(start) || stLoc.isAfter(start)) &&
              (enLoc.isAtSameMomentAs(end) || enLoc.isBefore(end));

          if (dentro && (s['status'] == status)) {
            s['status'] = nuevo;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar el estado del bloque: $e')),
      );
    }
  }

  Map<DateTime, List<Map<String, dynamic>>> _groupByDay(
    List<Map<String, dynamic>> rows,
  ) {
    final map = <DateTime, List<Map<String, dynamic>>>{};

    for (final r in rows) {
      final parsed = DateTime.parse(r['starts_at'] as String);
      final dt = parsed.isUtc ? parsed.toLocal() : parsed; // <- clave
      final dayKey = DateTime(dt.year, dt.month, dt.day);
      (map[dayKey] ??= []).add(r);
    }

    final sortedKeys = map.keys.toList()..sort();

    return {
      for (final k in sortedKeys)
        k:
            (map[k]!..sort((a, b) {
              final aDt = DateTime.parse(a['starts_at'] as String);
              final bDt = DateTime.parse(b['starts_at'] as String);
              final aLoc = aDt.isUtc ? aDt.toLocal() : aDt;
              final bLoc = bDt.isUtc ? bDt.toLocal() : bDt;
              return aLoc.compareTo(bLoc);
            })),
    };
  }

  List<Map<String, dynamic>> _compactRuns(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return [];

    final sorted = [...rows]..sort(
      (a, b) => DateTime.parse(
        a['starts_at'],
      ).compareTo(DateTime.parse(b['starts_at'])),
    );

    final out = <Map<String, dynamic>>[];

    Map<String, dynamic>? cur; // run actual

    for (final r in sorted) {
      final start = DateTime.parse(r['starts_at'] as String);
      final end = DateTime.parse(r['ends_at'] as String);
      final status = r['status'] as String;
      final apptId = _apptId(r);
      final isHome = (r['is_home_service'] as bool?) ?? false;
      final shop = r['barbershops'];

      if (cur == null) {
        cur = {
          'start': start,
          'end': end,
          'status': status,
          'appointment_id': apptId,
          'is_home_service': isHome,
          'barbershops': shop,
          'slot_id_first': r['id'],
          'slot_id_last': r['id'],
        };
        out.add(cur);
        continue;
      }

      final prevEnd = cur['end'] as DateTime;
      final sameStatus = (cur['status'] == status);
      final contiguous = start.isAtSameMomentAs(prevEnd);
      final sameAppt =
          (status == 'booked') ? (cur['appointment_id'] == apptId) : true;
      final samePlace =
          (cur['is_home_service'] == isHome) &&
          ((cur['barbershops']?['name']) == (shop?['name']));

      if (sameStatus && contiguous && sameAppt && samePlace) {
        // Extiendo el run
        cur['end'] = end;
        cur['slot_id_last'] = r['id'];
      } else {
        // Nuevo run
        cur = {
          'start': start,
          'end': end,
          'status': status,
          'appointment_id': apptId,
          'is_home_service': isHome,
          'barbershops': shop,
          'slot_id_first': r['id'],
          'slot_id_last': r['id'],
        };
        out.add(cur);
      }
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDay(_slots);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.appBarbkgs,
        title: Text('Turnos', style: TextStyles.tittleText),
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: _Filtros(
              from: _from,
              to: _to,
              onlyHome: _onlyHome,
              barbershopId: _barbershopId,
              misBarberias: _misBarberias,
              onChangeFrom: () => _pickFrom(),
              onChangeTo: () => _pickTo(),
              onToggleHome: (v) async {
                setState(() => _onlyHome = v);
                await _cargarSlots();
              },
              onChangeShop: (int? id) async {
                setState(() => _barbershopId = id);
                await _cargarSlots();
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : grouped.isEmpty
                    ? Center(
                      child: Text(
                        'Sin turnos en el rango seleccionado',
                        style: TextStyles.defaultText,
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: grouped.length,
                      itemBuilder: (_, i) {
                        final day = grouped.keys.elementAt(i);
                        final items = grouped[day]!;
                        final runs = _compactRuns(items);
                        return _DiaSection(
                          titulo: _fmtDay(day),
                          children:
                              runs
                                  .map(
                                    (run) => _SlotTile(
                                      startsAt: run['start'] as DateTime,
                                      endsAt: run['end'] as DateTime,
                                      status: run['status'] as String,
                                      isHome:
                                          (run['is_home_service'] as bool?) ??
                                          false,
                                      barbershopName:
                                          (run['barbershops']?['name'])
                                              as String?,
                                      statusColor: _statusColor(
                                        run['status'] as String,
                                      ),

                                      // 🔁 Bloquear / liberar TODO el bloque
                                      onToggle: () => _toggleEstadoRun(run),

                                      // 👇 Si es reserva, muestro al cliente usando el primer slot del bloque
                                      onTap: () async {
                                        if ((run['status'] as String) ==
                                            'booked') {
                                          final client =
                                              await fetchGuestContactForSlotId(
                                                run['slot_id_first'] as int,
                                              );
                                          if (!context.mounted ||
                                              client == null)
                                            return;
                                          _showClientSheet(context, client);
                                        }
                                      },
                                    ),
                                  )
                                  .toList(),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor:
            AppColors.accent, // si querés rojo, cambia por tu color
        icon: const Icon(Icons.auto_fix_high),
        label: const Text('Generar'),
        onPressed: () async {
          final res = await context.push('/gestion/turnos/generar');
          if (res == true) await _cargarSlots();
        },
      ),
    );
  }
}

/// ---------- Widgets de UI (estilo BarberiApp) ----------

class _Filtros extends StatelessWidget {
  final DateTime from;
  final DateTime to;
  final bool onlyHome;
  final int? barbershopId;
  final List<Map<String, dynamic>> misBarberias;
  final VoidCallback onChangeFrom;
  final VoidCallback onChangeTo;
  final ValueChanged<bool> onToggleHome;
  final ValueChanged<int?> onChangeShop;

  const _Filtros({
    required this.from,
    required this.to,
    required this.onlyHome,
    required this.barbershopId,
    required this.misBarberias,
    required this.onChangeFrom,
    required this.onChangeTo,
    required this.onToggleHome,
    required this.onChangeShop,
  });

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rango de fechas
        Row(
          children: [
            Expanded(
              child: FilledButton(
                style: ButtonStyles.redButton,
                onPressed: onChangeFrom,
                child: Text('Desde: ${df.format(from)}'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: ButtonStyles.redButton,
                onPressed: onChangeTo,
                child: Text('Hasta: ${df.format(to)}'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Domicilio y Barbería
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                value: onlyHome,
                onChanged: onToggleHome,
                title: Text('A domicilio', style: TextStyles.defaultText),
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.redAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                value: barbershopId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Barbería',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Todas'),
                  ),
                  ...misBarberias.map(
                    (s) => DropdownMenuItem<int?>(
                      value: s['id'] as int,
                      child: Text(s['name'] as String),
                    ),
                  ),
                ],
                onChanged: onChangeShop,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DiaSection extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _DiaSection({required this.titulo, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.backgroundComponent,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(titulo, style: TextStyles.tittleText),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: children,
      ),
    );
  }
}

class _SlotTile extends StatelessWidget {
  final DateTime startsAt;
  final DateTime endsAt;
  final String status; // free | blocked | booked
  final bool isHome;
  final String? barbershopName;
  final VoidCallback onToggle;
  final Color statusColor;
  final VoidCallback? onTap;

  const _SlotTile({
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.isHome,
    required this.barbershopName,
    required this.onToggle,
    required this.statusColor,
    this.onTap,
    super.key,
  });

  String _fmt(DateTime d) => DateFormat('HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    final isBooked = status == 'booked';
    final icon = isHome ? Icons.house : Icons.store;
    final place = isHome ? 'A domicilio' : (barbershopName ?? 'Barbería');

    final w = MediaQuery.of(context).size.width;
    final isSmall = w < 380;

    final radius = BorderRadius.circular(12);

    return Material(
      // <- necesario para el ripple del InkWell
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: isBooked ? onTap : null, // <- solo activo si está reservado
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.backgroundComponent,
            borderRadius: radius,
            border: Border.all(color: Colors.black26),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // IZQ: hora + lugar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fmt(startsAt)} – ${_fmt(endsAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.buttonText.copyWith(
                        fontSize: isSmall ? 14 : 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(icon, size: 16),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.defaultText.copyWith(
                              fontSize: isSmall ? 13 : 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // CENTRO: chip de estado
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 110),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      border: Border.all(color: statusColor),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyles.defaultText.copyWith(
                        fontSize: isSmall ? 11 : 12,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // DER: botón
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: SizedBox(
                  height: 40,
                  child: FilledButton(
                    style: ButtonStyles.redButton,
                    onPressed: isBooked ? null : onToggle,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        isBooked
                            ? 'Reservado'
                            : (status == 'free' ? 'Bloquear' : 'Liberar'),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
