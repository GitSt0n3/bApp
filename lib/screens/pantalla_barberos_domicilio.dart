// pantalla_barberos_domicilio.dart
// Requiere: geolocator, supabase_flutter, intl
// flutter pub add geolocator supabase_flutter intl

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
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
  double? _maxKm =
      20; // radio de búsqueda del cliente (km). Podés exponerlo con un Slider/Popup.
  bool _usandoPostGIS =
      true; // feature-flag simple para poder comparar con tu flujo actual

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

      // === NUEVO (PostGIS) =====================================================
      // 2) Traer barberos cercanos a domicilio desde la RPC (filtra y ordena por BD)
      //    Requiere que ya tengas creada la función public.home_barbers_near(lat,lng,max_km)
      //    _maxKm: podés fijarlo (p.ej. 20.0) o hacerlo configurable más adelante.
      final maxKm = 20.0;
      final rpcRes = await _supa.rpc(
        'home_barbers_near',
        params: {
          '_lat': _userPos?.latitude,
          '_lng': _userPos?.longitude,
          '_max_km': maxKm,
        },
      );

      final nearby = (rpcRes as List).cast<Map<String, dynamic>>();

      if (nearby.isEmpty) {
        setState(() {
          _items.clear();
          _loading = false;
        });
        return;
      }

      // Mapear IDs
      final barberIds = <String>[
        for (final r in nearby) (r['profile_id']).toString(),
      ];
      final distanceById = <String, double>{
        for (final r in nearby)
          (r['profile_id']).toString():
              (r['distance_km'] as num?)?.toDouble() ?? double.nan,
      };
      final radiusById = <String, int>{
        for (final r in nearby)
          (r['profile_id']).toString():
              ((r['radius_km'] as num?)?.toInt() ?? 0),
      };
      final shopNameById = <String, String?>{
        for (final r in nearby)
          (r['profile_id']).toString(): r['shop_name'] as String?,
      };

      // 3) Traer perfiles (nombres)
      final rowsProfiles = await _supa
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', barberIds);

      final nameById = <String, String>{};
      for (final p in (rowsProfiles as List)) {
        nameById[(p['id']).toString()] = (p['full_name'] ?? '').toString();
      }

      // 4) Traer services activos de esos barberos y calcular surcharge mínimo
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
        final prev = minSurchargeByBarber[id];
        minSurchargeByBarber[id] =
            (prev == null) ? sur : (sur < prev ? sur : prev);
      }

      // 5) Armar items en el **mismo** modelo que ya usás
      //    NOTA: ya no pedimos lat/lng de barbershops ni calculamos distancia en cliente.
      final items = <BarberoHomeItem>[];
      for (final id in barberIds) {
        final name = nameById[id] ?? 'Barbero';
        final radius = radiusById[id] ?? 0;
        final distanciaKm = distanceById[id]; // viene ya ordenada desde la BD
        final surchargeMin = minSurchargeByBarber[id];

        final it = BarberoHomeItem(
          barberId: id,
          fullName: name,
          homeService: true, // la RPC solo devuelve home_service = true
          radiusKm: radius,
          shopLat: null, // ya no lo necesitamos para calcular distancia
          shopLng: null,
          minHomeSurcharge: surchargeMin,
        )..distanciaKm = distanciaKm;

        items.add(it);
      }

      // 6) (Opcional) Por si querés filtrar otra vez por radio (la RPC ya lo hizo):
      //    Dejalo por si más adelante querés cambiar las reglas de business en cliente.
      final filtered =
          items.where((b) {
            if (b.distanciaKm == null || b.distanciaKm!.isNaN) return true;
            if (b.radiusKm <= 0) return true;
            return b.distanciaKm! <= b.radiusKm + 1e-9;
          }).toList();

      // 7) Ya viene ordenado por la BD; igual, si querés asegurar:
      filtered.sort((a, b) {
        final da = a.distanciaKm ?? double.infinity;
        final db = b.distanciaKm ?? double.infinity;
        return da.compareTo(db);
      });

      setState(() {
        _items
          ..clear()
          ..addAll(filtered);
        _loading = false;
      });
      // === FIN NUEVO (PostGIS) ==================================================
    } catch (e) {
      if (!mounted) return;
      final loc = S.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${loc.errorCargandoBarberosDomicilio}: $e',
            style: TextStyles.emptyState,
          ),
        ),
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
          loc.irADomicilio, // Barberos a Domicilio - Titulo -
          style: TextStyles.tittleText,
        ),
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
                      context.pushNamed(
                        'barbero',
                        pathParameters: {'id': it.barberId},
                        extra: {
                          'distanceKm': it.distanciaKm,
                          'minSurcharge': it.minHomeSurcharge,
                        },
                      );
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
