import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/barberias_mock.dart';
import '../models/barberia.dart';
import '../generated/l10n.dart';
import 'package:go_router/go_router.dart';
import '../services/location_service.dart';
import '../services/barbershops_service.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'dart:ui' as ui;

// <-- usar tu servicio real

class PantallaBarberiasMapa extends StatefulWidget {
  const PantallaBarberiasMapa({super.key});
  @override
  State<PantallaBarberiasMapa> createState() => _PantallaBarberiasMapaState();
}

// Pequeño contenedor para cargar ubicación + barberías juntas
class _CargaMapa {
  final Position? pos;
  final List<Barberia> shops;
  _CargaMapa(this.pos, this.shops);
}

class _BubblePopup extends StatelessWidget {
  final String title;
  final String? address;
  final VoidCallback onVerPerfil;

  const _BubblePopup({
    required this.title,
    this.address,
    required this.onVerPerfil,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Caja principal (globo)
        Container(
          width: 260,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(10), // poco redondeado
            border: Border.all(color: Colors.white12),
            boxShadow: const [BoxShadow(blurRadius: 8, color: Colors.black54)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (address != null && address!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  address!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onVerPerfil,
                icon: const Icon(Icons.info),
                label: Text(S.of(context)!.verPerfil),
              ),
            ],
          ),
        ),
        // Punta inferior que “nace” del pin
        CustomPaint(
          size: const Size(20, 10),
          painter: _BottomTrianglePainter(color: const Color(0xFF1E1E1E)),
        ),
      ],
    );
  }
}

class _BottomTrianglePainter extends CustomPainter {
  final Color color;
  _BottomTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;

    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, fill);

    // Borde sutil
    final border = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _PantallaBarberiasMapaState extends State<PantallaBarberiasMapa> {
  final LocationService _loc = LocationService();
  final MapController _mapController = MapController();
  final _popupCtrl = PopupController();

  Future<_CargaMapa> _cargar() async {
    final pos = await _loc.current();
    final rows = await BarbershopsService.listarPublicas(limit: 200);

    // Transformamos la respuesta de Supabase a tu modelo Barberia
    final shops =
        rows
            .where((e) => e['lat'] != null && e['lng'] != null)
            .map(
              (e) => Barberia(
                id: e['id'].toString(),
                nombre: (e['name'] ?? 'Sin nombre') as String,
                direccion: (e['address'] ?? '') as String,
                lat: (e['lat'] as num).toDouble(),
                lng: (e['lng'] as num).toDouble(),
                // La UI ya muestra rating; por ahora un default hasta que lo agreguemos en DB
                rating: 4.7,
              ),
            )
            .toList();

    return _CargaMapa(pos, shops);
  }

  void _showDetails(BuildContext context, Barberia b) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(
                    b.nombre,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${b.direccion} • ${b.rating.toStringAsFixed(1)} ★',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push('/turnos', extra: b);
                      },
                      child: Text(S.of(context)!.irATurnos),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CargaMapa>(
      future: _cargar(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Fallback al mock si la tabla está vacía o hubo algún problema
        final data = snap.data;
        final Position? userPos = data?.pos;
        final List<Barberia> barberias =
            (data?.shops.isNotEmpty == true) ? data!.shops : mockBarberias;

        final LatLng initialCenter =
            userPos != null
                ? LatLng(userPos.latitude, userPos.longitude)
                : LatLng(barberias.first.lat, barberias.first.lng);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              S.of(context)!.irABarberias,
              style: TextStyles.tittleText,
            ),
          ),
          body: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: initialCenter,
              zoom: 14,
              onTap: (_, __) => _popupCtrl.hideAllPopups(), // ⬅️ así
            ),
            children: [
              // Mapa base
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.barberiapp.app',
              ),

              // Marker del usuario (capa simple, SIN popup)
              if (userPos != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(userPos.latitude, userPos.longitude),
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 40,
                        color: AppColors.appBarbkgs,
                      ),
                    ),
                  ],
                ),

              // Markers de barberías + POPUP anclado al marker
              PopupMarkerLayerWidget(
                options: PopupMarkerLayerOptions(
                  popupController: _popupCtrl, // ⬅️ mismo nombre
                  markerTapBehavior: MarkerTapBehavior.togglePopup(),
                  markers:
                      barberias.map((b) {
                        return Marker(
                          key: ValueKey(b.id), // ⬅️ mejor usar el id
                          width: 50,
                          height: 50,
                          point: LatLng(b.lat, b.lng),
                          child: Image.asset('assets/icons/ubication.png'),
                        );
                      }).toList(),
                  popupDisplayOptions: PopupDisplayOptions(
                    snap: PopupSnap.markerTop,
                    builder: (ctx, marker) {
                      final id = (marker.key as ValueKey).value as String;
                      final barb = barberias.firstWhere(
                        (x) => x.id == id,
                      ); // recuperamos la barbería

                      return _BubblePopup(
                        title: barb.nombre,
                        address: barb.direccion,
                        onVerPerfil: () {
                          final intId = int.tryParse(barb.id);
                          if (intId != null) {
                            context.push('/perfil_barberia/$intId');
                          } else {
                            context.push('/perfil_barberia/${barb.id}');
                          }
                          _popupCtrl.hideAllPopups(); // cierra el globo
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final center =
                  userPos != null
                      ? LatLng(userPos.latitude, userPos.longitude)
                      : initialCenter;
              _mapController.move(center, 16);
            },
            child: const Icon(Icons.my_location),
          ),
        );
      },
    );
  }
}
