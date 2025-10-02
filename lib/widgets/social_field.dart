// lib/widgets/social_field.dart
import 'dart:async';
import 'dart:io'; // para comprobar existencia con HttpClient
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
  bool? _exists; // null=sin validar, true=ok, false=falló
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
      case SocialPlatform.tikto
