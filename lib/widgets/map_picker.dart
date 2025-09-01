import 'package:barberiapp/core/button_styles.dart';
import 'package:barberiapp/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../services/nominatim_service.dart';

class MapPickerResult {
  final double lat;
  final double lon;
  final String? address;
  MapPickerResult({required this.lat, required this.lon, this.address});
}

class MapPicker extends StatefulWidget {
  final LatLng initial;
  const MapPicker({super.key, required this.initial});

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  final _mapController = MapController();
  LatLng _center = const LatLng(-34.9011, -56.1645); // Montevideo
  bool _mapReady = false; // ← NUEVO
  String? _address;
  bool _loadingAddr = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initial;
    _fetchAddress();
  }

  void dispose() {
    _mapReady = false; // ← evita mover luego del dispose
    super.dispose();
  }

  Future<void> _fetchAddress() async {
    setState(() => _loadingAddr = true);
    _address = await NominatimService.reverse(
      _center.latitude,
      _center.longitude,
    );
    if (mounted) setState(() => _loadingAddr = false);
  }

  Future<void> _useMyLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied)
      perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever)
      return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    // ← el widget pudo cerrarse mientras esperábamos
    if (!mounted) return;
    _center = LatLng(pos.latitude, pos.longitude);
    if (_mapReady) {
      _mapController.move(_center, 16);
    } else {
      setState(() {}); // al menos actualiza estado
    }
    await _fetchAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Elegir ubicación', style: TextStyles.tittleText),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: _PlaceSearchDelegate(),
              );
              if (result != null) {
                _center = LatLng(result.lat, result.lon);
                _mapController.move(_center, 16);
                _fetchAddress();
              }
            },
          ),
          IconButton(
            onPressed: _useMyLocation,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onPositionChanged: (pos, _) {
                _center = pos.center!;
              },
              onMapReady: () {
                _mapReady = true;
                _mapController.move(_center, 15);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.barberiapp.app',
              ),
            ],
          ),
          // Pin fijo al centro
          const Center(child: Icon(Icons.location_on, size: 40)),
          // Address pill
          Positioned(
            left: 16,
            right: 16,
            bottom: 150,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _loadingAddr ? 'Buscando dirección…' : (_address ?? '—'),
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Confirmar
          Positioned(
            left: 16,
            right: 16,
            bottom: 95,
            child: FilledButton(
              style: ButtonStyles.redButton,
              onPressed: () {
                Navigator.pop(
                  context,
                  MapPickerResult(
                    lat: _center.latitude,
                    lon: _center.longitude,
                    address: _address,
                  ),
                );
              },
              child: const Text('Confirmar ubicación'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceSearchDelegate extends SearchDelegate<NominatimPlace?> {
  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear)),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back),
  );

  @override
  Widget buildResults(BuildContext context) => _buildList();

  @override
  Widget buildSuggestions(BuildContext context) => _buildList();

  Widget _buildList() {
    if (query.trim().isEmpty) return const SizedBox.shrink();
    return FutureBuilder(
      future: NominatimService.search(query),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data!;
        if (items.isEmpty) {
          return const Center(child: Text('Sin resultados'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) {
            final p = items[i];
            return ListTile(
              title: Text(
                p.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => close(context, p),
            );
          },
        );
      },
    );
  }
}
