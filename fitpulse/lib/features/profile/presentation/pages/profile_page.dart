import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. Profil Başlığı ve Avatar
            const Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.person,
                      size: 36, color: AppColors.textSecondary),
                ),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Doğukan',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Seviye 12 • Powerbuilder',
                      style: TextStyle(
                          color: AppColors.volt,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 32),

            // 2. Fiziksel Metrikler (Mock Data)
            Row(
              children: [
                _buildStatCard('Boy', '190', 'cm'),
                const SizedBox(width: 12),
                _buildStatCard('Kilo', '90', 'kg'),
                const SizedBox(width: 12),
                _buildStatCard('Antrenman', '142', 'gün'),
              ],
            ),
            const SizedBox(height: 32),

            // 3. Haftalık Hedef Çubuğu (Konuştuğumuz kısım)
            const Text(
              'Haftalık Hedef',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('4 Antrenman',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                      Text('3/4',
                          style: TextStyle(
                              color: AppColors.volt,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar Animasyonsuz Temel Hali
                  LinearProgressIndicator(
                    value: 0.75, // %75 dolu (3/4)
                    backgroundColor: AppColors.background,
                    color: AppColors.volt,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hedefe ulaşmak için bu hafta 1 antrenman daha yapmalısın.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Metrikleri yan yana dizmek için yazdığımız ufak yardımcı widget
  Widget _buildStatCard(String title, String value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.stroke),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 2),
                Text(unit,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
