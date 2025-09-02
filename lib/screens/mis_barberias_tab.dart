import 'package:flutter/material.dart';
import 'package:barberiapp/core/text_styles.dart';
import '../services/barbershops_service.dart';      // servicio Supabase
import 'crear_barberia.dart';               // la pantalla de crear
import 'gestion_staff_screen.dart';
import 'package:barberiapp/generated/l10n.dart';


// Cuando tengas hecha la gestión de staff, descomentá este import:
// import 'gestion_staff_screen.dart';
class MisBarberiasTab extends StatefulWidget {
  const MisBarberiasTab({super.key});
  @override
  State<MisBarberiasTab> createState() => _MisBarberiasTabState();
}

class _MisBarberiasTabState extends State<MisBarberiasTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = BarbershopsService.misBarberias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context)!.configurarMiBarberiaTitulo),),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CrearBarberiaScreen()),
        ).then((_) => setState(() => _future = BarbershopsService.misBarberias())),
        label: Text(S.of(context)!.crearBarberia),
        icon: const Icon(Icons.add_business),
      ),
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          if (items.isEmpty) {
            return _estadoVacio(context); // freelance
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (_, i) {
              final role = items[i]['role'] as String;
              final shop = items[i]['barbershops'] as Map<String, dynamic>;
              return ListTile(
                title: Text(shop['name']),
                subtitle: Text('${shop['address']}  ·  $role'),
                trailing: role == 'owner'
                    ? PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'staff') {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (_) => GestionStaffScreen(shopId: shop['id'], shopName: shop['name']),
                            ));
                          } else if (v == 'editar') {
                            // TODO edición básica (nombre/dirección)
                          } else if (v == 'eliminar') {
                            await BarbershopsService.eliminarBarberia(
                              shopId: shop['id'],
                              context: context,
                            );
                            setState(() => _future = BarbershopsService.misBarberias());
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'staff', child: Text('Gestionar barberos')),
                          PopupMenuItem(value: 'editar', child: Text('Editar datos')),
                          PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                        ],
                      )
                    : null,
              );
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: items.length,
          );
        },
      ),
    );
  }

  Widget _estadoVacio(BuildContext context) {
    final loc = S.of(context)!;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(loc.sinBarberiasVinculadas),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CrearBarberiaScreen()),
          ).then((_) => setState(() => _future = BarbershopsService.misBarberias())),
          child: Text(loc.crearMiBarberia),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            // (V2) solicitar vínculo a una existente
          },
          child: Text(loc.solicitarVinculoProximamente),
        ),
      ]),
    );
  }
}
