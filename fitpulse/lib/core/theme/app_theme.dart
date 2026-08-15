import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class AppColors {
  static const Color background = Color(
      0xFF07090E); // Daha da koyulaştırılmış, derin gece mavisi-antrasit zemin
  static const Color surface =
      Color(0xFF11151D); // Arka plana uyumlu, tok ve koyu kart zemini
  static const Color volt = Color(0xFFCCFF00); // Neon yeşil vurgu rengi
  static const Color voltDark =
      Color(0xFF99CC00); // Tıklanma/Gölgeler için koyu yeşil
  static const Color textPrimary = Colors.white;
  static const Color textSecondary =
      Color(0xFF9EA4B0); // Soğuk gri alt metinler
  static const Color stroke =
      Color(0xFF1C222E); // Derinliğe uyumlu ince kart sınır çizgileri
}

abstract class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.volt,
        surface: AppColors.surface,
      ),
      textTheme: GoogleFonts.poppinsTextTheme()
          .copyWith(
            bodyMedium: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600, // Standart metinler artık daha tok
            ),
            bodySmall: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600, // Alt metinler de cılız durmayacak
            ),
          )
          .apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
      // Material 3 koyu temada SnackBar'ın varsayılan yazı rengi koyudur
      // (açık "inverse" zemine göre seçilir); bizim kartlar da koyu olduğu
      // için mesajlar görünmez oluyordu. Rengi burada sabitliyoruz ki her
      // ekran ayrı ayrı hatırlamak zorunda kalmasın.
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
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
