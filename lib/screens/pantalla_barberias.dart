import 'package:barberiapp/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../generated/l10n.dart';
import '../models/barberia.dart';
import '../services/barbershops_service.dart';

class PantallaBarberias extends StatefulWidget {
  const PantallaBarberias({super.key});

  @override
  State<PantallaBarberias> createState() => _PantallaBarberiasState();
}

class _PantallaBarberiasState extends State<PantallaBarberias> {
  Position? _posicion;
  List<Barberia> _ordenadas = [];

  @override
  void initState() {
    super.initState();
    _initUbicacion();
  }

  Future<void> _initUbicacion() async {
    bool permitido = await _pedirPermiso();
    if (!permitido) return;

    final pos = await Geolocator.getCurrentPosition();

    final lista = await _leerYOrdenarDesdeServicio(pos);

    if (!mounted) return;
    setState(() {
      _posicion = pos;
      _ordenadas = lista;
    });
  }

  Future<bool> _pedirPermiso() async {
    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    return permiso == LocationPermission.always ||
        permiso == LocationPermission.whileInUse;
  }

  // NUEVO: usa BarbershopsService.listarPublicas(), mapea a tu modelo y ordena
  Future<List<Barberia>> _leerYOrdenarDesdeServicio(Position pos) async {
    try {
      // 1) Traer barberías públicas (del servicio centralizado)
      final rows = await BarbershopsService.listarPublicas(limit: 200);

      // 2) Mapear a tu modelo Barberia (ajustá si tu constructor es distinto)
      final lista =
          rows
              .map(
                (e) => Barberia(
                  id: (e['id'] as num).toString(),
                  nombre: (e['name'] ?? '') as String,
                  direccion: (e['address'] ?? '') as String,
                  lat: (e['lat'] as num?)?.toDouble() ?? 0,
                  lng: (e['lng'] as num?)?.toDouble() ?? 0,
                  rating: 5, // TODO: reemplazar cuando haya rating real
                ),
              )
              // Opcional pero recomendable: filtrar entradas sin coordenadas válidas
              .where((b) => b.lat != 0 && b.lng != 0)
              .toList();

      // 3) Ordenar por cercanía (misma lógica que ya usabas)
      double distancia(Barberia b) =>
          Geolocator.distanceBetween(pos.latitude, pos.longitude, b.lat, b.lng);
      lista.sort((a, b) => distancia(a).compareTo(distancia(b)));

      return lista;
    } catch (e) {
      // Manejo simple de error para no romper la UI
      if (mounted) {
        final loc = S.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.noPudimosCargarBarberias}: $e')),
        );
      }
      return [];
    }
  }

  void _showBarbershopSheet(BuildContext context, Barberia bar) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        final distKm =
            _posicion == null
                ? null
                : (Geolocator.distanceBetween(
                      _posicion!.latitude,
                      _posicion!.longitude,
                      bar.lat,
                      bar.lng,
                    ) /
                    1000);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.store, color: Colors.redAccent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      bar.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (bar.direccion.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18),
                    const SizedBox(width: 6),
                    Expanded(child: Text(bar.direccion)),
                  ],
                ),
              ],
              if (distKm != null) ...[
                const SizedBox(height: 6),
                Text('${distKm.toStringAsFixed(2)} km • ⭐️ ${bar.rating}'),
              ],

              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.info),
                label: Text(S.of(context)!.verPerfil),
                onPressed: () {
                  Navigator.of(context).pop();
                  // bar.id es String en tu modelo; la ruta usa :id (int). Hacemos parse seguro.
                  final idParam = int.tryParse(bar.id);
                  if (idParam != null) {
                    context.push('/perfil_barberia/$idParam');
                  } else {
                    // Si no es int, igual navegamos con el string (si cambiaste la ruta a string).
                    context.push('/perfil_barberia/${bar.id}');
                  }
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.map),
                label: Text(S.of(context)!.verEnMapa),
                onPressed: () {
                  // Si tenés pantalla de mapa, podés pasar la barbería por extra o query
                  // context.push('/mapa', extra: {'focusLat': bar.lat, 'focusLng': bar.lng});
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.irABarberias, style: TextStyles.tittleText),
      ),
      body:
          _posicion == null
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _ordenadas.length,
                itemBuilder: (context, index) {
                  final bar = _ordenadas[index];
                  final dist =
                      Geolocator.distanceBetween(
                        _posicion!.latitude,
                        _posicion!.longitude,
                        bar.lat,
                        bar.lng,
                      ) /
                      1000; // km

                  return Card(
                    child: ListTile(
                      title: Text(bar.nombre, style: TextStyles.defaultTex_2),
                      subtitle: Text(
                        '${dist.toStringAsFixed(2)} km • ⭐️ ${bar.rating}',
                        style: TextStyles.defaultText,
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showBarbershopSheet(context, bar),
                    ),
                  );
                },
              ),
    );
  }
}
