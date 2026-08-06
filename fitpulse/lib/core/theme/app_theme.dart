import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const Color background = Color(0xFF121212); // Koyu antrasit ana zemin
  static const Color surface = Color(0xFF1E1E1E); // Kart ve BottomSheet zemini
  static const Color volt = Color(0xFFCCFF00); // Neon yeşil vurgu rengi
  static const Color voltDark =
      Color(0xFF99CC00); // Tıklanma/Gölgeler için koyu yeşil
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA0A0A5); // Gri alt metinler
  static const Color stroke = Color(0xFF2C2C2E); // İnce kart sınırları
}

abstract class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.volt,
        surface: AppColors.surface,
        background: AppColors.background,
      ),
      textTheme: GoogleFonts.manropeTextTheme()
          .copyWith(
            bodyMedium: GoogleFonts.manrope(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600, // Standart metinler artık daha tok
            ),
            bodySmall: GoogleFonts.manrope(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600, // Alt metinler de cılız durmayacak
            ),
          )
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.stroke, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.background,
        selectedItemColor: AppColors.volt,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
