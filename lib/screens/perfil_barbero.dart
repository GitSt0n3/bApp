// (archivo completo, actualizado: usa full_name y google_email en el join,
// normaliza google_email, y PRIORIZA isnull de profiles.google_email al decidir el estado
// del botón cuando se visualiza el propio perfil)
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../generated/l10n.dart';
import 'package:barberiapp/core/section_card.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/social_button.dart';
import 'package:barberiapp/core/button_styles.dart';
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

  // sesión actual
  String? _currentUserId;
  String? _googleEmail; // email google de la sesión actual (si existe)

  // barber being viewed
  String? _fullName;
  String? _barberGoogleEmail; // email google guardado en profiles para ese barber (si existe)

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

  // Helper: normaliza valores nulos/strings "null"/vacíos a null
  String? _normalizeNullableString(dynamic v) {
    if (v == null) return null;
    final s = v is String ? v.trim() : v.toString().trim();
    if (s.isEmpty) return null;
    if (s.toLowerCase() == 'null') return null;
    return s;
  }

  // Helper: valida forma de email simple
  bool _looksLikeEmail(String? s) {
    if (s == null) return false;
    final emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRe.hasMatch(s.trim());
  }

  // Helper para extraer email Google desde user/identities
  String? _extractGoogleEmailFromUser(dynamic user) {
    if (user == null) return null;
    try {
      final identities =
          (user.identities ?? (user is Map ? user['identities'] : null));
      if (identities is List) {
        for (final id in identities) {
          if (id is Map) {
            final provider = (id['provider'] as String?) ?? '';
            if (provider == 'google') {
              final identityData = id['identity_data'] as Map<String, dynamic>?;
              final email = identityData?['email'] as String?;
              if (email != null && email.isNotEmpty) return email;
            }
          } else {
            try {
              final provider = (id as dynamic).provider as String?;
              if (provider == 'google') {
                final identityData =
                    (id as dynamic).identityData as Map<String, dynamic>?;
                final email = identityData?['email'] as String?;
                if (email != null && email.isNotEmpty) return email;
              }
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

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
      debugPrint('[_linkGoogle] before link: currentUser id = ${_supa.auth.currentUser?.id}');
      final ok = await Supabase.instance.client.auth.linkIdentity(
        OAuthProvider.google,
        redirectTo: 'com.barberiapp://login-callback',
        queryParams: {'prompt': 'select_account'},
      );

      debugPrint('[_linkGoogle] linkIdentity returned: $ok');

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

      // Intento de refrescar usuario después de corto delay (el callback puede tardar)
      Future.delayed(const Duration(seconds: 2), () async {
        try {
          final userResp = await _supa.auth.getUser();
          debugPrint('[_linkGoogle] getUser() after link (delayed): ${userResp.user}');
          final extractedRaw = _extractGoogleEmailFromUser(
            userResp.user ?? (userResp as dynamic)?.data,
          );
          final extracted = _normalizeNullableString(extractedRaw);
          debugPrint('[_linkGoogle] extracted google email after link: $extracted');

          // actualizar estado de sesión
          if (!mounted) return;
          setState(() {
            _googleEmail = extracted;
            _currentUserId = (userResp.user as dynamic?)?.id ?? _supa.auth.currentUser?.id;
          });

          // IMPORTANT: si existe columna profiles.google_email, intentamos actualizar el perfil
          try {
            final userId = (userResp.user as dynamic?)?.id as String?;
            if (extracted != null && userId != null) {
              debugPrint('[_linkGoogle] updating profiles.google_email for user $userId -> $extracted');
              await _supa.from('profiles').update({'google_email': extracted}).eq('id', userId);
              // Forzar recarga del perfil mostrado si es nuestro propio perfil
              if (mounted && widget.barberProfileId.toString().trim() == userId.toString().trim()) {
                await _load();
              }
            }
          } catch (e, st) {
            debugPrint('[_linkGoogle] error updating profiles.google_email: $e\n$st');
          }
        } catch (e, st) {
          debugPrint('[_linkGoogle] error fetching user after link: $e\n$st');
        }
      });

      // Otro intento de refresco
      Future.delayed(const Duration(seconds: 4), () async {
        try {
          final userResp = await _supa.auth.getUser();
          debugPrint('[_linkGoogle] getUser() after link (delayed 2): ${userResp.user}');
          final extractedRaw = _extractGoogleEmailFromUser(
            userResp.user ?? (userResp as dynamic)?.data,
          );
          final extracted = _normalizeNullableString(extractedRaw);
          debugPrint('[_linkGoogle] extracted google email after link (2): $extracted');
          if (!mounted) return;
          setState(() => _googleEmail = extracted);
        } catch (e) {
          debugPrint('[_linkGoogle] error 2 fetching user after link: $e');
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

  // Construye el botón de Integraciones (Google) con estado dinámico y estilo
  Widget _buildGoogleIntegrationButton(BuildContext context) {
    // Google brand blue: #4285F4
    const googleBlue = Color(0xFF4285F4);

    // Normalize/validate email values before decision
    final normalizedBarberEmail = _normalizeNullableString(_barberGoogleEmail);
    final normalizedSessionEmail = _normalizeNullableString(_googleEmail);

    final barberIsLinked = _looksLikeEmail(normalizedBarberEmail);
    final sessionIsLinked = _looksLikeEmail(normalizedSessionEmail);

    final viewingOwnProfile = (_currentUserId != null &&
        widget.barberProfileId.toString().trim() == _currentUserId.toString().trim());

    // debug info to logs so you can paste here if something still wrong
    debugPrint('[_debug google-state] viewingOwnProfile=$viewingOwnProfile '
        'widget.barberProfileId=${widget.barberProfileId.toString().trim()} _currentUserId=${_currentUserId?.toString().trim()} '
        'barberEmail=$normalizedBarberEmail barberIsLinked=$barberIsLinked '
        'sessionEmail=$normalizedSessionEmail sessionIsLinked=$sessionIsLinked');

    if (!viewingOwnProfile) {
      // Mostrar estado del barber (barberGoogleEmail) de forma deshabilitada
      if (barberIsLinked) {
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
          label: const Text('Vinculado con Google'),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.black87,
            disabledForegroundColor: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        );
      } else {
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.link, color: Colors.grey),
          label: const Text('No vinculado con Google'),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.grey.shade100,
            foregroundColor: Colors.black54,
            disabledForegroundColor: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        );
      }
    } else {
      // Aquí priorizamos el campo profiles.google_email (isnull) como fuente de verdad:
      // - Si profiles.google_email existe y es email válido -> "Vinculado"
      // - Si profiles.google_email es NULL/empty -> mostramos el botón para "Conectar con Google"
      //   (aunque la sesión local tenga identidad google, el campo en profiles debe existir para marcarlo como vinculado)
      if (barberIsLinked) {
        // profiles.google_email existe y es válido
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
          label: const Text('Vinculado con Google'),
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.grey.shade200,
            foregroundColor: Colors.black87,
            disabledForegroundColor: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 12),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        );
      } else {
        // profiles.google_email es NULL/empty -> mostrar Conectar (isnull)
        return ElevatedButton.icon(
          onPressed: () => _linkGoogle(context),
          icon: Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Center(
              child: Text(
                'G',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: googleBlue,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          label: const Text('Conectar con Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: googleBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );
      }
    }
  }

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

  // Reemplaza sólo la función _load() por esta implementación más tolerante a errores.
  Future<void> _load() async {
    debugPrint('[ _load ] barberProfileId = ${widget.barberProfileId}');

    // --- Obtener user local y setear _googleEmail / _currentUserId (solo la sesión actual) ---
    try {
      final userResp = await _supa.auth.getUser();
      debugPrint('[ _load ] getUser() raw: ${userResp.user}');
      final extractedRaw = _extractGoogleEmailFromUser(
        userResp.user ?? (userResp as dynamic)?.data,
      );
      final extracted = _normalizeNullableString(extractedRaw);
      debugPrint('[ _load ] extracted google email (session): $extracted');
      _currentUserId = (userResp.user as dynamic?)?.id ?? _supa.auth.currentUser?.id;
      if (mounted) setState(() {
        _googleEmail = extracted;
      });
    } catch (e, st) {
      debugPrint('[ _load ] error getUser(): $e\n$st');
    }

    try {
      // Intentamos la consulta "ideal" con join (profiles(full_name,google_email))
      try {
        final row = await _supa
            .from('barbers')
            .select(
              'home_service,radius_km,base_address,base_lat,base_lng,'
              'instagram_url,whatsapp,facebook_url,tiktok_url,booking_app,booking_url,'
              'profiles(full_name,google_email)',
            )
            .eq('profile_id', widget.barberProfileId)
            .maybeSingle();

        debugPrint('[ _load ] barbers row raw (join attempt): $row');

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

          final profilesRaw = row['profiles'];
          debugPrint('[ _load ] profiles raw from join: $profilesRaw');

          if (profilesRaw != null) {
            if (profilesRaw is List && profilesRaw.isNotEmpty) {
              final prof = profilesRaw.first as Map<String, dynamic>;
              _fullName = (prof['full_name'] ?? '') as String?;
              _barberGoogleEmail = _normalizeNullableString(prof['google_email']);
            } else if (profilesRaw is Map) {
              _fullName = (profilesRaw['full_name'] ?? '') as String?;
              _barberGoogleEmail = _normalizeNullableString(profilesRaw['google_email']);
            }
          }
        } else {
          debugPrint('[ _load ] no barbers row found for profile_id=${widget.barberProfileId} (join attempt)');
        }

        // Si row fue null o profiles no vino, seguiremos a fallback sólo si hace falta.
        final needFallback = (_fullName == null && _barberGoogleEmail == null);
        if (!needFallback) {
          // Ya conseguimos datos útiles: salimos de la función.
          if (mounted) setState(() => _loading = false);
          return;
        }
        debugPrint('[ _load ] needFallback after join attempt: $needFallback');
      } catch (e, st) {
        // Error en la consulta con join (posible columna inexistente o RLS)
        debugPrint('[ _load ] join query failed: $e\n$st');
        // continuamos al fallback
      }

      // --- Fallback seguro: leer barbers sin join y luego profiles por separado ---
      try {
        final row = await _supa
            .from('barbers')
            .select(
              'home_service,radius_km,base_address,base_lat,base_lng,'
              'instagram_url,whatsapp,facebook_url,tiktok_url,booking_app,booking_url',
            )
            .eq('profile_id', widget.barberProfileId)
            .maybeSingle();

        debugPrint('[ _load ] barbers row raw (fallback): $row');

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
        } else {
          debugPrint('[ _load ] no barbers row found for profile_id=${widget.barberProfileId} (fallback)');
        }

        // Intentamos leer profile por separado
        try {
          final profile = await _supa
              .from('profiles')
              .select('full_name,google_email')
              .eq('id', widget.barberProfileId)
              .maybeSingle();
          debugPrint('[ _load ] profile fetch raw fallback: $profile');
          if (profile != null) {
            _fullName = (profile['full_name'] ?? '') as String?;
            _barberGoogleEmail = _normalizeNullableString(profile['google_email']);
          }
        } catch (e, st) {
          debugPrint('[ _load ] error fetching profile fallback: $e\n$st');
        }
      } catch (e, st) {
        debugPrint('[ _load ] error in fallback barbers query: $e\n$st');
        // Mostrar mensaje al usuario (manteniendo UX)
        if (mounted) {
          final loc = S.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.errorCargandoPerfil} $e')),
          );
        }
      }
    } catch (e, st) {
      debugPrint('[ _load ] unexpected error: $e\n$st');
      if (mounted) {
        final loc = S.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorCargandoPerfil} $e')),
        );
      }
    } finally {
      // siempre quitamos el loading para que la UI muestre algo (o el mensaje de error)
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

    final displayName = (_fullName != null && _fullName!.trim().isNotEmpty)
        ? _fullName!.trim()
        : 'Nombre no disponible';

    String initials = '';
    if (_fullName != null && _fullName!.trim().isNotEmpty) {
      final parts = _fullName!.trim().split(RegExp(r'\s+'));
      if (parts.isNotEmpty && parts.first.isNotEmpty) initials += parts.first[0].toUpperCase();
      if (parts.length > 1 && parts.last.isNotEmpty) initials += parts.last[0].toUpperCase();
    } else {
      initials = '?';
    }

    return CustomScrollView(
      slivers: [
        // Nueva tarjeta superior con nombre/apellidos
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials.isNotEmpty ? initials : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Mostrar el email vinculado del BARBER (si existe y es email válido),
                          // si no, mostrar el de sesión (si es tu perfil y es válido)
                          if (_normalizeNullableString(_barberGoogleEmail) != null && _looksLikeEmail(_barberGoogleEmail))
                            Text(
                              _barberGoogleEmail!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            )
                          else if ((_currentUserId != null && widget.barberProfileId.toString().trim() == _currentUserId.toString().trim()) &&
                              _normalizeNullableString(_googleEmail) != null &&
                              _looksLikeEmail(_googleEmail))
                            Text(
                              _googleEmail!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

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
                const SizedBox(height: 8),
                FilledButton.icon(
                  style: ButtonStyles.redButton,
                  onPressed: _usarUbicacionActual,
                  icon: const Icon(Icons.my_location),
                  label: Text(S.of(context)!.usarmiubicacionctual),
                ),
                const SizedBox(height: 8),

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
                    initial: _instagramCtrl.text,
                    onChanged:
                        (v) => setState(() => _instagramCtrl.text = v ?? ''),
                  ),
                ),
                const SizedBox(height: 12),

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

        // --- Integraciones ---
        SliverToBoxAdapter(
          child: SectionCard(
            title: S.of(context)!.profile_section_integrations,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contenedor con estilo consistente con las otras entradas (Instagram/FB/TikTok)
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón dinámico para Google (ver _buildGoogleIntegrationButton)
                      _buildGoogleIntegrationButton(context),
                      const SizedBox(height: 8),
                      // Mostrar email vinculado del barber (si existe y es email válido)
                      if (_normalizeNullableString(_barberGoogleEmail) != null && _looksLikeEmail(_barberGoogleEmail))
                        Text(
                          'Vinculado: $_barberGoogleEmail',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      // Debug small panel in debug builds
                      if (kDebugMode)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'DEBUG: barberId=${widget.barberProfileId.toString().trim()} '
                            'currentUserId=${_currentUserId?.toString().trim() ?? "null"} '
                            'barberGoogle=${_barberGoogleEmail ?? "null"} '
                            'sessionGoogle=${_googleEmail ?? "null"}',
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
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