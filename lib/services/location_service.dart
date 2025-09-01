import 'package:geolocator/geolocator.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';

class LocationService {
  final _geolocator = GeolocatorPlatform.instance;

  Future<Position?> current() async {
    if (!await _geolocator.isLocationServiceEnabled()) return null;

    var perm = await _geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await _geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) return null;

    return _geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high, 
      ),
    );
  }

  Stream<Position> stream() => _geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 10,   // solo si se mueve ≥10 m
        ),
      );
}