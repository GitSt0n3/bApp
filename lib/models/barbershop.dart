// lib/models/barbershop.dart
class Barbershop {
  final int id;
  final String name;
  final String? address;
  final double? lat;
  final double? lng;

  Barbershop({required this.id, required this.name, this.address, this.lat, this.lng});

  factory Barbershop.fromMap(Map<String, dynamic> m) => Barbershop(
    id: m['id'] as int,
    name: m['name'] as String,
    address: m['address'] as String?,
    lat: (m['lat'] as num?)?.toDouble(),
    lng: (m['lng'] as num?)?.toDouble(),
  );
}
