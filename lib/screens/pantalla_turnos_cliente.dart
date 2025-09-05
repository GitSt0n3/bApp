import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../generated/l10n.dart';


class PantallaTurnosCliente extends StatefulWidget {
  final int serviceId;
  final int durationMin;
  final int? barbershopId; // null = a domicilio o genérico

  const PantallaTurnosCliente({
    super.key,
    required this.serviceId,
    required this.durationMin,
    this.barbershopId,
  });

  @override
  State<PantallaTurnosCliente> createState() => _PantallaTurnosClienteState();
}

class _PantallaTurnosClienteState extends State<PantallaTurnosCliente> {
  final formKey = GlobalKey<FormState>();
  final _supa = Supabase.instance.client;
  bool _loading = true;

  // Resultado: propuestas de turnos “armados” (k slots)
  final List<_PropuestaTurno> _propuestas = [];

  final _fmtDay = DateFormat('EEE d/MM', 'es');
  final _fmtHour = DateFormat('HH:mm');

  @override
  void initState() {
    super.initState();
    _cargarTurnos();
  }

  Future<void> _cargarTurnos() async {
    try {
      setState(() {
        _loading = true;
        _propuestas.clear();
      });

      final now = DateTime.now().toUtc();
      final to = now.add(const Duration(days: 14)).toUtc();

      // Traemos slots libres entre hoy y +14 días.
      var query = _supa
          .from('time_slots')
          .select(
            'id,barber_id,barbershop_id,barbershops(id,name,address,lat,lng),service_id,starts_at,ends_at,is_home_service,status',
          )
          .eq('status', 'free')
          .gte('starts_at', now.toIso8601String())
          .lte('starts_at', to.toIso8601String());

      // Filtro barbería / domicilio
      final shopId = widget.barbershopId; // promoción nula segura
      if (shopId != null) {
        query = query.eq('barbershop_id', shopId);
      } else {
        query = query.filter(
          'barbershop_id',
          'is',
          null,
        ); // domicilio / genérico
      }

      // Preferir service_id = seleccionado pero permitir genéricos (NULL)
      query = query.or('service_id.eq.${widget.serviceId},service_id.is.null');

      final rows = await query
          .order('barber_id', ascending: true)
          .order('starts_at', ascending: true);

      final slots =
          (rows as List)
              .map((e) => _Slot.fromMap(e as Map<String, dynamic>))
              .toList();

      // Agrupar por barber y por día; buscar secuencias contiguas de tamaño k
      final k = ((widget.durationMin + 29) ~/ 30); // slots de 30m
      final propuestas = _armarPropuestas(slots, k);

      setState(() => _propuestas.addAll(propuestas));
    } catch (e) {
      if (mounted) {
        final loc = S.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error cargando turnos: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_PropuestaTurno> _armarPropuestas(List<_Slot> slots, int k) {
    // Asumimos slots contiguos cuando next.starts_at == prev.ends_at
    // Agrupamos por barber_id + día (UTC)
    final Map<String, List<_Slot>> groups = {};
    for (final s in slots) {
      final dayKey = DateTime.utc(
        s.startsAt.year,
        s.startsAt.month,
        s.startsAt.day,
      );
      final key = '${s.barberId}::$dayKey';
      groups.putIfAbsent(key, () => []).add(s);
    }

    final List<_PropuestaTurno> res = [];
    groups.forEach((_, list) {
      list.sort((a, b) => a.startsAt.compareTo(b.startsAt));
      int i = 0;
      while (i < list.length) {
        int j = i;
        while (j + 1 < list.length &&
            list[j + 1].startsAt.isAtSameMomentAs(list[j].endsAt)) {
          j++;
        }
        final runLen = j - i + 1;
        if (runLen >= k) {
          for (int base = i; base + k - 1 <= j; base++) {
            final chunk = list.sublist(base, base + k);
            res.add(
              _PropuestaTurno(
                slotIds: chunk.map((e) => e.id).toList(),
                barberId: chunk.first.barberId,
                barbershopId: chunk.first.barbershopId,
                barbershopName: chunk.first.barbershopName,
                startsAt: chunk.first.startsAt,
                endsAt: chunk.last.endsAt,
              ),
            );
          }
        }
        i = j + 1;
      }
    });

    res.sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return res;
  }

  // ========= Reserva tipo "guest" (sin login) =========
  Future<_ContactoGuest?> _pedirContacto() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    return showModalBottomSheet<_ContactoGuest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true, // si tu versión de Flutter lo soporta
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) {
            return SingleChildScrollView(
              controller: scrollCtrl,
              padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tus datos para la reserva',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl, // controllers definidos en el State
                      decoration: const InputDecoration(
                        labelText: 'Nombre y apellido',
                      ),
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Ingresá tu nombre'
                                  : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Celular'),
                      keyboardType: TextInputType.phone,
                      validator:
                          (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Ingresá tu celular'
                                  : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email (opcional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              Navigator.pop(
                                ctx,
                                _ContactoGuest(
                                  nameCtrl.text.trim(),
                                  phoneCtrl.text.trim(),
                                  emailCtrl.text.trim(),
                                ),
                              );
                            }
                          },
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reservar(_PropuestaTurno p) async {
    try {
      _ContactoGuest? contacto;
      final user = _supa.auth.currentUser;

      contacto = await _pedirContacto();
      if (contacto == null) return; // canceló

      final params = {
        'p_barber': p.barberId,
        'p_barbershop_id': p.barbershopId, // null si domicilio
        'p_service_id': widget.serviceId,
        'p_starts_at': p.startsAt.toUtc().toIso8601String(),
        'p_ends_at': p.endsAt.toUtc().toIso8601String(),
        'p_slot_ids': p.slotIds,
        'p_is_home': p.barbershopId == null,
        'p_contact_name': contacto?.nombre ?? '',
        'p_contact_phone': contacto?.celular ?? '',
        'p_contact_email': contacto?.email ?? '',
      };

      final apptId = await _supa.rpc('guest_book_appointment', params: params);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Reserva confirmada!')));
      Navigator.pop(context, apptId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo reservar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elegí tu turno')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _propuestas.isEmpty
              ? const Center(
                child: Text(
                  'No hay turnos contiguos para este servicio.\nPodés solicitar agenda o contactar a la barbería.',
                  textAlign: TextAlign.center,
                ),
              )
              : ListView.builder(
                itemCount: _propuestas.length,
                itemBuilder: (context, i) {
                  final p = _propuestas[i];
                  final d1 = _fmtDay.format(p.startsAt.toLocal());
                  final h1 = _fmtHour.format(p.startsAt.toLocal());
                  final h2 = _fmtHour.format(p.endsAt.toLocal());
                  final lugar =
                      p.barbershopId == null
                          ? 'A domicilio'
                          : 'En barbería #${p.barbershopName}';
                  return Card(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: ListTile(
                      title: Text('$d1  $h1 - $h2'),
                      subtitle: Text(lugar),
                      trailing: ElevatedButton(
                        onPressed: () => _reservar(p),
                        child: const Text('Reservar'),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class _Slot {
  final int id;
  final String barberId;
  final int? barbershopId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? barbershopName;

  _Slot({
    required this.id,
    required this.barberId,
    required this.barbershopId,
    required this.startsAt,
    required this.endsAt,
    required this.barbershopName,
  });

  static _Slot fromMap(Map<String, dynamic> m) {
    final Map<String, dynamic>? shop =
        (m['barbershops'] as Map?)?.cast<String, dynamic>();
    return _Slot(
      id: m['id'] as int,
      barberId: m['barber_id'] as String,
      barbershopId: m['barbershop_id'] as int?,
      barbershopName: shop?['name'] as String?,
      startsAt: DateTime.parse(m['starts_at'] as String),
      endsAt: DateTime.parse(m['ends_at'] as String),
    );
  }
}

class _PropuestaTurno {
  final List<int> slotIds;
  final String barberId;
  final int? barbershopId;
  final String? barbershopName;
  final DateTime startsAt;
  final DateTime endsAt;

  _PropuestaTurno({
    required this.slotIds,
    required this.barberId,
    required this.barbershopId,
    required this.barbershopName,
    required this.startsAt,
    required this.endsAt,
  });
}

class _ContactoGuest {
  final String nombre, celular, email;
  _ContactoGuest(this.nombre, this.celular, this.email);
}
