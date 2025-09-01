import 'package:barberiapp/core/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../generated/l10n.dart';
import '../core/text_styles.dart';

class PantallaInicio extends StatefulWidget {
  const PantallaInicio({super.key});

  @override
  State<PantallaInicio> createState() => _PantallaInicioState();
}

class _PantallaInicioState extends State<PantallaInicio> {
  String? opcionSeleccionada;

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarbkgs,
        title: Row(
          children: [
            Transform.rotate(
              angle: 3.14, // Gira 180 grados
              child: Image.asset('assets/icons/barber.png', height: 40),
            ),
            const SizedBox(width: 8),
            Text(loc.appTitle, style: TextStyles.tittleText),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _botonConSeleccion(
              id: "Mapa",
              texto: loc.irAMapa,
              iconoAssets: 'assets/icons/map.png',
              onTap: () => context.push('/mapa'),
            ),
            _botonConSeleccion(
              id: "Barberias",
              texto: loc.irABarberias,
              iconoAssets: 'assets/icons/barbershop.png',
              onTap: () => context.push('/barberias'),
            ),
            _botonConSeleccion(
              id: "Turnos",
              texto: loc.irATurnos,
              iconoAssets: 'assets/icons/turno.png',
              onTap: () => context.push('/servicios'),
            ),
            _botonConSeleccion(
              id: "Domicilio",
              texto: loc.irADomicilio,
              iconoAssets: 'assets/icons/home.png',
              onTap: () => context.push('/domicilio'),
            ),
            _botonConSeleccion(
              id: "SoyBarbero",
              texto: loc.soyBarbero,
              iconoAssets: 'assets/icons/imbarber.png',
              onTap: () => context.push('/barbero/auth'),
            ),
            _botonConSeleccion(
              id: "Soporte",
              texto: loc.soporte,
              iconoAssets: 'assets/icons/support.png',
              onTap: () => context.push('/soporte'),
            ),
            // banner inferior           
          ],
        ),   
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _bannerInferior(),
      ),
    );
  }

  Widget _bannerInferior() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black, Colors.black],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
     //   border: Border(top: BorderSide(color: Colors.red.shade700, width: 2)),
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
        setState(() {
          opcionSeleccionada = id;
        });
        onTap(); // navega después de cambiar el estado
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
              offset: Offset(2, 2),
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
