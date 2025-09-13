import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../generated/l10n.dart'; // Ajustá el import según tu estructura de S
import 'package:barberiapp/core/button_styles.dart';
import 'package:barberiapp/core/text_styles.dart';

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
    final avatarUrl = _profile?['avatar_url'] as String?;
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
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          const SizedBox(height: 16),
          // TODO: reemplazar por tus SocialButton si ya los tenés
          Wrap(
            spacing: 8,
            children: [
              if ((_barber?['instagram'] as String?)?.isNotEmpty == true)
                TextButton(
                  onPressed: () {
                    /* launch */
                  },
                  child: const Text('Instagram'),
                ),
              if ((_barber?['whatsapp'] as String?)?.isNotEmpty == true)
                TextButton(
                  onPressed: () {
                    /* launch */
                  },
                  child: const Text('WhatsApp'),
                ),
              if ((_barber?['tiktok'] as String?)?.isNotEmpty == true)
                TextButton(
                  onPressed: () {
                    /* launch */
                  },
                  child: const Text('TikTok'),
                ),
            ],
          ),

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
