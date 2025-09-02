// pantalla_barberos_domicilio.dart
// Requiere: geolocator, supabase_flutter, intl
// flutter pub add geolocator supabase_flutter intl

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../generated/l10n.dart';
import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/text_styles.dart';

final _supa = Supabase.instance.client;

class BarberoHomeItem {
  final String barberId; // = profiles.id
  final String fullName; // profiles.full_name
  final bool homeService; // barbers.home_service
  final int radiusKm; // barbers.radius_km
  final double? shopLat; // barbershops.lat (si es owner)
  final double? shopLng; // barbershops.lng (si es owner)
  num? minHomeSurcharge; // min(services.home_service_surcharge)
  double? distanciaKm; // calculada runtime

  BarberoHomeItem({
    required this.barberId,
    required this.fullName,
    required this.homeService,
    required this.radiusKm,
    required this.shopLat,
    required this.shopLng,
    this.minHomeSurcharge,
    this.distanciaKm,
  });
}

class PantallaBarberosDomicilio extends StatefulWidget {
  const PantallaBarberosDomicilio({super.key});

  @override
  State<PantallaBarberosDomicilio> createState() =>
      _PantallaBarberosDomicilioState();
}

class _PantallaBarberosDomicilioState extends State<PantallaBarberosDomicilio> {
  bool _loading = true;
  Position? _userPos;
  final List<BarberoHomeItem> _items = [];
  final _fmtKm = NumberFormat('#,##0.0', 'es');
  final _fmtMoney = NumberFormat.currency(locale: 'es', symbol: '\$ ');

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // 1) Ubicación del cliente (opcional)
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      if (await Geolocator.isLocationServiceEnabled()) {
        _userPos = await Geolocator.getCurrentPosition();
      }

      // 2) Traer barberos con domicilio habilitado + nombre del profile
      //    y, si existe, una barbería de la que sea owner (para estimar distancia)
      //    Nota: PostgREST no hace join libre por owner_barber_id; lo resolvemos con 2 queries.
      final rowsBarbers = await _supa
          .from('barbers')
          .select('profile_id, home_service, radius_km')
          .eq('home_service', true);

      if (rowsBarbers is! List || rowsBarbers.isEmpty) {
        setState(() {
          _items.clear();
          _loading = false;
        });
        return;
      }

      // Mapear IDs
      final barberIds = <String>[
        for (final r in rowsBarbers) (r['profile_id']).toString(),
      ];

      // 3) Traer perfiles (nombres)
      final rowsProfiles = await _supa
          .from('profiles')
          .select('id, full_name')
          .inFilter('barber_id', barberIds)
          .eq('active', true);

      final nameById = <String, String>{};
      for (final p in (rowsProfiles as List)) {
        nameById[(p['id']).toString()] = (p['full_name'] ?? '').toString();
      }

      // 4) Traer UNA barbería (si la tiene) donde es owner para tener lat/lng
      //    (si no tiene, distancia quedará “—” hasta que guardemos barbero.lat/lng)
      final rowsShops = await _supa
          .from('barbershops')
          .select('owner_barber_id, lat, lng')
          .inFilter(
            'owner_barber_id',
            barberIds,
          ); // ← antes: .in_('owner_barber_id', barberIds)

      final coordsByOwner = <String, (double, double)>{};
      for (final s in (rowsShops as List)) {
        final owner = (s['owner_barber_id'])?.toString();
        final lat = (s['lat'] as num?)?.toDouble();
        final lng = (s['lng'] as num?)?.toDouble();
        if (owner != null && lat != null && lng != null) {
          coordsByOwner[owner] = (lat, lng);
        }
      }

      // 5) Surcharge: traemos todos los services de estos barberos y calculamos MIN
      final rowsServices = await _supa
          .from('services')
          .select('barber_id, home_service_surcharge, active')
          .inFilter('barber_id', barberIds)
          .eq('active', true);

      final minSurchargeByBarber = <String, num>{};
      for (final s in (rowsServices as List)) {
        final id = (s['barber_id']).toString();
        final sur = s['home_service_surcharge'] as num?;
        if (sur == null) continue;
        if (!minSurchargeByBarber.containsKey(id)) {
          minSurchargeByBarber[id] = sur;
        } else {
          minSurchargeByBarber[id] = math.min(minSurchargeByBarber[id]!, sur);
        }
      }

      // 6) Armar items y calcular distancia si tenemos coords
      final items = <BarberoHomeItem>[];
      for (final r in rowsBarbers) {
        final id = (r['profile_id']).toString();
        final name = nameById[id] ?? 'Barbero';
        final home = (r['home_service'] as bool?) ?? false;
        final radius = (r['radius_km'] as int?) ?? 0;
        final coords = coordsByOwner[id];

        final it = BarberoHomeItem(
          barberId: id,
          fullName: name,
          homeService: home,
          radiusKm: radius,
          shopLat: coords?.$1,
          shopLng: coords?.$2,
          minHomeSurcharge: minSurchargeByBarber[id],
        );

        // Distancia (si hay ubicación cliente + coords de referencia)
        if (_userPos != null && it.shopLat != null && it.shopLng != null) {
          final dMeters = Geolocator.distanceBetween(
            _userPos!.latitude,
            _userPos!.longitude,
            it.shopLat!,
            it.shopLng!,
          );
          it.distanciaKm = dMeters / 1000.0;
        }

        items.add(it);
      }

      // 7) Filtro por radio si tengo distancia + radio > 0
      final filtered =
          items.where((b) {
            if (b.distanciaKm == null) return true; // sin coords → mostramos
            if (b.radiusKm <= 0) return true; // sin radio → mostramos
            return b.distanciaKm! <= b.radiusKm + 1e-9;
          }).toList();

      setState(() {
        _items
          ..clear()
          ..addAll(filtered);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final loc = S.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.errorCargandoBarberosDomicilio}: $e')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.appBarbkgs,
      appBar: AppBar(
        backgroundColor: AppColors.appBarbkgs,
        title: Text(
          loc.irADomicilio,
          style: TextStyles.tittleText,
        ), // Barberos a Domicilio
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty
              ? Center(
                child: Text(
                  S
                      .of(context)!
                      .sinBarberosDomicilioCerca, //'No hay barberos a domicilio cerca.',
                  style: TextStyles.emptyState,
                ),
              )
              : ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final it = _items[i];

                  final distanciaStr =
                      (it.distanciaKm != null)
                          ? '${_fmtKm.format(it.distanciaKm)} km'
                          : '—';

                  final recargoStr =
                      (it.minHomeSurcharge != null)
                          ? _fmtMoney.format(it.minHomeSurcharge)
                          : '—';

                  return _BarberoCard(
                    nombre: it.fullName,
                    distancia: distanciaStr,
                    recargo: recargoStr,
                    onTap: () {
                      // TODO: navegar al perfil del barbero o a sus servicios a domicilio
                      // context.push('/barbero/${it.barberId}');
                    },
                  );
                },
              ),
    );
  }
}

class _BarberoCard extends StatelessWidget {
  final String nombre;
  final String distancia;
  final String recargo;
  final VoidCallback? onTap;

  const _BarberoCard({
    required this.nombre,
    required this.distancia,
    required this.recargo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    return Material(
      color: AppColors.appBarbkgs,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(16),
            color: AppColors.appBarbkgs,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, size: 24, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.defaultTex_2,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${loc.distanciaLabel} $distancia',
                      style: TextStyles.defaultTex_2,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${loc.recargoDomicilioLabel} $recargo',
                      style: TextStyles.defaultTex_2,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
