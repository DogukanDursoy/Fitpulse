import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/services/user_preferences.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/core/widgets/user_avatar.dart';
import 'package:fitpulse/core/utils/measurement_input.dart';
import 'package:fitpulse/data/models/workout_model.dart';
import 'package:fitpulse/features/templates/presentation/pages/templates_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WorkoutDao _workoutDao = WorkoutDao();

  String _userName = 'Şampiyon';
  String _userImage = '';
  int _weeklyGoal = 4;

  // Bu haftanın (pazartesi -> pazar) antrenman yapılan günleri
  Set<DateTime> _sessionDays = {};
  late DateTime _weekStart;

  // Form kartı: ilk kayıt, güncel kilo ve hedef
  double? _firstWeight;
  double? _latestWeight;
  double? _targetWeight;

  // Gelişim kartı: compound e1RM kıyası
  StrengthProgress? _progress;

  // Haftalık hedefin üst üste kaç haftadır tutturulduğu
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _weekStart = WorkoutDao.weekStart(DateTime.now());
    _loadUserData();
  }

  // SharedPreferences'tan profil bilgisini, SQLite'tan haftalık aktiviteyi
  // ve kilo geçmişini çekiyoruz
  Future<void> _loadUserData() async {
    final data = await UserPreferences().getUserInfo();
    // Hafta sınırını her yüklemede tazeliyoruz ki uygulama açık kalsa bile
    // pazartesi olunca çubuklar kendiliğinden sıfırlansın.
    final weekStart = WorkoutDao.weekStart(DateTime.now());

    final sessionDays = await _workoutDao.getSessionDays(
      weekStart,
      weekStart.add(const Duration(days: 7)),
    );
    final firstWeight = await _workoutDao.getFirstWeight();
    final latestWeight = await _workoutDao.getLatestWeight();
    // Vücut ağırlıklı compound'ların (barfiks, dips, şınav) e1RM'i için kilo gerekli
    final progress = await _workoutDao.getStrengthProgress(
      bodyWeight: latestWeight ?? 0,
    );
    final weeklyGoal = parseWeeklyGoal(data['goal']) ?? 4;
    final streak = await _workoutDao.getWeeklyGoalStreak(weeklyGoal);

    if (!mounted) return;
    setState(() {
      _userName = data['name'] ?? 'Şampiyon';
      _userImage = data['image'] ?? '';
      _weeklyGoal = weeklyGoal;
      _streak = streak;
      _targetWeight = parseWeightKg(data['targetWeight']);
      _weekStart = weekStart;
      _sessionDays = sessionDays;
      _firstWeight = firstWeight;
      _latestWeight = latestWeight;
      _progress = progress;
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
                  child: UserAvatar(
                    name: _userName,
                    imagePath: _userImage,
                    radius: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 2. ANTRENMANA BAŞLA KARTI (Tıklanınca TemplatesPage'e uçar)
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TemplatesPage(),
                  ),
                );
                // Antrenman kaydedilmiş olabilir; haftalık aktiviteyi tazele
                await _loadUserData();
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

            // 3. HAFTALIK HEDEF VE SERİ KARTI
            _buildStreakCard(),
            const SizedBox(height: 16),

            // 4. YAN YANA KARTLAR: Kalp Atışı ve Kalori
            Row(
              children: [
                Expanded(child: _buildProgressCard()),
                const SizedBox(width: 16),
                Expanded(child: _buildFormCard()),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weekly Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      // Uydurma yüzde yerine gerçek veri: bu hafta / haftalık hedef
                      Text(
                        '${_sessionDays.length}/$_weeklyGoal hedef',
                        style: TextStyle(
                          color: _sessionDays.length >= _weeklyGoal
                              ? AppColors.volt
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(7, (index) {
                      final day = _weekStart.add(Duration(days: index));
                      return _buildDayCube(day, _dayLabels[index]);
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _dayLabels = [
    'Pt',
    'Sa',
    'Ça',
    'Pe',
    'Cu',
    'Ct',
    'Pa'
  ];

  // Haftanın bir günü: antrenman girildiyse volt dolu küp.
  // Hafta pazartesi başladığı için her pazartesi kendiliğinden sıfırlanır.
  Widget _buildDayCube(DateTime day, String label) {
    final isTrained = _sessionDays.contains(day);
    final today = DateTime.now();
    final isToday = day == DateTime(today.year, today.month, today.day);

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isTrained ? AppColors.volt : AppColors.background,
            borderRadius: BorderRadius.circular(12), // köşesi yuvarlak küp
            border: Border.all(
              color: isTrained
                  ? AppColors.volt
                  : (isToday ? AppColors.volt : AppColors.stroke),
              width: isToday && !isTrained ? 1.5 : 1,
            ),
          ),
          child: isTrained
              ? const Icon(Icons.check, color: Colors.black, size: 20)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isTrained
                ? AppColors.volt
                : (isToday ? Colors.white : AppColors.textSecondary),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // HAFTALIK HEDEF VE SERİ KARTI
  //
  // Adım sayacının yerini aldı. Halka bu haftanın hedefe göre doluluğu,
  // sağdaki büyük sayı ise üst üste kaç haftadır hedefin tutturulduğu.
  Widget _buildStreakCard() {
    final done = _sessionDays.length;
    final goal = _weeklyGoal > 0 ? _weeklyGoal : 1;
    final remaining = goal - done;
    final isGoalMet = remaining <= 0;
    final ratio = (done / goal).clamp(0.0, 1.0);

    return Container(
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
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: ratio,
                  backgroundColor: AppColors.background,
                  color: AppColors.volt,
                  strokeWidth: 9,
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$done/$goal',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'BU HAFTA',
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
                Text(
                  _streak > 0 ? '$_streak HAFTALIK SERİ' : 'Seri Bekliyor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _streak > 0
                      ? 'Üst üste $_streak haftadır haftalık hedefini tutturuyorsun.'
                      : 'Bu haftanın hedefini tuttur, seri başlasın.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isGoalMet ? AppColors.volt : AppColors.stroke),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isGoalMet
                            ? Icons.local_fire_department
                            : Icons.flag_outlined,
                        color: isGoalMet
                            ? AppColors.volt
                            : AppColors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isGoalMet
                            ? 'HEDEF TAMAM'
                            : '$remaining ANTRENMAN KALDI',
                        style: TextStyle(
                          color: isGoalMet
                              ? AppColors.volt
                              : AppColors.textSecondary,
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
    );
  }

  // GELİŞİM KARTI: son 14 gün ile önceki 14 günün compound e1RM kıyası.
  Widget _buildProgressCard() {
    final progress = _progress;
    final percent = progress?.changePercent;
    final hasResult = percent != null;
    final isUp = hasResult && percent > 0.05;
    final isDown = hasResult && percent < -0.05;

    // Veri yoksa neyin eksik olduğunu söylüyoruz
    String subtitle;
    if (!hasResult) {
      subtitle = (progress?.hasPreviousData ?? false)
          ? 'Bu dönem kayıt yok'
          : 'Veri topluyor';
    } else if (progress!.isLowConfidence) {
      subtitle = '1 harekete göre';
    } else {
      subtitle = '${progress.comparedLifts} harekete göre';
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
                'GELİŞİM',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                isDown ? Icons.trending_down : Icons.trending_up,
                color: isUp ? AppColors.volt : AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hasResult
                ? '${percent >= 0 ? '+' : '−'}%${percent.abs().toStringAsFixed(1)}'
                : '—',
            style: TextStyle(
              color: isUp ? AppColors.volt : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasResult ? 'son 14 günde' : subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasResult) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // FORM KARTI: başlangıç kilosundan hedef kiloya giden yolun ne kadarı bitti.
  //
  // Yön sorununu bu formül kendiliğinden çözüyor: kilo vermek de almak da
  // "hedefe yaklaşmak" olarak ölçülüyor, ayrıca bir hedef türü sormaya gerek yok.
  Widget _buildFormCard() {
    final first = _firstWeight;
    final latest = _latestWeight;
    final target = _targetWeight;

    final hasWeights = first != null && latest != null;
    final hasTarget =
        hasWeights && target != null && (target - first).abs() > 0.01;

    double? completion; // hedefe giden yolun yüzdesi
    if (hasTarget) {
      completion =
          ((first - latest) / (first - target) * 100).clamp(0.0, 100.0);
    }

    final reached = completion != null && completion >= 99.5;

    // Hedef girilmemişse ilk kayda göre değişimi göstermeye devam ediyoruz
    final fallbackChange = hasWeights && first > 0 && !hasTarget
        ? ((latest - first) / first * 100).abs()
        : null;

    String value;
    String caption;
    if (completion != null) {
      value = '%${completion.round()}';
      caption = reached ? 'Hedefe ulaştın' : 'hedef yolunda';
    } else if (fallbackChange != null) {
      value = '%${fallbackChange.toStringAsFixed(1)}';
      caption = fallbackChange < 0.05 ? 'İlk kayıtla aynı' : 'kilo değişimi';
    } else {
      value = '—';
      caption = 'Kilonu güncelle';
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
                'FORM',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(
                reached ? Icons.emoji_events : Icons.flag_outlined,
                color: completion != null && completion > 0
                    ? AppColors.volt
                    : AppColors.textSecondary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: reached ? AppColors.volt : Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            caption,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasWeights) ...[
            const SizedBox(height: 2),
            Text(
              hasTarget
                  ? '${_formatWeight(latest)} → ${_formatWeight(target)} kg hedef'
                  : '${_formatWeight(first)} → ${_formatWeight(latest)} kg',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatWeight(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}
