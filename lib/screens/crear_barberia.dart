import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../widgets/map_picker.dart';
import '../services/barbershops_service.dart';
import 'package:barberiapp/generated/l10n.dart';

class CrearBarberiaScreen extends StatefulWidget {
  const CrearBarberiaScreen({super.key});
  @override
  State<CrearBarberiaScreen> createState() => _CrearBarberiaScreenState();
}

class _CrearBarberiaScreenState extends State<CrearBarberiaScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _direccion = TextEditingController();
  LatLng? _picked;
  bool _loading = false;

  @override
  void dispose() {
    _nombre.dispose();
    _direccion.dispose();
    super.dispose();
  }

  Future<void> _pickOnMap() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MapPicker(initial: _picked ?? const LatLng(-34.9011, -56.1645))),
    );
    if (res != null) {
      setState(() => _picked = LatLng(res.lat, res.lon));
      _direccion.text = res.address ?? '${res.lat.toStringAsFixed(6)}, ${res.lon.toStringAsFixed(6)}';
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_picked == null) {
      final loc = S.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.seleccionaUbicacion)));
      return;
    }
    setState(() => _loading = true);
    try {
      await BarbershopsService.crearBarberiaPropia(
        name: _nombre.text,
        address: _direccion.text,
        lat: _picked!.latitude,
        lng: _picked!.longitude,
        context: context,
      );
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.crearBarberia)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            children: [
              TextFormField(
                controller: _nombre,
                decoration:  InputDecoration(labelText: loc.nombre),
                validator: (v) => (v == null || v.isEmpty) ? loc.requerido : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _direccion,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: loc.direccion,
                  suffixIcon: IconButton(icon: const Icon(Icons.map), onPressed: _pickOnMap),
                ),
                validator: (v) => (v == null || v.isEmpty) ? loc.seleccionaEnMapa : null,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading ? const CircularProgressIndicator() : Text(loc.crear),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
