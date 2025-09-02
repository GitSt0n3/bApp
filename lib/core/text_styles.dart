import 'package:barberiapp/core/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

class TextStyles {
  static final TextStyle bodyText = GoogleFonts.fruktur(
    color: AppColors.tittleText,
    fontSize: 16,
  );
  static final TextStyle tittleText = GoogleFonts.fruktur(
    color: AppColors.tittleText,
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  static final TextStyle buttonText = GoogleFonts.fruktur(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.buttonText,
  );
  static final TextStyle defaultText = GoogleFonts.fruktur(
    fontSize: 16,
    fontWeight: FontWeight.w100,
    color: AppColors.buttonText,
  );
  static final TextStyle defaultTex_2 = GoogleFonts.fruktur(
    fontSize: 16,
    fontWeight: FontWeight.w200,
    color: const Color(0xC5EEE6E6),
  );

  static final TextStyle subtitleText = GoogleFonts.fruktur(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: const Color(0xC5EEE6E6),
  );
  // --- NUEVOS (reutilizables en toda la app) ---

  /// Título de ítems de lista / cards (menos bold que el actual)
  static final TextStyle listTitle = GoogleFonts.fruktur(
    fontSize: 16,
    fontWeight: FontWeight.w500, // bajamos un poco el bold
    color: AppColors.tittleText,
  );

  /// Línea de meta (duración, precio, etc.)
  static final TextStyle listSubtitle = GoogleFonts.fruktur(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: const Color(0xFFBDBDBD), // gris claro
  );

  /// Línea secundaria (ej: distancia)
  static final TextStyle listSubtitleMuted = GoogleFonts.fruktur(
    fontSize: 13,
    fontWeight: FontWeight.w300,
    color: const Color(0xFF9E9E9E), // gris más tenue
  );

  /// Mensajes vacíos / estados
  static final TextStyle emptyState = GoogleFonts.fruktur(
    fontSize: 15,
    fontStyle: FontStyle.italic,
    color: const Color(0xFF9E9E9E),
  );

  /// Placeholder / hint de inputs de búsqueda
  static final TextStyle searchHint = GoogleFonts.fruktur(
    fontSize: 14,
    fontWeight: FontWeight.w300,
    color: const Color(0xFF9E9E9E),
  );
}
