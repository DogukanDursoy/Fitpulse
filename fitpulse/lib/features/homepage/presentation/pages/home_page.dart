import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/services/user_preferences.dart';
import 'package:fitpulse/features/templates/presentation/pages/templates_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'Şampiyon';
  String _userImage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // SharedPreferences'tan kayıtlı ismi ve profil resmini çekiyoruz
  Future<void> _loadUserData() async {
    final data = await UserPreferences().getUserInfo();
    setState(() {
      _userName = data['name'] ?? 'Şampiyon';
      _userImage = data['image'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // 1. ÜST KISIM: Karşılama ve Dinamik Profil Avatarı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _userName, // Dinamik kullanıcı ismi buraya yazılıyor
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.volt, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.surface,
                    backgroundImage: _userImage.isNotEmpty
                        ? NetworkImage(_userImage) as ImageProvider
                        : const NetworkImage(
                            'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1000&auto=format&fit=crop',
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. ANTRENMANA BAŞLA KARTI (Tıklanınca TemplatesPage'e uçar)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplatesPage(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.volt,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.volt.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antrenman Zamanı',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Şablon seç veya serbest ağırlığa geç',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.volt,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. ANA HEDEF / ADIM SAYARI KARTI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.stroke, width: 1),
              ),
              child: Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: 0.82,
                          backgroundColor: AppColors.background,
                          color: AppColors.volt,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '9,840',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'STEPS',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '82% of Goal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Almost there! Just 2,160 steps left to smash your daily metric.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.stroke),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department,
                                  color: AppColors.volt, size: 14),
                              SizedBox(width: 6),
                              Text(
                                '5 DAY STREAK',
                                style: TextStyle(
                                  color: AppColors.volt,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. YAN YANA KARTLAR: Kalp Atışı ve Kalori
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.stroke, width: 1),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'HEART RATE',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(Icons.favorite,
                                color: AppColors.volt, size: 18),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '134 bpm',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Peak Zone (Cardio)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.stroke, width: 1),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'BURNED',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(Icons.local_fire_department_outlined,
                                color: AppColors.textSecondary, size: 18),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '642 kcal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Target: 800 kcal',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. HAFTALIK AKTİVİTE BARI
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.stroke, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Weekly Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '+14% vs last week',
                        style: TextStyle(
                          color: AppColors.volt,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBarCol('M', 40, false),
                      _buildBarCol('T', 55, false),
                      _buildBarCol('W', 70, false),
                      _buildBarCol('T', 45, false),
                      _buildBarCol('F', 100, true),
                      _buildBarCol('S', 60, false),
                      _buildBarCol('S', 35, false),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarCol(String day, double heightFactor, bool isActive) {
    return Column(
      children: [
        Container(
          width: 14,
          height: 80,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(7),
          ),
          child: FractionallySizedBox(
            heightFactor: heightFactor / 100,
            child: Container(
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.volt
                    : AppColors.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          day,
          style: TextStyle(
            color: isActive ? AppColors.volt : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
