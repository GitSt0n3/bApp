import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialButton extends StatelessWidget {
  final String assetPath; // ruta del SVG en assets
  final String url;

  const SocialButton({
    super.key,
    required this.assetPath,
    required this.url,
  });

  Future<void> _launch() async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: SvgPicture.asset(
        assetPath,
        width: 32,
        height: 32,
      ),
      onPressed: _launch,
      tooltip: url,
    );
  }
}
