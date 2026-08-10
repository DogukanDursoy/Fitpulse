import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  bool _isFront = true; // Ön / Arka kas haritası geçiş durumu

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Haftalık Kas Haritası',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. TARİH SEÇİCİ BAR
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.stroke, width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.chevron_left, color: AppColors.textSecondary),
                  Text(
                    '27 Tem - 2 Ağu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. KAS HARİTASI VE ÖN/ARKA SEÇİCİ KUTUSU
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.stroke, width: 1),
              ),
              child: Column(
                children: [
                  // Ön / Arka Toggle Butonu
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.stroke, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildToggleTab('Ön', _isFront,
                            () => setState(() => _isFront = true)),
                        _buildToggleTab('Arka', !_isFront,
                            () => setState(() => _isFront = false)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Vücut Silüeti ve Kas Yoğunluk Temsili
                  SizedBox(
                    height: 150,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 130,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color:
                                      AppColors.textSecondary.withOpacity(0.25),
                                  width: 1.5),
                              borderRadius: BorderRadius.circular(55),
                            ),
                          ),
                          // Görseldeki yoğunluk barları simülasyonu
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  width: 28,
                                  height: 18,
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(4))),
                              const SizedBox(width: 4),
                              Container(
                                  width: 28,
                                  height: 18,
                                  decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(4))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Düşük - Yüksek Renk Skalası Çubuğu
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          gradient: const LinearGradient(
                            colors: [
                              Colors.green,
                              Colors.yellow,
                              Colors.orange,
                              Colors.red
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Düşük',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                          Text('Yüksek',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 3. EN ÇOK ÇALIŞAN KASLAR BAŞLIĞI
            const Text(
              'En Çok Çalışan Kaslar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 14),

            // 4. KAS LİSTESİ KARTLARI
            _buildMuscleStatCard(
                '1', 'Göğüs', 'Haftalık Hacim: 4.200 kg', '85%', Colors.red),
            const SizedBox(height: 12),
            _buildMuscleStatCard('2', 'Ön Omuz', 'Haftalık Hacim: 2.800 kg',
                '55%', Colors.orange),
            const SizedBox(height: 12),
            _buildMuscleStatCard('3', 'Triceps', 'Haftalık Hacim: 1.600 kg',
                '30%', AppColors.volt),
          ],
        ),
      ),
    );
  }

  // Ön / Arka Sekme Tasarım Yardımcısı
  Widget _buildToggleTab(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // En Çok Çalışan Kas Kartı Tasarım Yardımcısı
  Widget _buildMuscleStatCard(String rank, String name, String volume,
      String percentage, Color indicatorColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    rank,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    volume,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                percentage,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
