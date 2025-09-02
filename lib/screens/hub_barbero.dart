import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:barberiapp/core/button_styles.dart';
import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/text_styles.dart';
import 'package:barberiapp/generated/l10n.dart';

class HubBarbero extends StatefulWidget {
  const HubBarbero({super.key});

  @override
  State<HubBarbero> createState() => _HubBarberoState();
}

class _HubBarberoState extends State<HubBarbero> {
  String? opcionSeleccionada;

  bool _isOwner = false;
  bool _isStaff = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    try {
      final supa = Supabase.instance.client;
      final uid = supa.auth.currentUser?.id;
      if (uid == null) return;

      final rows = await supa
          .from('barbershop_members')
          .select('role')
          .eq('barber_id', uid);

      setState(() {
        _isOwner = rows.any((m) => m['role'] == 'owner');
        _isStaff = rows.any((m) => m['role'] == 'staff');
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } finally {
      if (!mounted) return;
      context.go('/'); // o '/barbero/auth' si preferís
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    final freelance = !_isOwner && !_isStaff;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarbkgs,
        title: Row(
          children: [
            Transform.rotate(
              angle: 3.14,
              child: Image.asset('assets/icons/barber.png', height: 40),
            ),
            const SizedBox(width: 8),
            Text(loc.panelBarberoTitulo, style: TextStyles.tittleText),
          ],
        ),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          _botonConSeleccion(
                            id: "BarberiasPublicas",
                            texto: loc.irABarberias, // "Barberías"
                            iconoAssets: 'assets/icons/barbershop.png',
                            onTap: () => context.push('/barberias'),
                          ),
                          _botonConSeleccion(
                            id: "MisBarberias",
                            texto:
                                freelance
                                    ? loc.configurarMiBarberia
                                    : loc.misBarberias,
                            iconoAssets:
                                'assets/icons/barbershop_user_badge.png',
                            onTap: () => context.push('/mis_barberias_tab'),
                          ),
                          _botonConSeleccion(
                            id: "Turnos",
                            texto: loc.turnos,
                            iconoAssets: 'assets/icons/turno.png',
                            onTap: () => context.push('/turnos_barbero'),
                          ),
                          _botonConSeleccion(
                            id: "Servicios",
                            texto: loc.servicios,
                            iconoAssets: 'assets/icons/barber_icon.png',
                            onTap: () => context.push('/servicios_b'),
                          ),
                          _botonConSeleccion(
                            id: "Perfil",
                            texto: loc.miPerfil,
                            iconoAssets: 'assets/icons/barber_icon.png',
                            onTap: () {
                              final barberId =
                                  Supabase.instance.client.auth.currentUser!.id;
                              context.pushNamed(
                                'perfilBarbero',
                                pathParameters: {'barberId': barberId},
                              );
                            },
                          ),

                          _botonConSeleccion(
                            id: "Soporte",
                            texto: loc.soporte,
                            iconoAssets: 'assets/icons/support.png',
                            onTap: () => context.push('/soporte'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: ButtonStyles.redButton,
                        onPressed: _logout, // tu función de cerrar sesión
                        child: Text(loc.cerrarSesion),
                      ),
                    ),
                  ],
                ),
              ),
      bottomNavigationBar: SafeArea(top: false, child: _bannerInferior()),
    );
  }

  Widget _bannerInferior() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 1),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/icons/barberiapp.png', height: 150),
          const SizedBox(height: 5),
        ],
      ),
    );
  }

  Widget _botonConSeleccion({
    required String id,
    required String texto,
    String? iconoAssets,
    required VoidCallback onTap,
  }) {
    final estaSeleccionado = opcionSeleccionada == id;

    return GestureDetector(
      onTap: () {
        setState(() => opcionSeleccionada = id);
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color:
              estaSeleccionado
                  ? AppColors.backgroundComponentSelected
                  : AppColors.backgroundComponent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black26),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconoAssets != null)
              Image.asset(iconoAssets, width: 90, height: 90),
            const SizedBox(height: 8),
            Text(
              texto,
              style: TextStyles.buttonText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
