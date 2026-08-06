import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/features/workout/presentation/pages/active_workout_page.dart';

class TemplatesPage extends StatelessWidget {
  const TemplatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. HEADER: Karşılama Alanı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş Geldin,',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Şampiyon', // İleride API'dan kullanıcının adı gelecek
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.stroke, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.surface,
                    child: Icon(Icons.person, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 2. HERO BUTON: Boş Antrenman Başlat
            GestureDetector(
              onTap: () {
                // Şantiyeyi (Fullscreen Modal) başlatıyoruz
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActiveWorkoutPage(),
                    fullscreenDialog: true,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.volt,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.volt.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Boş Antrenman',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Hemen serbest ağırlığa geç',
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Icon(Icons.add_circle_outline,
                        color: Colors.black, size: 36),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 3. KAYITLI ŞABLONLAR BAŞLIĞI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kayıtlı Şablonlar',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Tümünü Gör',
                      style: TextStyle(
                          color: AppColors.volt, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. ŞABLON KARTLARI (Şimdilik Mock Data)
            _TemplateCard(
              title: 'Push Day (İtme)',
              subtitle: 'Göğüs, Omuz, Arka Kol',
              lastPerformed: 'Son antrenman: 2 gün önce',
              onTap: () {
                // TODO: Şablon verisiyle şantiyeyi aç
              },
            ),
            const SizedBox(height: 16),
            _TemplateCard(
              title: 'Pull Day (Çekme)',
              subtitle: 'Sırt, Biceps, Arka Omuz',
              lastPerformed: 'Son antrenman: Dün',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// Şablon Kartı Bileşeni
class _TemplateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String lastPerformed;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.title,
    required this.subtitle,
    required this.lastPerformed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.stroke, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: AppColors.textSecondary, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                lastPerformed,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
