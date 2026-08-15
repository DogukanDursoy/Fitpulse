import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/layout/root_layout.dart';
import 'core/services/user_preferences.dart'; // Yeni servisimiz
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/core/utils/measurement_input.dart';
import 'package:fitpulse/data/local/daos/exercise_dao.dart';
// Aşağıdaki satırı kendi Onboarding sayfanın yoluna göre değiştir
import 'package:fitpulse/features/onboarding/presentation/pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Veritabanı kurulumu
  final workoutDao = WorkoutDao();
  await workoutDao.seedWorkoutPrograms();
  await workoutDao.seedProgramExercises();
  // Hareket kataloğu: kas haritasının beslendiği primary/secondary kas bilgisi buradan gelir
  await ExerciseDao().seedExerciseCatalog();

  // Onboarding'i daha önce tamamlamış kullanıcıların kilo geçmişi boş olabilir;
  // hacim hesabı ve form kartı için tek seferlik başlangıç kaydını düşüyoruz.
  final preferences = UserPreferences();
  if (await preferences.hasCompletedOnboarding()) {
    final info = await preferences.getUserInfo();
    await workoutDao
        .ensureInitialWeightRecord(parseWeightKg(info['weight']) ?? 75);
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const FitpulseApp());
}

class FitpulseApp extends StatelessWidget {
  const FitpulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GainFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // BURASI KAPIDA KARAR VEREN YER
      home: FutureBuilder<bool>(
        future: UserPreferences().hasCompletedOnboarding(),
        builder: (context, snapshot) {
          // Veri okunurken yükleme ekranı
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                  child: CircularProgressIndicator(color: AppColors.volt)),
            );
          }

          // Eğer onboarding tamamlandıysa RootLayout'a (Ana sayfaya),
          // değilse Onboarding'e gönder
          return snapshot.data == true
              ? const RootLayout()
              : const OnboardingPage();
        },
      ),
    );
  }
}
