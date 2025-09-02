// pubspec.yaml: url_launcher
// flutter pub add url_launcher

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../generated/l10n.dart';
//test
class PantallaPerfilBarberia extends StatefulWidget {
  final int barbershopId;
  const PantallaPerfilBarberia({super.key, required this.barbershopId});

  @override
  State<PantallaPerfilBarberia> createState() => _PantallaPerfilBarberiaState();
}

class _PantallaPerfilBarberiaState extends State<PantallaPerfilBarberia> {
  final _supa = Supabase.instance.client;
  Map<String, dynamic>? _shop;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final q = _supa
          .from('barbershops')
          .select(r'''
          id,
          name,
          address,
          instagram_url,
          facebook_url,
          tiktok_url,
          external_booking_url,
          owner_whatsapp,
          barbershop_members (
            role,
            barber:barbers!barbershop_members_barber_id_fkey (
              bio,
              home_service,
              radius_km,
              profile:profiles!barbers_profile_id_fkey (
                id,
                full_name,
                phone
              )
            )
          )
        ''')
          .eq('id', widget.barbershopId)
          .limit(1);

      // maybeSingle() evita throw si no hay fila
      final row = await q.maybeSingle();

      if (!mounted) return;
      setState(() {
        _shop = row as Map<String, dynamic>?;
        _loading = false;
      });
    } catch (e, st) {
      // Para depurar rápido en consola y mostrar algo en UI
      debugPrint('Supabase error: $e\n$st');
      if (!mounted) return;
      final loc = S.of(context)!;
      setState(() {
        _shop = null;
        _loading = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorCargandoBarberia} $e')),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(String e164) async {
    final url = _waUrl(
      e164,
      msg: 'Hola, vengo de BarberiApp. ¿Tienen turnos esta semana?',
    );
    await _openUrl(url);
  }

  String _waUrl(String e164, {String? msg}) {
    final text = Uri.encodeComponent(msg ?? 'Hola, vengo de BarberiApp.');
    return 'https://wa.me/$e164?text=$text';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_shop == null) {
      return Scaffold(
        body: Center(child: Text(S.of(context)!.barberiaNoEncontrada)),
        //  body: Center(child: Text('Barberia no encontrada.')),
      );
    }

    final name = _shop!['name'] as String;
    final address = _shop!['address'] as String?;
    final ig = _shop!['instagram_url'] as String?;
    final fb = _shop!['facebook_url'] as String?;
    final tk = _shop!['tiktok_url'] as String?;
    final ext = _shop!['external_booking_url'] as String?;
    final wa = _shop!['owner_whatsapp'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Encabezado con icono genérico
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.store,
                  size: 42,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ],
          ),
          if (address != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(address)),
              ],
            ),
          ],

          const SizedBox(height: 16),
          // Enlaces sociales / externos
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (ig != null && ig.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Instagram'),
                  onPressed: () => _openUrl(ig),
                ),
              if (fb != null && fb.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.facebook),
                  label: const Text('Facebook'),
                  onPressed: () => _openUrl(fb),
                ),
              if (tk != null && tk.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.music_note),
                  label: const Text('TikTok'),
                  onPressed: () => _openUrl(tk),
                ),
              if (wa != null && wa.isNotEmpty)
                if (wa != null && wa.isNotEmpty)
                  ElevatedButton.icon(
                    onPressed: () => _openWhatsApp(wa),
                    icon: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      color: Colors.green,
                    ),
                    label: const Text("WhatsApp"),
                  ),
              if (ext != null && ext.isNotEmpty)
                OutlinedButton.icon(
                  icon: const Icon(Icons.link),
                 // label: Text(S.of(context)!.reservarExterno),
                  label: Text('Reservar (externo)'),
                  onPressed: () => _openUrl(ext),
                ),
            ],
          ),

          const SizedBox(height: 24),
          // CTA: Ver servicios (filtrados por esta barbería)
          FilledButton.icon(
            icon: const Icon(Icons.design_services),
            //label: Text(S.of(context)!.verServicios),
            label: Text('Ver Servicios'),
            onPressed: () {
              context.push(
                '/servicios',
                extra: {'barbershopId': widget.barbershopId},
              );
            },
          ),

          const SizedBox(height: 16),
          // Sección Barberos (placeholder MVP)
          const Text('Barberos', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Próximamente: listado de staff con link a su perfil.'),
        ],
      ),
    );
  }
}
