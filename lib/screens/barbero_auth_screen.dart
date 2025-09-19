import 'package:barberiapp/core/app_colors.dart';
import 'package:barberiapp/core/button_styles.dart';
import 'package:barberiapp/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/map_picker.dart';
import '../services/auth_Service.dart';
import 'package:barberiapp/generated/l10n.dart';
import 'package:barberiapp/services/native_google_auth.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

const kOAuthRedirectUri =
    'com.barberiapp://login-callback/'; // <- igual al que pusiste en Supabase

/// =========================
///  Helpers Google OAuth
/// =========================
void _openGoogleModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF111214),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _GoogleLoginSheet(),
  );
}

Widget googleDivider(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final loc = S.of(context)!;
  return Row(
    children: [
      Expanded(child: Divider(color: cs.outlineVariant)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(loc.continuarConGoogle, style: TextStyles.bodyText),
      ),
      Expanded(child: Divider(color: cs.outlineVariant)),
    ],
  );
}

Widget googleButton(BuildContext context, {bool loading = false}) {
  final cs = Theme.of(context).colorScheme;
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton.icon(
      onPressed: loading ? null : () => _openGoogleModal(context),
      icon:
          loading
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
      label: const Text('Google'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: cs.outlineVariant),
        foregroundColor: cs.onSurface,
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
  );
}

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

            // ↓↓↓ Aquí va Google
            const SizedBox(height: 24),
            googleDivider(context),
            const SizedBox(height: 12),
            googleButton(context, loading: _loading),
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

class _GoogleLoginSheet extends StatefulWidget {
  const _GoogleLoginSheet();

  @override
  State<_GoogleLoginSheet> createState() => _GoogleLoginSheetState();
}

class _GoogleLoginSheetState extends State<_GoogleLoginSheet> {
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Lanza de inmediato el selector de cuentas
    Future.microtask(_handleGoogle);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Tu leyenda de “Iniciar sesión” se mantiene
          const Text('Iniciar sesión', textAlign: TextAlign.center),
          const SizedBox(height: 16),

          if (_loading)
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: cs.error)),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _handleGoogle,
              child: const Text('Reintentar'),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handleGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await signInWithGoogleNative(); // usa TU servicio nativo
      if (!mounted) return;
      if (res?.session != null) {
        Navigator.of(
          context,
        ).pop(); // cierra el modal; tu listener global redirige
      } else {
        setState(() => _error = 'No se pudo iniciar sesión.');
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
