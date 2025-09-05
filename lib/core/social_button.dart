import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialButton extends StatelessWidget {
  final String assetPath;
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

  bool get _isSvg => assetPath.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final double size = 32;
    return IconButton(
      onPressed: _launch,
      tooltip: url,
      icon: _isSvg
          ? SvgPicture.asset(assetPath, width: size, height: size)
          : Image.asset(assetPath, width: size, height: size, fit: BoxFit.contain),
    );
  }
}

