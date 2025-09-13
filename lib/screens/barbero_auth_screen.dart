import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/button_styles.dart';
import 'package:barberiapp/core/text_styles.dart';

import 'package:latlong2/latlong.dart';
import '../widgets/map_picker.dart';
import '../services/auth_Service.dart';
import 'package:barberiapp/generated/l10n.dart';

const kOAuthRedirectUri = 'com.barberiapp://login-callback/';

class BarberAuthScreen extends StatefulWidget {
  const BarberAuthScreen({super.key});

  @override
  State<BarberAuthScreen> createState() => _BarberAuthScreenState();
}

class _BarberAuthScreenState extends State<BarberAuthScreen> {
  final supabase = Supabase.instance.client;
  bool _googleLoading = false;
  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn && mounted) {
        // TODO: navega a tu hub de barbero (go_router, etc.)
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

   Future<void> _loginWithGoogle() async {
    if (_googleLoading) return;
    setState(() => _googleLoading = true);
    try {
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kOAuthRedirectUri,
        scopes: 'openid email profile',
        queryParams: {
          'access_type': 'offline',
          'prompt': 'select_account',
        },
      );
    } catch (e) {
      if (!mounted) return;
      final loc = S.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${loc.errorAutenticando}: $e')),
      );
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final loc = S.of(context)!;

    return Scaffold(
      // …tu AppBar y resto del formulario email/contraseña…
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // …tus campos + botón "Entrar" existentes…
            const SizedBox(height: 24),

            // separador visual
            Row(
              children: [
                Expanded(child: Divider(color: cs.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(loc.oContinuarCon, style: TextStyles.bodyText),
                ),
                Expanded(child: Divider(color: cs.outlineVariant)),
              ],
            ),

            const SizedBox(height: 12),

            // Botón Google
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _googleLoading ? null : _loginWithGoogle,
                icon:
                    _googleLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : Image.asset(
                          'assets/icons/social/google.png',
                          width: 20,
                          height: 20,
                        ),
                label: Text('Google', style: TextStyles.buttonText),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: cs.outlineVariant),
                  foregroundColor: cs.onSurface,
                  backgroundColor: cs.surface,
                ),
              ),
            ),
          ],
        ),
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
                      (v == null || !v.contains('@'))
                          ? loc.emailInvalido
                          : null,
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
                      (v == null || v.length < 6) ? loc.contrasenaMin6 : null,
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
              validator:
                  (v) =>
                      (v != _password.text) ? loc.contrasenaNoCoincide : null,
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              value: _domicilio,
              onChanged: (v) => setState(() => _domicilio = v),
              title: Text(loc.ofrezcoDomicilio, style: TextStyles.defaultTex_2),
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
