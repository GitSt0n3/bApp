import 'package:barberiapp/core/text_styles.dart';
import 'package:flutter/material.dart';
import 'app_colors.dart'; // si tienes la paleta de colores separada
import 'package:barberiapp/core/app_colors.dart';

class ButtonStyles {
  static final redButton = FilledButton.styleFrom(
    backgroundColor: Colors.red, // o AppColors.primary
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
    textStyle: TextStyles.defaultTex_2,
    minimumSize: const Size(100, 44), // alto fijo, ancho mínimo
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static final redButtonFull = FilledButton.styleFrom(
    backgroundColor: Colors.red,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    textStyle: TextStyles.defaultTex_2,
    minimumSize: const Size.fromHeight(48), // ocupa todo el ancho disponible
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );

  static final greyButton = FilledButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.primary,
    textStyle: TextStyles.defaultTex_2,
    minimumSize: const Size(100, 44), // 👈 alto fijo, ancho mínimo
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class ChipStyles {
  static final chipTheme = ChipThemeData(
    backgroundColor: AppColors.accent, // no seleccionado
    selectedColor: AppColors.primary, // seleccionado
    labelStyle: TextStyles.defaultTex_2.copyWith(
      color: AppColors.primary, // texto base
    ),
    secondaryLabelStyle: TextStyles.defaultTex_2.copyWith(
      color: Colors.white, // texto seleccionado
    ),
    checkmarkColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: AppColors.primary, width: 1),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  );
}
