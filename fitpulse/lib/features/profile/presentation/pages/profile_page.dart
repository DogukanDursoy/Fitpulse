import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/services/user_preferences.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _userName = 'Şampiyon';
  String _userImage = '';
  String _weeklyGoal = '4';
  String _userHeight = '175';
  String _userWeight = '75';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await UserPreferences().getUserInfo();
    setState(() {
      _userName = data['name'] ?? 'Şampiyon';
      _userImage = data['image'] ?? '';
      _weeklyGoal = data['goal'] ?? '4';
      _userHeight = data['height'] ?? '175';
      _userWeight = data['weight'] ?? '75';
    });
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userName);
    final heightController = TextEditingController(text: _userHeight);
    final goalController = TextEditingController(text: _weeklyGoal);
    final weightController = TextEditingController(text: _userWeight);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profili Düzenle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İSİM (Üzerine yazılır)
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Adın',
                    labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 12),
              // BOY (Üzerine yazılır)
              TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Boy (cm)',
                    labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 12),
              // HEDEF (Üzerine yazılır)
              TextField(
                controller: goalController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Haftalık Hedef (Gün)',
                    labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 12),
              // KİLO (Hem üzerine yazılır, hem geçmişe loglanır)
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'Güncel Kilo (kg)',
                    labelStyle: TextStyle(color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal',
                  style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.volt),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newHeight = heightController.text.trim();
              final newGoal = goalController.text.trim();
              final newWeight = weightController.text.trim();

              if (newName.isNotEmpty && newWeight.isNotEmpty) {
                // 1. SharedPreferences'a güncel hallerini kaydet (üzerine yaz)
                await UserPreferences().updateProfileSettings(
                  name: newName,
                  height: newHeight,
                  weeklyGoal: newGoal,
                  weight: newWeight,
                );

                // 2. EĞER KİLO DEĞİŞMİŞSE -> SQLite veritabanına yeni metrik olarak logla (Tarihli Kayıt)
                if (newWeight != _userWeight) {
                  final parsedWeight = double.tryParse(newWeight) ?? 0.0;
                  // WorkoutDao'yu projene import ettiğinden emin ol
                  await WorkoutDao().insertWeightRecord(parsedWeight);
                }

                // 3. Arayüzü güncelle
                setState(() {
                  _userName = newName;
                  _userHeight = newHeight;
                  _weeklyGoal = newGoal;
                  _userWeight = newWeight;
                });
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Kaydet',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _showEditProfileDialog,
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.volt, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.surface,
                      backgroundImage: _userImage.isNotEmpty
                          ? NetworkImage(_userImage) as ImageProvider
                          : const NetworkImage(
                              'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=1000&auto=format&fit=crop',
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                _userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.edit,
                                color: AppColors.textSecondary, size: 16),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.workspace_premium,
                                color: AppColors.volt, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'HEDEF: HAFTADA $_weeklyGoal GÜN',
                              style: const TextStyle(
                                color: AppColors.volt,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 2. MONTHLY HEATMAP
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
                        'Monthly Heatmap',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Last 28 Days',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: 28,
                    itemBuilder: (context, index) {
                      final colors = [
                        const Color(0xFF1C221E),
                        const Color(0xFF384E29),
                        const Color(0xFF6B9A34),
                        AppColors.volt,
                      ];
                      final colorIndex = (index * 7 + 3) % colors.length;

                      return Container(
                        decoration: BoxDecoration(
                          color: colors[colorIndex],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. ACHIEVEMENTS
            const Text(
              'Achievements',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _AchievementBadge(
                      icon: Icons.local_fire_department,
                      title: 'Streak Master'),
                  SizedBox(width: 12),
                  _AchievementBadge(
                      icon: Icons.fitness_center, title: 'Iron Will'),
                  SizedBox(width: 12),
                  _AchievementBadge(icon: Icons.bolt, title: 'Early Bird'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. PERSONAL RECORDS
            const Text(
              'Personal Records',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.stroke, width: 1),
              ),
              child: const Column(
                children: [
                  _PrTile(
                    title: 'Max Bench Press',
                    date: 'Oct 12',
                    value: '245 lbs',
                    showDivider: true,
                  ),
                  _PrTile(
                    title: 'Deadlift Max',
                    date: 'Oct 20',
                    value: '315 lbs',
                    showDivider: true,
                  ),
                  _PrTile(
                    title: 'Fastest 5K Run',
                    date: 'Sep 28',
                    value: '21m 45s',
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String title;

  const _AchievementBadge({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.volt, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrTile extends StatelessWidget {
  final String title;
  final String date;
  final String value;
  final bool showDivider;

  const _PrTile({
    required this.title,
    required this.date,
    required this.value,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.fitness_center,
                        color: AppColors.textSecondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date,
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
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.volt,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            color: AppColors.stroke,
            height: 1,
            thickness: 1,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
