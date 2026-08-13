import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/services/user_preferences.dart';
import 'package:fitpulse/core/widgets/user_avatar.dart';
import 'package:fitpulse/core/utils/measurement_input.dart';
import 'package:fitpulse/core/utils/turkish_date.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/achievement_model.dart';
import 'package:fitpulse/data/models/workout_model.dart';
import 'package:fitpulse/features/profile/presentation/pages/credits_page.dart';

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
  String _targetWeight = '';

  // Rekor kartı: veri gelene kadar hiç çizilmiyor, boş bir kart yanıp sönmesin
  List<PersonalRecord> _records = const [];
  bool _recordsLoaded = false;

  // Aylık aktivite haritası: gün -> o günkü tonaj. Anahtarın varlığı o gün
  // antrenman yapıldığını, değeri ne kadar yüklenildiğini söyler.
  Map<DateTime, double> _dailyVolumes = const {};
  bool _heatmapLoaded = false;

  // Rozetler tamamen kayıtlardan türetiliyor, veritabanında saklanmıyor
  List<Achievement> _achievements = const [];

  /// Haritanın ilk günü: içinde bulunulan hafta dahil 4 tam hafta geriye.
  /// Pazartesiye hizalı olduğu için her sütun sabit bir güne denk geliyor.
  static DateTime get _heatmapStart =>
      WorkoutDao.weekStart(DateTime.now()).subtract(const Duration(days: 21));

  static const List<String> _dayLabels = [
    'Pt',
    'Sa',
    'Ça',
    'Pe',
    'Cu',
    'Ct',
    'Pa'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadPersonalRecords();
    _loadHeatmap();
  }

  Future<void> _loadHeatmap() async {
    final start = _heatmapStart;
    final volumes = await WorkoutDao()
        .getDailyVolumes(start, start.add(const Duration(days: 28)));
    if (!mounted) return;
    setState(() {
      _dailyVolumes = volumes;
      _heatmapLoaded = true;
    });
  }

  /// Vücut ağırlıklı hareketlerin (barfiks, dips, şınav) rekoru güncel kiloya
  /// bağlı olduğu için önce onu okuyoruz.
  Future<void> _loadPersonalRecords() async {
    final dao = WorkoutDao();
    final bodyWeight = await dao.getLatestWeight() ?? 0;
    final records = await dao.getPersonalRecords(bodyWeight: bodyWeight);
    if (!mounted) return;
    setState(() {
      _records = records;
      _recordsLoaded = true;
    });
  }

  Future<void> _loadUserData() async {
    final data = await UserPreferences().getUserInfo();
    if (!mounted) return;
    setState(() {
      _userName = data['name'] ?? 'Şampiyon';
      _userImage = data['image'] ?? '';
      _weeklyGoal = data['goal'] ?? '4';
      _userHeight = data['height'] ?? '175';
      _userWeight = data['weight'] ?? '75';
      _targetWeight = data['targetWeight'] ?? '';
    });

    // "Seri" rozeti haftalık hedefe bağlı, o yüzden profil verisinden sonra
    await _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final stats = await WorkoutDao()
        .getAchievementStats(weeklyGoal: parseWeeklyGoal(_weeklyGoal) ?? 4);
    if (!mounted) return;
    setState(() => _achievements = buildAchievements(stats));
  }

  void _showEditProfileDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: _userName);
    final heightController = TextEditingController(text: _userHeight);
    final goalController = TextEditingController(text: _weeklyGoal);
    final weightController = TextEditingController(text: _userWeight);
    final targetWeightController = TextEditingController(text: _targetWeight);

    // Ondalık ayırıcı klavyeden gelebilsin diye; parse zaten virgülü de çözüyor
    const numberInput = TextInputType.numberWithOptions(decimal: true);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Profili Düzenle',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İSİM (Üzerine yazılır)
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Adın',
                      labelStyle: TextStyle(color: AppColors.textSecondary)),
                  validator: (value) =>
                      (value == null || value.trim().isEmpty) ? 'Adını gir' : null,
                ),
                const SizedBox(height: 12),
                // BOY (Üzerine yazılır)
                TextFormField(
                  controller: heightController,
                  keyboardType: numberInput,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Boy (cm)',
                      labelStyle: TextStyle(color: AppColors.textSecondary)),
                  validator: validateHeight,
                ),
                const SizedBox(height: 12),
                // HEDEF (Üzerine yazılır)
                TextFormField(
                  controller: goalController,
                  keyboardType: numberInput,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Haftalık Hedef (Gün)',
                      labelStyle: TextStyle(color: AppColors.textSecondary)),
                  validator: validateWeeklyGoal,
                ),
                const SizedBox(height: 12),
                // KİLO (Hem üzerine yazılır, hem geçmişe loglanır)
                TextFormField(
                  controller: weightController,
                  keyboardType: numberInput,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Güncel Kilo (kg)',
                      labelStyle: TextStyle(color: AppColors.textSecondary)),
                  validator: validateWeight,
                ),
                const SizedBox(height: 12),
                // HEDEF KİLO (Ana sayfadaki form kartının referansı)
                TextFormField(
                  controller: targetWeightController,
                  keyboardType: numberInput,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: 'Hedef Kilo (kg)',
                      labelStyle: TextStyle(color: AppColors.textSecondary)),
                  validator: validateOptionalTargetWeight,
                ),
              ],
            ),
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
              // Geçersiz girdide hata mesajları alanların altında görünür ve
              // dialog açık kalır; hiçbir şey kaydedilmez.
              if (!formKey.currentState!.validate()) return;

              final newName = nameController.text.trim();

              // Doğrulama geçtiğine göre parse'lar null dönemez; değerleri tek
              // biçime sokup öyle saklıyoruz ki "72,5" geri okunabilir kalsın.
              final newHeight =
                  formatMeasurement(parseHeightCm(heightController.text)!);
              final newGoal =
                  parseWeeklyGoal(goalController.text)!.toString();
              final parsedWeight = parseWeightKg(weightController.text)!;
              final newWeight = formatMeasurement(parsedWeight);

              final parsedTarget = parseWeightKg(targetWeightController.text);
              final newTargetWeight =
                  parsedTarget == null ? '' : formatMeasurement(parsedTarget);

              // 1. SharedPreferences'a güncel hallerini kaydet (üzerine yaz)
              await UserPreferences().updateProfileSettings(
                name: newName,
                height: newHeight,
                weeklyGoal: newGoal,
                weight: newWeight,
                targetWeight: newTargetWeight,
              );

              // 2. EĞER KİLO DEĞİŞMİŞSE -> SQLite veritabanına yeni metrik olarak logla (Tarihli Kayıt)
              if (newWeight != _userWeight) {
                await WorkoutDao().insertWeightRecord(parsedWeight);
              }

              if (!mounted) return;

              // 3. Arayüzü güncelle
              setState(() {
                _userName = newName;
                _userHeight = newHeight;
                _weeklyGoal = newGoal;
                _userWeight = newWeight;
                _targetWeight = newTargetWeight;
              });

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

  // Isı skalası: boş gün, hafif, orta, ağır
  static const List<Color> _heatColors = [
    Color(0xFF1C221E),
    Color(0xFF384E29),
    Color(0xFF6B9A34),
    AppColors.volt,
  ];

  /// Aylık aktivite haritası. Önceden renkler hücrenin sırasından
  /// hesaplanıyordu — herkeste aynı desen çıkıyor, hiç antrenman yapmamış biri
  /// bile dolu bir takvim görüyordu.
  Widget _buildActivityHeatmap() {
    final start = _heatmapStart;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Skala pencere içindeki en ağır güne göre; tek bir rekor gün, geri kalan
    // her şeyi sönük göstermesin diye 28 günle sınırlı.
    final maxVolume = _dailyVolumes.values.fold<double>(0, math.max);
    final trainedDays = _dailyVolumes.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.stroke, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Aylık Aktivite',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                _heatmapLoaded ? '$trainedDays/28 gün' : 'Son 4 hafta',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_heatmapLoaded)
            const SizedBox(
              height: 148,
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.volt)),
            )
          else ...[
            Row(
              children: [
                for (final label in _dayLabels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.3,
              ),
              itemCount: 28,
              itemBuilder: (context, index) {
                final day = start.add(Duration(days: index));

                // Bu haftanın gelmemiş günleri "antrenman kaçırıldı" gibi
                // görünmesin diye boş günden ayrı çiziliyor
                if (day.isAfter(today)) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.stroke, width: 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: _heatColorFor(day, maxVolume),
                    borderRadius: BorderRadius.circular(6),
                    border: day == today
                        ? Border.all(color: AppColors.volt, width: 1.5)
                        : null,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Bir günün rengi. Antrenman yapılmadıysa sönük; yapıldıysa en az bir kademe
  /// yanar — kardiyo seansları tonaj üretmediği için yalnızca hacme bakmak
  /// 45 dakika koşulan bir günü boş gösterirdi.
  Color _heatColorFor(DateTime day, double maxVolume) {
    final volume = _dailyVolumes[day];
    if (volume == null) return _heatColors[0];
    if (maxVolume <= 0) return _heatColors[1];

    final ratio = volume / maxVolume;
    if (ratio <= 1 / 3) return _heatColors[1];
    if (ratio <= 2 / 3) return _heatColors[2];
    return _heatColors[3];
  }

  /// Rekor kartı. Satırlar WorkoutSets'ten geliyor; gösterilen ağırlık ve
  /// tekrar kullanıcının o gün gerçekten yaptığı settir.
  List<Widget> _buildPersonalRecords() {
    if (!_recordsLoaded) return const [];

    return [
      const Text(
        'Kişisel Rekorlar',
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
        child: _records.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Henüz rekorun yok. Antrenman kaydettikçe her hareketteki '
                  'en iyi setin burada görünecek.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            : Column(
                children: [
                  for (var i = 0; i < _records.length; i++)
                    _PrTile(
                      title: _records[i].exerciseName,
                      date: _recordSubtitle(_records[i]),
                      value: _recordValue(_records[i]),
                      showDivider: i < _records.length - 1,
                    ),
                ],
              ),
      ),
      const SizedBox(height: 24),
    ];
  }

  // Ek yük takılmamış barfiks/şınavda rekoru kilo değil tekrar sayısı anlatır
  static String _recordValue(PersonalRecord record) => record.isBodyweightOnly
      ? '${record.reps} tekrar'
      : '${formatMeasurement(record.weight)} kg';

  static String _recordSubtitle(PersonalRecord record) {
    final date = formatShortDate(record.date);
    return record.isBodyweightOnly
        ? 'Vücut ağırlığı · $date'
        : '${record.reps} tekrar · $date';
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
                    child: UserAvatar(
                    name: _userName,
                    imagePath: _userImage,
                    radius: 32,
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

            // 2. AYLIK AKTİVİTE HARİTASI
            _buildActivityHeatmap(),
            const SizedBox(height: 24),

            // 3. ROZETLER
            const Text(
              'Rozetler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 64,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) =>
                    _AchievementBadge(achievement: _achievements[index]),
              ),
            ),
            const SizedBox(height: 24),

            // 4. KİŞİSEL REKORLAR
            ..._buildPersonalRecords(),

            // Uygulamada kullanılan üçüncü taraf içeriklerin kaynakları
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreditsPage()),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.stroke, width: 1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: AppColors.textSecondary, size: 22),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Krediler',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: AppColors.textSecondary, size: 22),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Tek rozet. Kazanılmamış rozet de gösteriliyor ama sönük — hedefi görmek
/// kazanılmış rozet kadar değerli, ve sadece kazanılanları göstermek yeni
/// kullanıcıya bomboş bir şerit bırakırdı.
class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final earned = achievement.isEarned;
    final accent = earned ? AppColors.volt : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: earned ? AppColors.volt.withValues(alpha: 0.35) : AppColors.stroke,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(achievement.icon, color: accent, size: 20),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    achievement.title,
                    style: TextStyle(
                      color: earned ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (earned) ...[
                    const SizedBox(width: 6),
                    _TierPips(
                        tier: achievement.tier, maxTier: achievement.maxTier),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                achievement.label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Kademe göstergesi: kazanılan kademe kadar dolu nokta.
class _TierPips extends StatelessWidget {
  final int tier;
  final int maxTier;

  const _TierPips({required this.tier, required this.maxTier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < maxTier; i++)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < tier ? AppColors.volt : AppColors.stroke,
              ),
            ),
          ),
      ],
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
