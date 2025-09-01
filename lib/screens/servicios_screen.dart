import 'dart:math' as math;
import 'package:barberiapp/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../generated/l10n.dart';
import 'package:barberiapp/core/app_colors.dart';

final _supa = Supabase.instance.client;

/// Modelo simple para usar en UI (evita líos de joins)
class ServicioItem {
  final int id;
  final String name;
  final int durationMin;
  final num price;
  final String barberId;
  final int? barbershopId;
  final Map<String, dynamic>?
  shop; // {id,name,address,lat,lng} si la query lo trae

  ServicioItem({
    required this.id,
    required this.name,
    required this.durationMin,
    required this.price,
    required this.barberId,
    required this.barbershopId,
    this.shop,
  });

  static ServicioItem fromMap(Map<String, dynamic> m) {
    return ServicioItem(
      id: m['id'] as int,
      name: m['name'] as String,
      durationMin: (m['duration_min'] as num).toInt(),
      price: m['price'] as num,
      barberId: m['barber_id'] as String,
      barbershopId: m['barbershop_id'] as int?,
      shop: m['barbershops'] as Map<String, dynamic>?,
    );
  }
}

class ServiciosScreen extends StatefulWidget {
  final int? barbershopId;
  final bool onlyHomeInitial; // 👈 nuevo
  const ServiciosScreen({super.key, this.barbershopId,this.onlyHomeInitial = false,});
  

  @override
  State<ServiciosScreen> createState() => _ServiciosScreenState();
}

class _ServiciosScreenState extends State<ServiciosScreen> {
  
  bool _loading = true;
  String _search = '';
  bool _onlyHome =
      false; // solo servicios “a domicilio” (barbershop_id == null)
  Position? _pos;
  final _fmtMoney = NumberFormat.currency(locale: 'es_UY', symbol: '\$U ');

  List<ServicioItem> _todos = [];
  List<ServicioItem> _filtrados = [];

  @override
  void initState() {
    super.initState();
    _onlyHome = widget.onlyHomeInitial; // 👈 aplica filtro inicial
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    final loc = S.of(context)!; 
    try {
      // Ubicación (opcional)
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      if (await Geolocator.isLocationServiceEnabled()) {
        _pos = await Geolocator.getCurrentPosition();
      }

      // Base: servicios activos + barbería embebida
      var query = _supa
          .from('services')
          .select(r'''
          id,
          name,
          duration_min,
          price,
          active,
          barber_id,
          barbershop_id,
          barbershops(id,name,address,lat,lng)
        ''')
          .eq('active', true);

      // Filtro opcional por barbería (si abriste desde perfil_barberia)
      if (widget.barbershopId != null) {
        final id = widget.barbershopId!; // ya sabemos que no es null
        query = query.eq('barbershop_id', id);
      }

      final rows = await query;

      _todos = (rows as List).map((e) => ServicioItem.fromMap(e)).toList();
      _aplicarFiltros(); // <-- nombre correcto
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorCargandoServicios} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _aplicarFiltros() {
    final s = _search.trim().toLowerCase();
    List<ServicioItem> data =
        _todos.where((it) {
          if (_onlyHome && it.barbershopId != null) return false;
          if (s.isEmpty) return true;
          final inName = it.name.toLowerCase().contains(s);
          final inShop = (it.shop?['name']?.toString().toLowerCase() ?? '')
              .contains(s);
          return inName || inShop;
        }).toList();

    // Orden por distancia (si tengo ubicación)
    if (_pos != null) {
      data.sort((a, b) => _dist(a).compareTo(_dist(b)));
    }

    setState(() => _filtrados = data);
  }

  // Distancia en metros usando Geolocator
  double _dist(ServicioItem it) {
    if (_pos == null) return double.maxFinite;
    final lat = (it.shop?['lat'] as num?)?.toDouble();
    final lng = (it.shop?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return double.maxFinite;

    return Geolocator.distanceBetween(
      _pos!.latitude,
      _pos!.longitude,
      lat,
      lng,
    ); // metros
  }

  // Formato “200 m” / “1.2 km”
  String? _distPretty(ServicioItem it) {
    if (_pos == null) return null;
    final lat = (it.shop?['lat'] as num?)?.toDouble();
    final lng = (it.shop?['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    final m = _dist(it);
    if (m < 1000) return '${m.round()} m';
    final km = m / 1000.0;
    return km < 10
        ? '${km.toStringAsFixed(1)} km'
        : '${km.toStringAsFixed(0)} km';
  }

  void _onSeleccionar(ServicioItem it) {
    context.push(
      '/turnos',
      extra: {
        'service_id': it.id,
        'duration_min': it.durationMin,
        'barbershop_id': it.barbershopId,
        'barber_id': it.barberId, // puede ser null (a domicilio)
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.servicios, style: TextStyles.tittleText)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) {
                      _search = v;
                      _aplicarFiltros();
                    },
                    decoration: InputDecoration(
                      hintText: loc.buscarServicio,
                      hintStyle: TextStyles.defaultTex_2,
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  selected: _onlyHome,
                  label: Text(
                    loc.irADomicilio,
                    style: TextStyles.defaultTex_2.copyWith(
                      color: _onlyHome ? Colors.white : AppColors.primary,
                    ),
                  ),
                  backgroundColor:
                      AppColors.accent, // fondo cuando NO está seleccionado
                  selectedColor:
                      AppColors.primary, // fondo cuando SÍ está seleccionado
                  checkmarkColor:
                      Colors.white, // color del tilde cuando está ON
                  side: BorderSide(
                    color: _onlyHome ? Colors.transparent : AppColors.primary,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (v) {
                    setState(() => _onlyHome = v);
                    _aplicarFiltros();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _filtrados.isEmpty
                    ? Center(
                      child: Text(
                        loc.noHayServiciosDisponibles,
                        style: TextStyles.emptyState,
                      ),
                    )
                    : ListView.separated(
                      itemCount: _filtrados.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final it = _filtrados[i];
                        final isHome = it.barbershopId == null;
                        final shopName = it.shop?['name']?.toString();
                        final address = it.shop?['address']?.toString();
                        final sub =
                            isHome
                                ? loc.aDomicilio
                                : (shopName ?? loc.enBarberia);
                        final distLabel = (!isHome) ? _distPretty(it) : null;

                        return ListTile(
                          isThreeLine:
                              true, // habilita 3 líneas (title + 2 en subtitle)
                          title: Text(it.name, style: TextStyles.listTitle),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 2º renglón (como ya tenías)
                              Text(
                                '$sub · ${it.durationMin} min · ${_fmtMoney.format(it.price)}',
                                style: TextStyles.listSubtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              // 3º renglón: dirección de la barbería (si existe)
                              if (!isHome &&
                                  (address != null &&
                                      address.trim().isNotEmpty))
                                Text(
                                  address,
                                  style: TextStyles.listSubtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              if (distLabel != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.place,
                                      size: 14,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      distLabel,
                                      style: TextStyles.listSubtitle,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF9E9E9E),
                          ),
                          onTap: () => _onSeleccionar(it),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
