// pantalla_domicilio_hub.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/text_styles.dart';
import '../generated/l10n.dart';

class PantallaDomicilioHub extends StatelessWidget {
  const PantallaDomicilioHub({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.aDomicilio, style: TextStyles.tittleText)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _HomeTile(
              icon: Icons.home_repair_service,
              title: loc.homeServiciosDomicilioTitle,//'Servicios a domicilio',
              subtitle: loc.homeServiciosDomicilioSubtitle,//'Cortes, afeitado, combos — cerca de tu ubicación',
              onTap: () {
                // Abrimos Servicios con el filtro de domicilio ya activo
                context.push('/servicios_domicilio');
              },
            ),
            const SizedBox(height: 16),
            _HomeTile(
              icon: Icons.person_pin_circle,
              title: loc.homeBarberosDomicilioTitle,//'Barberos a domicilio',
              subtitle: loc.homeBarberosDomicilioSubtitle,//'Barberos que atienden en tu zona',
              onTap: () {
                context.push('/barberos_domicilio');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: AppColors.backgrounds,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyles.listTitle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyles.defaultTex_2),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
