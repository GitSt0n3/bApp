import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
 import '../generated/l10n.dart'; // Ajustá el import según tu estructura de S

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
  Map<String, dynamic>? _barber;   // barbers.*
  Map<String, dynamic>? _profile;  // profiles.*
  List<dynamic> _services = [];     // services activos

  final _money = NumberFormat.currency(locale: 'es', symbol: '\$ ');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final barber = await _supa
          .from('barbers')
          .select('profile_id, bio, home_service, radius_km, base_lat, base_lng, instagram, whatsapp, tiktok')
          .eq('profile_id', widget.barberId)
          .single();

      final profile = await _supa
          .from('profiles')
          .select('id, full_name, avatar_url, phone')
          .eq('id', widget.barberId)
          .single();

      final services = await _supa
          .from('services')
          .select('id, name, price, duration_min, home_service_surcharge, active')
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
    final minSurcharge = widget.minSurcharge ??
        _services
            .map((s) => s['home_service_surcharge'])
            .where((v) => v != null)
            .cast<num>()
            .fold<num?>(null, (min, v) => (min == null || v < min) ? v : min);

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl.isEmpty)
                    ? Text(name.isNotEmpty ? name[0] : '?')
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    if (widget.distanceKm != null)
                      Text(loc.distanceKm(widget.distanceKm!.toStringAsFixed(1))),
                    if (radiusKm != null)
                      Text(loc.coverRadiusKm(radiusKm.toString())),
                    if (minSurcharge != null)
                      Text(loc.homeSurchargeFrom(_money.format(minSurcharge))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bio.isNotEmpty) Text(bio),
          const SizedBox(height: 16),
          // TODO: reemplazar por tus SocialButton si ya los tenés
          Wrap(
            spacing: 8,
            children: [
              if ((_barber?['instagram'] as String?)?.isNotEmpty == true)
                TextButton(onPressed: () {/* launch */}, child: Text('Instagram')),
              if ((_barber?['whatsapp'] as String?)?.isNotEmpty == true)
                TextButton(onPressed: () {/* launch */}, child: const Text('WhatsApp')),
              if ((_barber?['tiktok'] as String?)?.isNotEmpty == true)
                TextButton(onPressed: () {/* launch */}, child: const Text('TikTok')),
            ],
          ),
          const Divider(height: 32),
          Text(loc.servicesTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_services.isEmpty)
            Text(loc.noServicesYet),
          for (final s in _services)
            ListTile(
              title: Text(s['name'] ?? ''),
              subtitle: Text(loc.durationMin((s['duration_min'] ?? 0).toString())),
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_money.format(s['price'] ?? 0)),
                  if (s['home_service_surcharge'] != null)
                    Text(loc.homeSurchargeShort(_money.format(s['home_service_surcharge']))),
                ],
              ),
            ),
          const SizedBox(height: 12),
          
            FilledButton(
              onPressed: () {
                // launchUrl(Uri.parse(weibookUrl!));
              },
              child: Text(loc.reserveInWeiBook),
            ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: () {
              context.push('/servicios?barber=${widget.barberId}');
            },
            child: Text(loc.viewServicesCta),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () {
              context.push('/reservar?barber=${widget.barberId}&home=1');
            },
            child: Text(loc.reserveHomeCta),
          ),
        ],
      ),
    );
  }
}
