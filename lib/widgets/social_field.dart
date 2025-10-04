// lib/widgets/social_field.dart
import 'dart:async';
import 'dart:io' show HttpClient; // solo móvil
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

enum SocialPlatform { instagram, whatsapp, facebook, tiktok }

class SocialField extends StatefulWidget {
  const SocialField({
    super.key,
    required this.platform,
    required this.initial,
    required this.onChanged,
  });

  final SocialPlatform platform;
  final String? initial;
  final ValueChanged<String?> onChanged;

  @override
  State<SocialField> createState() => _SocialFieldState();
}

class _SocialFieldState extends State<SocialField> {
  late final TextEditingController _c;
  bool _checking = false;
  bool? _exists; // null = sin validar
  String? _error;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial ?? '');
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // ---------- UI helpers ----------
  String _label() {
    switch (widget.platform) {
      case SocialPlatform.instagram: return 'Instagram';
      case SocialPlatform.whatsapp:  return 'WhatsApp';
      case SocialPlatform.facebook:  return 'Facebook';
      case SocialPlatform.tiktok:    return 'TikTok';
    }
  }

  String _hint() {
    switch (widget.platform) {
      case SocialPlatform.instagram: return '@usuario o enlace';
      case SocialPlatform.whatsapp:  return '+54911... (formato internacional)';
      case SocialPlatform.facebook:  return 'usuario o enlace';
      case SocialPlatform.tiktok:    return '@usuario o enlace';
    }
  }

  Icon _icon() {
    switch (widget.platform) {
      case SocialPlatform.instagram: return const Icon(Icons.camera_alt_outlined);
      case SocialPlatform.whatsapp:  return const Icon(Icons.chat_bubble_outline);
      case SocialPlatform.facebook:  return const Icon(Icons.facebook_outlined);
      case SocialPlatform.tiktok:    return const Icon(Icons.music_note);
    }
  }

  // ---------- Normalización a URL ----------
  Uri? _buildUrl() {
    final raw = _c.text.trim();
    if (raw.isEmpty) return null;

    switch (widget.platform) {
      case SocialPlatform.instagram:
        final h = raw
            .replaceAll(RegExp(r'https?://(www\.)?instagram\.com/'), '')
            .replaceAll('@', '')
            .split('?').first
            .replaceAll('/', '');
        if (!_isHandle(h)) return null;
        return Uri.parse('https://www.instagram.com/$h/');
      case SocialPlatform.facebook:
        if (raw.startsWith('http')) return Uri.tryParse(raw);
        return Uri.parse('https://www.facebook.com/$raw');
      case SocialPlatform.tiktok:
        final h = raw
            .replaceAll(RegExp(r'https?://(www\.)?tiktok\.com/@'), '')
            .replaceAll('@', '')
            .split('?').first
            .replaceAll('/', '');
        if (!_isHandle(h)) return null;
        return Uri.parse('https://www.tiktok.com/@$h');
      case SocialPlatform.whatsapp:
        final d = raw.replaceAll(RegExp(r'\D'), '');
        if (d.length < 8 || d.length > 15) return null;
        return Uri.parse('https://wa.me/$d');
    }
  }

  String? _validateLocal() {
    final raw = _c.text.trim();
    if (raw.isEmpty) return null; // opcional
    switch (widget.platform) {
      case SocialPlatform.instagram:
      case SocialPlatform.tiktok:
        final h = raw.replaceAll('@', '').split('/').last;
        if (!_isHandle(h)) return 'Formato inválido';
        return null;
      case SocialPlatform.facebook:
        if (raw.contains(' ')) return 'Sin espacios';
        return null;
      case SocialPlatform.whatsapp:
        final d = raw.replaceAll(RegExp(r'\D'), '');
        if (d.length < 8 || d.length > 15) {
          return 'Número internacional válido (+cód. país)';
        }
        return null;
    }
  }

  bool _isHandle(String h) =>
      RegExp(r'^[A-Za-z0-9._]{2,30}$').hasMatch(h);

  // ---------- Acciones ----------
  Future<void> _checkExists() async {
    final url = _buildUrl();
    if (url == null) {
      setState(() { _exists = false; _error = 'Link inválido'; });
      return;
    }
    if (kIsWeb) {
      // Evitamos CORS en Web; luego podemos mover la verificación a una Cloud Function.
      setState(() { _exists = null; _error = 'Validación no disponible en Web'; });
      return;
    }

    setState(() { _checking = true; _error = null; _exists = null; });

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final req = await client.getUrl(url);
      final resp = await req.close().timeout(const Duration(seconds: 8));
      final ok = resp.statusCode >= 200 && resp.statusCode < 400;
      if (!mounted) return;
      setState(() => _exists = ok);
    } on TimeoutException {
      if (!mounted) return;
      setState(() { _exists = false; _error = 'Tiempo agotado'; });
    } catch (_) {
      if (!mounted) return;
      setState(() { _exists = false; _error = 'Error de red'; });
    } finally {
      client.close(force: true);
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _open() async {
    final url = _buildUrl();
    if (url == null) { setState(() => _error = 'Link inválido'); return; }
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final localError = _validateLocal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _c,
          onChanged: (v) {
            widget.onChanged(v.trim().isEmpty ? null : v.trim());
            setState(() { _exists = null; _error = null; });
          },
          decoration: InputDecoration(
            labelText: _label(),
            hintText: _hint(),
            prefixIcon: _icon(),
            errorText: _error ?? localError,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.link),
              label: const Text('Abrir'),
              onPressed: _open,
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: _checking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Validar'),
              onPressed: (localError == null && !_checking) ? _checkExists : null,
            ),
            const Spacer(),
            if (_exists == true)
              _Pill(text: 'Verificado', ok: true)
            else if (_exists == false)
              _Pill(text: 'No encontrado', ok: false),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.ok});
  final String text;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF2ecc71) : const Color(0xFFe74c3c);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.15),
        border: Border.all(color: color.withOpacity(.6)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12)),
    );
  }
}
