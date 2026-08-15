import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/services/user_preferences.dart';
import 'package:fitpulse/core/layout/root_layout.dart';
import 'package:fitpulse/core/utils/measurement_input.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameController = TextEditingController();
  final _weightController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _heightController = TextEditingController();
  final _goalController = TextEditingController(text: '4');

  String _selectedLevel = 'Orta';
  final List<String> _levels = ['Acemi', 'Orta', 'İleri', 'Canavar'];

  String _selectedGender = 'Erkek'; // Varsayılan cinsiyet
  final List<String> _genders = ['Erkek', 'Kadın'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "GainFit'e Hoş Geldin! 🚀",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                "Sana özel antrenman deneyimi için profiline ihtiyacımız var.",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Ad Alanı
              _buildTextField(
                  controller: _nameController,
                  label: "Adın Nedir?",
                  icon: Icons.person_outline),
              const SizedBox(height: 20),

              // Boy ve Kilo (Yan yana)
              Row(
                children: [
                  Expanded(
                      child: _buildTextField(
                          controller: _heightController,
                          label: "Boy (cm)",
                          icon: Icons.height,
                          isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: _buildTextField(
                          controller: _weightController,
                          label: "Kilo (kg)",
                          icon: Icons.monitor_weight_outlined,
                          isNumber: true)),
                ],
              ),
              const SizedBox(height: 20),

              // Hedef Kilo (Ana sayfadaki form kartı buna göre ilerleme gösterir)
              _buildTextField(
                  controller: _targetWeightController,
                  label: "Hedef Kilo (kg) — opsiyonel",
                  icon: Icons.flag_outlined,
                  isNumber: true),
              const SizedBox(height: 24),

              // Cinsiyet Seçimi
              const Text(
                "Cinsiyet",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Row(
                children: _genders.map((gender) {
                  final isSelected = gender == _selectedGender;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = gender),
                      child: Container(
                        margin:
                            EdgeInsets.only(right: gender == 'Erkek' ? 12 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.volt : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.volt
                                  : AppColors.stroke),
                        ),
                        child: Center(
                          child: Text(
                            gender,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Antrenman Seviyesi Seçimi
              const Text(
                "Antrenman Seviyen",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _levels.length,
                  itemBuilder: (context, index) {
                    final level = _levels[index];
                    final isSelected = level == _selectedLevel;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedLevel = level),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? AppColors.volt : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isSelected
                                  ? AppColors.volt
                                  : AppColors.stroke),
                        ),
                        child: Center(
                          child: Text(
                            level,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Başla Butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.volt,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty) return;

                    // Boş bırakılan alanlar varsayılana düşer, ama DOLU ve
                    // geçersiz bir alan sessizce varsayılana düşürülmez —
                    // yanlış bir başlangıç kilosu tüm gelişim kartlarını bozar.
                    final weightError = _weightController.text.trim().isEmpty
                        ? null
                        : validateWeight(_weightController.text);
                    final heightError = _heightController.text.trim().isEmpty
                        ? null
                        : validateHeight(_heightController.text);
                    final goalError = _goalController.text.trim().isEmpty
                        ? null
                        : validateWeeklyGoal(_goalController.text);
                    final targetError =
                        validateOptionalTargetWeight(_targetWeightController.text);

                    final firstError =
                        weightError ?? heightError ?? goalError ?? targetError;
                    if (firstError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(firstError),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }

                    final startingWeight =
                        parseWeightKg(_weightController.text) ?? 75;
                    final startingHeight =
                        parseHeightCm(_heightController.text) ?? 175;
                    final startingGoal =
                        parseWeeklyGoal(_goalController.text) ?? 4;
                    final targetWeight =
                        parseWeightKg(_targetWeightController.text);

                    // Bilgileri Kaydet
                    await UserPreferences().saveDetailedUserInfo(
                      name: _nameController.text.trim(),
                      weight: formatMeasurement(startingWeight),
                      height: formatMeasurement(startingHeight),
                      level: _selectedLevel,
                      gender: _selectedGender,
                      weeklyGoal: startingGoal.toString(),
                      targetWeight: targetWeight == null
                          ? ''
                          : formatMeasurement(targetWeight),
                    );

                    // Başlangıç kilosunu geçmişe düş: "%x daha fitsin" kartının
                    // kıyaslayacağı referans nokta bu ilk kayıt.
                    await WorkoutDao().insertWeightRecord(startingWeight);

                    // Onboarding tamamlandı yap
                    await UserPreferences().setCompletedOnboarding(true);

                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const RootLayout()),
                      );
                    }
                  },
                  child: const Text(
                    "Sisteme Giriş Yap",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.volt),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.stroke)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.volt, width: 2)),
      ),
    );
  }
}
