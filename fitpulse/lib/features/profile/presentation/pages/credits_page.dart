import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/program_visuals.dart';

/// Uygulamada kullanılan üçüncü taraf içeriklerin kaynakları.
///
/// Hazır şablonların kart fotoğrafları Unsplash'ten alındı ve uygulamaya
/// gömüldü. Unsplash License atıf zorunlu tutmuyor, ama fotoğrafçıya kredi
/// vermek doğrusu — ve mağaza incelemesinde kaynakların şeffaf olması iyi.
class CreditsPage extends StatelessWidget {
  const CreditsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Krediler',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Fotoğraflar',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hazır antrenman şablonlarının görselleri Unsplash üzerinden '
            'alınmıştır ve Unsplash License kapsamında kullanılmaktadır.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ...ProgramVisuals.photoCredits.map(
            (credit) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.stroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    credit.program,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    credit.photographer.isEmpty
                        ? 'Unsplash · ${credit.sourceId}'
                        : '${credit.photographer} · Unsplash',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Kas haritası',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'İstatistik ekranındaki anatomi çizimi uygulamayla birlikte gelir.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
