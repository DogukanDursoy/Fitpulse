import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../features/templates/presentation/pages/templates_page.dart';
import '../../features/workout/presentation/pages/workouts_page.dart';
import 'package:fitpulse/features/profile/presentation/pages/profile_page.dart';
import 'package:fitpulse/features/stats/presentation/pages/stats_page.dart';
import 'package:fitpulse/features/homepage/presentation/pages/home_page.dart';

class RootLayout extends StatefulWidget {
  const RootLayout({super.key});

  @override
  State<RootLayout> createState() => _RootLayoutState();
}

class _RootLayoutState extends State<RootLayout> {
  int _currentIndex = 0;

  // BURASI DÜZELTİLDİ: 0. İndekse gerçek HomePage (Dashboard) bağlandı!
  final List<Widget> _pages = [
    const HomePage(), // 0. İndeks: Ana Sayfa (Dashboard + İstatistik Kartları)
    const WorkoutsPage(), // 1. İndeks: Antrenman / Kütüphane
    const StatsPage(), // 2. İndeks: İstatistik
    const ProfilePage(), // 3. İndeks: Profil
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
                color: AppColors.stroke,
                width: 1), // Tasarımdaki o ince üst çizgi
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.background,
          selectedItemColor: AppColors.volt,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.home_outlined)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home)),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.fitness_center_outlined)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.fitness_center)),
              label: 'Antrenman',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.show_chart)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.show_chart)),
              label: 'İstatistik',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person_outline)),
              activeIcon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.person)),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
