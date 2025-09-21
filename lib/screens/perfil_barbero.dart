import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../generated/l10n.dart';
import 'package:barberiapp/core/section_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilBarberoDomicilioYRedes extends StatefulWidget {
  final String barberProfileId; // profile_id del barbero (uuid)
  const PerfilBarberoDomicilioYRedes({
    super.key,
    required this.barberProfileId,
  });

  @override
  State<PerfilBarberoDomicilioYRedes> createState() =>
      _PerfilBarberoDomicilioYRedesState();
}

class _PerfilBarberoDomicilioYRedesState
    extends State<PerfilBarberoDomicilioYRedes> {
  final _supa = Supabase.instance.client;
  Future<void> _linkGoogle(BuildContext context) async {
    try {
      final ok = await Supabase.instance.client.auth.linkIdentity(
        OAuthProvider.google,
        redirectTo: 'com.barberiapp://login-callback',
        queryParams: {'prompt': 'select_account'},
      );

      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo iniciar el flujo de vinculación.'),
          ),
        );
        return;
      }

      // El usuario actualizado llega por onAuthStateChange → AuthChangeEvent.userUpdated
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔗 Se abrió el flujo para vincular Google.'),
        ),
      );
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al vincular: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
    }
  }

  // Estado
  bool _loading = true;
  bool _saving = false;

  bool _homeService = false;
  double _radiusKm = 8;

  final _addrCtrl = TextEditingController();
  double? _lat;
  double? _lng;

  final _instagramCtrl = TextEditingController();
  final _whatsCtrl = TextEditingController();
  final _facebookCtrl = TextEditingController();
  final _tiktokCtrl = TextEditingController();

  String _bookingApp = 'none'; // 'none' | 'weibook' | 'other'
  final _bookingUrlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    //  _load();
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _instagramCtrl.dispose();
    _whatsCtrl.dispose();
    _facebookCtrl.dispose();
    _tiktokCtrl.dispose();
    _bookingUrlCtrl.dispose();
    super.dispose();
  }

  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;

    _load(); // ✅ Seguro aquí
  }

  Future<void> _load() async {
    try {
      final row =
          await _supa
              .from('barbers')
              .select(
                'home_service,radius_km,base_address,base_lat,base_lng,'
                'instagram_url,whatsapp,facebook_url,tiktok_url,booking_app,booking_url',
              )
              .eq('profile_id', widget.barberProfileId)
              .maybeSingle();

      if (row != null) {
        _homeService = (row['home_service'] ?? false) as bool;
        _radiusKm = ((row['radius_km'] ?? 8) as num).toDouble();
        _addrCtrl.text = (row['base_address'] ?? '') as String;
        _lat = (row['base_lat'] as num?)?.toDouble();
        _lng = (row['base_lng'] as num?)?.toDouble();

        _instagramCtrl.text = (row['instagram_url'] ?? '') as String;
        _whatsCtrl.text = (row['whatsapp'] ?? '') as String;
        _facebookCtrl.text = (row['facebook_url'] ?? '') as String;
        _tiktokCtrl.text = (row['tiktok_url'] ?? '') as String;

        _bookingApp = (row['booking_app'] ?? 'none') as String;
        _bookingUrlCtrl.text = (row['booking_url'] ?? '') as String;
      }
    } catch (e) {
      if (!mounted) return;
      final loc = S.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${loc.errorCargandoPerfil} $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _usarUbicacionActual() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        perm = await Geolocator.requestPermission();
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        // en vez de throw string
        if (mounted) {
          final loc = S.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.ubicacionServiciosDeshabilitados)),
          );
        }
        return; // salgo limpiamente
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      // Opcional: resolver dirección amigable con tu servicio/OSM geocoding
      _addrCtrl.text =
          'Lat ${pos.latitude.toStringAsFixed(5)}, Lng ${pos.longitude.toStringAsFixed(5)}';
    } catch (e) {
      if (!mounted) return;
      final loc = S.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.ubicacionNoSePudoObtener} $e')),
      );
    }
  }

  bool _isValidUrl(String s) {
    if (s.trim().isEmpty) return true; // campo opcional
    final uri = Uri.tryParse(s.trim());
    return uri != null &&
        (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https'));
  }

  Future<void> _guardar() async {
    if (_bookingApp != 'none' && !_isValidUrl(_bookingUrlCtrl.text)) {
      final loc = S.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.urlReservasInvalida)));
      return;
    }
    if ((_lat == null || _lng == null) && _homeService) {
      final loc = S.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.debeDefinirUbicacionBase)));
      return;
    }

    setState(() => _saving = true);
    try {
      await _supa
          .from('barbers')
          .update({
            'home_service': _homeService,
            'radius_km': _radiusKm.round(),
            'base_address':
                _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
            'base_lat': _lat,
            'base_lng': _lng,
            'instagram_url':
                _instagramCtrl.text.trim().isEmpty
                    ? null
                    : _instagramCtrl.text.trim(),
            'whatsapp':
                _whatsCtrl.text.trim().isEmpty ? null : _whatsCtrl.text.trim(),
            'facebook_url':
                _facebookCtrl.text.trim().isEmpty
                    ? null
                    : _facebookCtrl.text.trim(),
            'tiktok_url':
                _tiktokCtrl.text.trim().isEmpty
                    ? null
                    : _tiktokCtrl.text.trim(),
            'booking_app': _bookingApp,
            'booking_url':
                _bookingUrlCtrl.text.trim().isEmpty
                    ? null
                    : _bookingUrlCtrl.text.trim(),
          })
          .eq('profile_id', widget.barberProfileId);

      if (!mounted) return;
      final loc = S.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.perfilActualizado)));
    } catch (e) {
      if (!mounted) return;
      final loc = S.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${loc.errorGuardando} $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!; // 👈 acá inicializamos traducciones
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    // 🔁 REEMPLAZA desde: return SingleChildScrollView(...);
    // 🔁 HASTA el ); que cierra ese SingleChildScrollView

    return CustomScrollView(
      slivers: [
        // --- Servicio a domicilio ---
        SliverToBoxAdapter(
          child: SectionCard(
            title: S.of(context)!.ofrezcoDomicilio,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // tu Switch actual (no cambies la lógica)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      S.of(context)!.ofrezcoDomicilio,
                    ),
                    Switch(
                      value: _homeService,
                      onChanged: (v) => setState(() => _homeService = v),
                    ),
                  ],
                ),
                if (_homeService) ...[
                  const SizedBox(height: 8),
                  // etiqueta del slider con el valor actual
                  Text(
                    '${S.of(context)!.radioKm} ${_radiusKm.toStringAsFixed(0)}',
                  ),
                  Slider(
                    value: _radiusKm,
                    min: 1,
                    max: 50,
                    divisions: 49,
                    label: '${_radiusKm.toStringAsFixed(0)} km',
                    onChanged: (v) => setState(() => _radiusKm = v),
                  ),
                ],
              ],
            ),
          ),
        ),

        // --- Ubicación base ---
        SliverToBoxAdapter(
          child: SectionCard(
            title: S.of(context)!.seleccionaUbicacion,
            trailing: TextButton.icon(
              onPressed: null,//_onPickOnMap, // tu handler existente
              icon: const Icon(Icons.map_outlined),
              label: Text(S.of(context)!.verEnMapa),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // muestra tu texto/dirección actual
               // Text(_baseAddressText ?? _latLngToString(_baseLatLng)),
                const SizedBox(height: 8),
                FilledButton.tonalIcon(
                  onPressed: null,//_onUseCurrentLocation, // tu handler existente
                  icon: const Icon(Icons.my_location),
                  label: Text(
                    S.of(context)!.usarmiubicacionctual,
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- Redes sociales ---
        SliverToBoxAdapter(
          child: SectionCard(
            title: S.of(context)!.redesSocialesTitulo,
            child: Column(
              children: [
                // _instagramField(), // reusa tus widgets/métodos actuales
                // _whatsappField(),
                // _facebookField(),
                // _tiktokField(),
              ],
            ),
          ),
        ),

        // --- Agenda externa ---
        

        // --- Integraciones ---
        SliverToBoxAdapter(
          child: SectionCard(
            title: S.of(context)!.profile_section_integrations,
            child: FilledButton.icon(
              onPressed: null,//_onLinkGoogle,
              icon: const Icon(Icons.link),
              label: Text(S.of(context)!.continuarConGoogle),
            ),
          ),
        ),

        // espacio para que no tape el botón inferior (si tu Scaffold lo usa)
        const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
      ],
    );
  }
}
