import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialButton extends StatelessWidget {
  final String assetPath;
  final String url;
  final double size;

  const SocialButton({
    super.key,
    required this.assetPath,
    required this.url,
    this.size = 32,
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
    final Widget icon = _isSvg
        ? SvgPicture.asset(
            assetPath,
            width: size,
            height: size,
            placeholderBuilder: (_) => SizedBox(
              width: 32,
              height: 32,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            clipBehavior: Clip.hardEdge,
          )
        : Image.asset(
            assetPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high, // 🔑 mejora nitidez PNG
            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
          );

    return IconButton(
      onPressed: _launch,
      tooltip: url,
      icon: icon,
    );
  }
}
