import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../generated/l10n.dart'; // Ajustá el import según tu estructura de S
import 'package:barberiapp/core/button_styles.dart';
import 'package:barberiapp/core/text_styles.dart';
import 'package:barberiapp/core/social_button.dart';

class PerfilBarberoPublic extends StatefulWidget {
  final String barberId;
  final double? distanceKm;
  final num? minSurcharge;

  const PerfilBarberoPublic({
    super.key,
    required this.barberId,
    this.distanceKm,
    this.minSurcharge,
  });

  @override
  State<PerfilBarberoPublic> createState() => _PerfilBarberoPublicState();
}

class _PerfilBarberoPublicState extends State<PerfilBarberoPublic> {
  final _supa = Supabase.instance.client;
  bool _loading = true;
  Map<String, dynamic>? _barber; // barbers.*
  Map<String, dynamic>? _profile; // profiles.*
  List<dynamic> _services = []; // services activos

  final _money = NumberFormat.currency(locale: 'es', symbol: '\$ ');
  // --- Helpers sociales (dentro del State) -------------------------------

  // Toma el primer campo no vacío (por si en BD usás nombres alternativos)
  String? _firstNonEmpty(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = (m[k] ?? '').toString().trim();
      if (v.isNotEmpty) return v;
    }
    return null;
  }

  // Normaliza URL si viene sin http/https
  String? _normalizeUrl(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    return 'https://$v';
  }

  // 🔹 Acá “va el string de WhatsApp”:
  // Le pasás lo que venga de BD en `whatsapp` (número o URL).
  // Si es número → arma https://wa.me/<numero>; si ya es URL → la usa tal cual.
  String? _whatsAppLink(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v.isEmpty) return null;

    if (v.startsWith('http://') || v.startsWith('https://')) return v;

    final digits = v.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.isEmpty) return null;

    final normalized = digits.startsWith('+') ? digits.substring(1) : digits;
    return 'https://wa.me/$normalized';
  }

  // Construye la fila de íconos según lo que haya en _barber
  Widget _buildSocialRow(Map<String, dynamic> data) {
    final ig = _normalizeUrl(
      _firstNonEmpty(data, ['instagram', 'instagram_url', 'ig']),
    );
    final fb = _normalizeUrl(
      _firstNonEmpty(data, ['facebook', 'facebook_url', 'fb']),
    );
    final tk = _normalizeUrl(
      _firstNonEmpty(data, ['tiktok', 'tiktok_url', 'tt', 'tk']),
    );
    final wa = _whatsAppLink(
      _firstNonEmpty(data, ['whatsapp', 'whatsapp_phone', 'wa']),
    );

    final children = <Widget>[];
    if (ig != null) {
      children.add(
        SocialButton(
          assetPath: 'assets/icons/social/Instagram.png',
          url: ig,
          size: 24,
        ),
      );
    }
    if (fb != null) {
      children.add(
        SocialButton(
          assetPath: 'assets/icons/social/facebook.png',
          url: fb,
          size: 24,
        ),
      );
    }
    if (tk != null) {
      children.add(
        SocialButton(
          assetPath: 'assets/icons/social/tiktok.png',
          url: tk,
          size: 24,
        ),
      );
    }
    if (wa != null) {
      children.add(
        SocialButton(
          assetPath: 'assets/icons/social/whatsapp.png',
          url: wa,
          size: 24,
        ),
      );
    }

    if (children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(spacing: 12, runSpacing: 8, children: children),
    );
  }
  // ----------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final barber =
          await _supa
              .from('barbers')
              .select(
                'profile_id, bio, home_service, radius_km, base_lat, base_lng, instagram_url, whatsapp, tiktok_url, facebook_url',
              )
              .eq('profile_id', widget.barberId)
              .single();

      final profile =
          await _supa
              .from('profiles')
              .select('id, full_name,  phone')
              .eq('id', widget.barberId)
              .single();

      final services = await _supa
          .from('services')
          .select(
            'id, name, price, duration_min, home_service_surcharge, active',
          )
          .eq('barber_id', widget.barberId)
          .eq('active', true)
          .order('price', ascending: true);

      if (!mounted) return;
      setState(() {
        _barber = barber;
        _profile = profile;
        _services = (services as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final loc = S.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.errLoadingProfile(e.toString()))),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.barberPublicTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final name = _profile?['full_name'] as String? ?? loc.unknownBarber;
    final bio = _barber?['bio'] as String? ?? '';
    final radiusKm = _barber?['radius_km'] as num?;
    final minSurcharge =
        widget.minSurcharge ??
        _services
            .map((s) => s['home_service_surcharge'])
            .where((v) => v != null)
            .cast<num>()
            .fold<num?>(null, (min, v) => (min == null || v < min) ? v : min);

    return Scaffold(
      appBar: AppBar(title: Text(name, style: TextStyles.tittleText)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Image.asset(
                'assets/icons/imbarber.png',
                width: 72, // ajustá el tamaño a gusto
                height: 72,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyles.subtitleText),
                    if (widget.distanceKm != null)
                      Text(
                        loc.distanceKm(widget.distanceKm!.toStringAsFixed(1)),
                        style: TextStyles.defaultTex_2,
                      ),
                    if (radiusKm != null)
                      Text(
                        loc.coverRadiusKm(radiusKm.toString()),
                        style: TextStyles.bodyText,
                      ),
                    if (minSurcharge != null)
                      Text(
                        loc.homeSurchargeFrom(_money.format(minSurcharge)),
                        style: TextStyles.bodyText,
                      ),
                    if (_barber != null) _buildSocialRow(_barber!),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 16),
      
          
          const SizedBox(height: 12),
          // (El botón "Reservar en WeiBook" fue eliminado)
          const SizedBox(height: 8),
          FilledButton(
            style: ButtonStyles.redButton,
            onPressed: () {
              context.push('/servicios?barber=${widget.barberId}');
            },
            child: Text(loc.viewServicesCta, style: TextStyles.defaultTex_2),
          ),
        ],
      ),
    );
  }
}
