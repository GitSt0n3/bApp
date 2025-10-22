// (archivo completo, modificado: botones de mapa/ubicación habilitados, añadido _onPickOnMap,
// añadido _guardarUbicacion y estilo del botón de "Guardar ubicación" con ButtonStyles.redButton)
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../generated/l10n.dart';
import 'package:barberiapp/core/section_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/social_button.dart'; // ruta según tu proyecto
import 'package:barberiapp/core/button_styles.dart'; // para estilos de botones
// si pegaste el helper que te pasé:
//import 'package:barberiapp/core/social_utils.dart';
import '../widgets/social_field.dart';
import '../core/social_utils.dart';

// Nuevas importaciones para el selector de mapa
import 'package:latlong2/latlong.dart';
import '../widgets/map_picker.dart';
import 'package:geocoding/geocoding.dart'; // Dirección aproximada

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
  String? _googleEmail;
  // --- Redes sociales ---
  // --- Helper: extraer email de una User (maneja Map o objetos tipados) ---
  // ----------------------- NUEVO HELPER (añadir dentro de _PerfilBarberoDomicilioYRedesState) -----------------------
  String? _extractGoogleEmailFromUser(dynamic user) {
    if (user == null) return null;
    try {
      // 1) Intentamos leer identities de forma segura (user.identities o user['identities'])
      final identities =
          (user.identities ?? (user is Map ? user['identities'] : null));
      if (identities is List) {
        for (final id in identities) {
          // Caso: Map (serializado)
          if (id is Map) {
            final provider = (id['provider'] as String?) ?? '';
            if (provider == 'google') {
              final identityData = id['identity_data'] as Map<String, dynamic>?;
              final email = identityData?['email'] as String?;
              if (email != null && email.isNotEmpty) return email;
            }
          } else {
            // Caso: objeto tipado (UserIdentity). Accedemos dinámicamente para evitar errores de tipo.
            try {
              final provider = (id as dynamic).provider as String?;
              if (provider == 'google') {
                final identityData =
                    (id as dynamic).identityData as Map<String, dynamic>?;
                final email = identityData?['email'] as String?;
                if (email != null && email.isNotEmpty) return email;
              }
            } catch (_) {
              // si falla el acceso dinámico, seguimos con el siguiente id
            }
          }
        }
      }
    } catch (_) {
      // ignore parsing errors
    }

    // Fallback: intentamos obtener email directo del user
    try {
      final emailFromUser =
          (user.email ?? (user is Map ? user['email'] : null)) as String?;
      if (emailFromUser != null && emailFromUser.isNotEmpty)
        return emailFromUser;
    } catch (_) {}

    return null;
  }

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔗 Se abrió el flujo para vincular Google.'),
        ),
      );

      // --- En _linkGoogle(): luego de abrir el flujo ---
      if (!ok) {
        /* existente */
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🔗 Se abrió el flujo para vincular Google.'),
        ),
      );

      // Intento de refrescar usuario después de corto delay (el callback puede tardar)
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          final userResp = await _supa.auth.getUser();
          final user = userResp.user;
          final extracted = _extractGoogleEmailFromUser(
            user ?? (userResp as dynamic)?.data,
          );
          if (!mounted) return;
          setState(() => _googleEmail = extracted);
        } catch (_) {}
      });

      // Intentar refrescar el usuario localmente (en muchos casos la vinculación
      // sucede en otra ventana/APP y requiere que el SDK reciba el callback).
      // Aquí hacemos un intento simple de refrescar el usuario; si el deep-link
      // o el callback no han ocurrido aún, el cambio se reflejará cuando vuelva.
      // dentro de _linkGoogle(): después de mostrar el snackbar:
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          final userResp = await _supa.auth.getUser();
          final user = userResp.user;
          final extracted = _extractGoogleEmailFromUser(
            user ?? (userResp as dynamic)?.data,
          );
          if (!mounted) return;
          setState(() => _googleEmail = extracted);
        } catch (_) {
          // ignoramos errores de refresco
        }
      });
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
    // --- En _load(): obtener user y setear _googleEmail ---
    // --- en _load(), después de tus lecturas normales de 'row' ---
    try {
      final userResp = await _supa.auth.getUser();
      final user = userResp.user;
      // si el SDK devuelve una estructura distinta, _extractGoogleEmailFromUser lo maneja
      final extracted = _extractGoogleEmailFromUser(
        user ?? (userResp as dynamic)?.data,
      );
      if (mounted) setState(() => _googleEmail = extracted);
    } catch (_) {
      // no crítico; ignoramos errores al consultar auth.getUser()
    }
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

  // --- Reemplazar (o insertar) la implementación de _usarUbicacionActual() por esta ----------------
  Future<void> _usarUbicacionActual() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Activa los servicios de ubicación en tu dispositivo',
            ),
          ),
        );
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Permiso de ubicación denegado permanentemente. Habilítalo en Ajustes.',
            ),
            action: SnackBarAction(
              label: 'Ajustes',
              onPressed: () => Geolocator.openAppSettings(),
            ),
          ),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final lat = pos.latitude;
      final lng = pos.longitude;

      setState(() {
        _lat = lat;
        _lng = lng;
      });

      try {
        final placemarks = await placemarkFromCoordinates(lat, lng);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[];
          if (p.street != null && p.street!.trim().isNotEmpty)
            parts.add(p.street!.trim());
          if (p.subLocality != null && p.subLocality!.trim().isNotEmpty)
            parts.add(p.subLocality!.trim());
          if (p.locality != null && p.locality!.trim().isNotEmpty)
            parts.add(p.locality!.trim());
          if (parts.isEmpty) {
            if (p.subAdministrativeArea != null &&
                p.subAdministrativeArea!.trim().isNotEmpty)
              parts.add(p.subAdministrativeArea!.trim());
            else if (p.administrativeArea != null &&
                p.administrativeArea!.trim().isNotEmpty)
              parts.add(p.administrativeArea!.trim());
          }
          final shortAddress =
              parts.isNotEmpty
                  ? parts.join(', ')
                  : 'Ubicación aproximada no disponible';
          setState(() {
            _addrCtrl.text = shortAddress;
          });
        } else {
          setState(() {
            _addrCtrl.text = 'Ubicación aproximada no disponible';
          });
        }
      } catch (_) {
        setState(() {
          _addrCtrl.text = 'Ubicación aproximada no disponible';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al obtener ubicación: $e')));
      setState(() {
        _addrCtrl.text = 'Ubicación aproximada no disponible';
      });
    }
  }

  // ------------------------------------------------
  // Nuevo: abrir MapPicker y recoger resultado
  Future<void> _onPickOnMap() async {
    final initial = LatLng(_lat ?? -34.9011, _lng ?? -56.1645);
    final res = await Navigator.push<MapPickerResult?>(
      context,
      MaterialPageRoute(builder: (_) => MapPicker(initial: initial)),
    );
    if (res != null) {
      setState(() {
        _lat = res.lat;
        _lng = res.lon;
        _addrCtrl.text =
            res.address ??
            '${res.lat.toStringAsFixed(6)}, ${res.lon.toStringAsFixed(6)}';
      });
    }
  }

  // Nuevo: guardar sólo la ubicación (base_address/base_lat/base_lng)
  Future<void> _guardarUbicacion() async {
    final loc = S.of(context)!;
    if ((_lat == null || _lng == null) && _homeService) {
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
            'base_address':
                _addrCtrl.text.trim().isEmpty ? null : _addrCtrl.text.trim(),
            'base_lat': _lat,
            'base_lng': _lng,
          })
          .eq('profile_id', widget.barberProfileId);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.perfilActualizado)));
    } catch (e) {
      if (!mounted) return;
      final loc2 = S.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${loc2.errorGuardando} $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
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
                    Text(S.of(context)!.ofrezcoDomicilio),
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
              onPressed: _onPickOnMap,
              icon: const Icon(Icons.map_outlined),
              label: Text(S.of(context)!.verEnMapa),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // muestra tu texto/dirección actual
                // Text(_baseAddressText ?? _latLngToString(_baseLatLng)),
                const SizedBox(height: 8),
                // Botón para usar ubicación actual — estilado como el botón Guardar
                FilledButton.icon(
                  style: ButtonStyles.redButton,
                  onPressed: _usarUbicacionActual,
                  icon: const Icon(Icons.my_location),
                  label: Text(S.of(context)!.usarmiubicacionctual),
                ),
                const SizedBox(height: 8),

                // Muestra la dirección / coordenadas recogidas
                if ((_addrCtrl.text).isNotEmpty)
                  Text(
                    _addrCtrl.text,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  )
                else if (_lat != null && _lng != null)
                  Text(
                    '${_lat!.toStringAsFixed(6)}, ${_lng!.toStringAsFixed(6)}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  )
                else
                  Text(
                    S.of(context)!.seleccionaBarberiaODomicilio,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),

                const SizedBox(height: 8),
                // Botón específico para guardar sólo la ubicación (mismo estilo que Guardar)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: ButtonStyles.redButton,
                        onPressed: _saving ? null : _guardarUbicacion,
                        child:
                            _saving
                                ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(loc.guardarBtn),
                      ),
                    ),
                  ],
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
                const SizedBox(height: 8),

                // // Instagram
                // --- Instagram ---
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.appBarbkgs,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: SocialField(
                    platform: SocialPlatform.instagram,
                    initial: _instagramCtrl.text, // ✅ usa solo el controlador
                    onChanged:
                        (v) => setState(() => _instagramCtrl.text = v ?? ''),
                  ),
                ),
                const SizedBox(height: 12),

                // --- WhatsApp ---
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.appBarbkgs,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: SocialField(
                    platform: SocialPlatform.whatsapp,
                    initial: _whatsCtrl.text,
                    onChanged: (v) => setState(() => _whatsCtrl.text = v ?? ''),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Facebook ---
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.appBarbkgs,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: SocialField(
                    platform: SocialPlatform.facebook,
                    initial: _facebookCtrl.text,
                    onChanged:
                        (v) => setState(() => _facebookCtrl.text = v ?? ''),
                  ),
                ),
                const SizedBox(height: 12),

                // --- TikTok ---
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.appBarbkgs,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: SocialField(
                    platform: SocialPlatform.tiktok,
                    initial: _tiktokCtrl.text,
                    onChanged:
                        (v) => setState(() => _tiktokCtrl.text = v ?? ''),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- Agenda externa ---

        // --- Integraciones ---
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                style: ButtonStyles.redButton,
                onPressed: () => _linkGoogle(context),
                icon: const Icon(Icons.link),
                label: Text(S.of(context)!.continuarConGoogle),
              ),
              const SizedBox(height: 8),
              if (_googleEmail != null && _googleEmail!.isNotEmpty)
                Text(
                  'Vinculado: $_googleEmail',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
            ],
          ),
        ),

        // --- Botón Guardar general ---
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: ButtonStyles.redButton,
                onPressed: _saving ? null : _guardar,
                child:
                    _saving
                        ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(loc.guardarBtn),
              ),
            ),
          ),
        ),

        // espacio para que no tape el botón inferior (si tu Scaffold lo usa)
        const SliverPadding(padding: EdgeInsets.only(bottom: 88)),
      ],
    );
  }
}
