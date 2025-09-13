import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/button_styles.dart';
import 'package:barberiapp/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/map_picker.dart';
import '../services/auth_Service.dart';
import 'package:barberiapp/generated/l10n.dart';

const kOAuthRedirectUri = 'com.barberiapp://login-callback/'; // <- igual al que pusiste en Supabase




class BarberAuthScreen extends StatelessWidget {
  const BarberAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.appBarbkgs,
        appBar: AppBar(
          title: Text(loc.barberoAuthTitulo, style: TextStyles.tittleText),
          backgroundColor: AppColors.appBarbkgs,
          bottom: TabBar(
            labelStyle: TextStyles.defaultText,
            tabs: [Tab(text: loc.iniciarSesion), Tab(text: loc.registrarme)],
          ),
        ),
        body: const TabBarView(children: [_LoginForm(), _RegisterForm()]),
      ),
    );
  }
}



class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.login(_email.text, _password.text, context);
      // TODO: navegar al panel si querés
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _email,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              validator:
                  (v) =>
                      (v == null || !v.contains('@'))
                          ? loc.emailInvalido
                          : null,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _password,
              style: const TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                labelText: loc.contrasenaLabel,
                labelStyle: TextStyle(color: Colors.white70),
              ),
              validator:
                  (v) =>
                      (v == null || v.length < 6) ? loc.contrasenaMin6 : null,
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: ButtonStyles.redButton,
                onPressed: _loading ? null : _submit,
                child:
                    _loading
                        ? const CircularProgressIndicator()
                        : Text(loc.entrar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum RegistroModo { unirme, domicilio, crear }

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();
  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _nombreBarberia = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _repassword = TextEditingController();
  final _direccionCtrl = TextEditingController();
  LatLng? _picked;
  bool _domicilio = true;
  bool _loading = false;
  // estado nuevo

  @override
  void dispose() {
    _nombre.dispose();
    _nombreBarberia.dispose();
    _telefono.dispose();
    _email.dispose();
    _password.dispose();
    _repassword.dispose();
    _direccionCtrl.dispose();
    super.dispose();
  }

  // ← ABRE el mapa y completa dirección + _picked
  Future<void> _pickOnMap() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => MapPicker(
              initial: _picked ?? const LatLng(-34.71522, -55.95244),
            ),
      ),
    );
    if (res != null) {
      setState(() => _picked = LatLng(res.lat, res.lon));
      _direccionCtrl.text =
          res.address ??
          '${res.lat.toStringAsFixed(6)}, ${res.lon.toStringAsFixed(6)}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService.registerBarberBasico(
        nombre: _nombre.text,
        telefono: _telefono.text,
        email: _email.text,
        password: _password.text,
        homeService: _domicilio,
        context: context,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = S.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nombre,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: loc.nombreApellidoLabel,
                labelStyle: TextStyle(color: Colors.white70),
              ),
              validator: (v) => (v == null || v.isEmpty) ? loc.requerido : null,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: loc.telefonoLabel,
                labelStyle: TextStyle(color: Colors.white70),
              ),
              validator:
                  (v) =>
                      (v == null || v.length < 7) ? loc.telefonoInvalido : null,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Colors.white70),
              ),
              validator:
                  (v) =>
                      (v == null || !v.contains('@')) ? loc.emailInvalido : null,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _password,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: loc.contrasenaLabel,
                labelStyle: TextStyle(color: Colors.white70),
              ),
              validator:
                  (v) =>
                      (v == null || v.length < 6)
                          ? loc.contrasenaMin6
                          : null,
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _repassword,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: loc.repetirContrasenaLabel,
                labelStyle: TextStyle(color: Colors.white70),
              ),
              validator: (v) => (v != _password.text) ? loc.contrasenaNoCoincide: null,
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: _domicilio,
              onChanged: (v) => setState(() => _domicilio = v),
              title: Text(
                loc.ofrezcoDomicilio,
                style: TextStyles.defaultTex_2,
              ),
              subtitle: Text(
                loc.toggleDomicilioHint,
                style: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: ButtonStyles.redButton,
                onPressed: _loading ? null : _submit,
                child:
                    _loading
                        ? const CircularProgressIndicator()
                        : Text(loc.crearCuenta),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
