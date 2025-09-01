import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimService {
  static const _base = 'https://nominatim.openstreetmap.org';
  static const _headers = {
    // Nominatim pide User-Agent identificable
    'User-Agent': 'BarberiApp/1.0 (contacto@example.com)'
  };

  static Future<String?> reverse(double lat, double lon) async {
    final uri = Uri.parse('$_base/reverse?lat=$lat&lon=$lon&format=jsonv2');
    final r = await http.get(uri, headers: _headers);
    if (r.statusCode == 200) {
      final data = jsonDecode(r.body);
      return data['display_name'] as String?;
    }
    return null;
    // TIP: maneja rate limiting si empezás a tener tráfico
  }

  static Future<List<NominatimPlace>> search(String query) async {
    final uri = Uri.parse('$_base/search?q=$query&format=jsonv2&addressdetails=1&limit=8');
    final r = await http.get(uri, headers: _headers);
    if (r.statusCode != 200) return [];
    final List list = jsonDecode(r.body);
    return list.map((e) => NominatimPlace.fromJson(e)).toList();
  }
}

class NominatimPlace {
  final double lat;
  final double lon;
  final String displayName;
  NominatimPlace({required this.lat, required this.lon, required this.displayName});
  factory NominatimPlace.fromJson(Map<String, dynamic> j) => NominatimPlace(
    lat: double.parse(j['lat']),
    lon: double.parse(j['lon']),
    displayName: j['display_name'],
  );
}
