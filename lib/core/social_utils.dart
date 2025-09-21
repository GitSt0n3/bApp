enum SocialPlatform { instagram, whatsapp, facebook, tiktok, web }

class SocialLink {
  final SocialPlatform platform;
  final String input;      // lo que escribe el usuario
  final String url;        // URL normalizada para abrir
  final String? deepLink;  // esquema app si existe (fallback a url)
  const SocialLink({required this.platform, required this.input, required this.url, this.deepLink});
}

class SocialUtils {
  static String normalize(SocialPlatform p, String raw) {
    final t = raw.trim();
    switch (p) {
      case SocialPlatform.instagram:
        final handle = t
            .replaceAll(RegExp(r'https?://(www\.)?instagram\.com/'), '')
            .replaceAll('@', '')
            .split('?').first.replaceAll('/', '');
        return 'https://instagram.com/$handle';
      case SocialPlatform.facebook:
        if (t.startsWith('http')) return t;
        return 'https://facebook.com/$t';
      case SocialPlatform.tiktok:
        final handle = t.replaceAll(RegExp(r'https?://(www\.)?tiktok\.com/@'), '').replaceAll('@', '');
        return 'https://www.tiktok.com/@$handle';
      case SocialPlatform.whatsapp:
        final digits = t.replaceAll(RegExp(r'\D'), '');
        return 'https://wa.me/$digits';
      case SocialPlatform.web:
        return t.startsWith('http') ? t : 'https://$t';
    }
  }

  static String? deep(SocialPlatform p, String url) {
    switch (p) {
      case SocialPlatform.instagram:
        final user = url.split('/').last;
        return 'instagram://user?username=$user';
      case SocialPlatform.facebook:
        return null; // fb://… (no siempre funciona sin id numérico)
      case SocialPlatform.tiktok:
        final user = url.split('@').last;
        return 'snssdk1128://user/profile/@$user';
      case SocialPlatform.whatsapp:
        final num = url.split('/').last;
        return 'whatsapp://send?phone=$num';
      case SocialPlatform.web:
        return null;
    }
  }

  static bool isValid(SocialPlatform p, String raw) {
    switch (p) {
      case SocialPlatform.instagram:
        return RegExp(r'^[A-Za-z0-9._]{1,30}$').hasMatch(raw.replaceAll('@', '').split('/').last);
      case SocialPlatform.facebook:
        return raw.length >= 3;
      case SocialPlatform.tiktok:
        return RegExp(r'^[A-Za-z0-9._]{1,30}$').hasMatch(raw.replaceAll('@', '').split('@').last);
      case SocialPlatform.whatsapp:
        return RegExp(r'^\+?\d{8,15}$').hasMatch(raw.replaceAll(RegExp(r'\D'), ''));
      case SocialPlatform.web:
        return RegExp(r'^(https?://)?[^\s]+\.[^\s]+').hasMatch(raw);
    }
  }
}
