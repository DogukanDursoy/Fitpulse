import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/services/user_preferences.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/core/widgets/user_avatar.dart';
import 'package:fitpulse/core/utils/measurement_input.dart';
import 'package:fitpulse/data/models/workout_model.dart';
import 'package:fitpulse/features/homepage/presentation/widgets/home_summary_cards.dart';
import 'package:fitpulse/features/homepage/presentation/widgets/recent_session_tile.dart';
import 'package:fitpulse/features/templates/presentation/pages/templates_page.dart';
import 'package:fitpulse/features/workout/presentation/pages/active_workout_page.dart';
import 'package:fitpulse/features/workout/presentation/pages/workout_history_page.dart';

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

  /// Son antrenmanlar listesi. Beşle sınırlı: burası bir arşiv değil,
  /// "az önce yanlış girdim" anını yakalayacak kadar yakın geçmiş.
  static const int _recentSessionLimit = 5;
  List<WorkoutSession> _recentSessions = const [];

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
    final recentSessions =
        await _workoutDao.getLastNSessions(_recentSessionLimit);

    if (!mounted) return;
    setState(() {
      _recentSessions = recentSessions;
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
                      'Hoş geldin,',
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
                      color: AppColors.volt.withValues(alpha: 0.2),
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
            WeeklyStreakCard(
              done: _sessionDays.length,
              weeklyGoal: _weeklyGoal,
              streak: _streak,
            ),
            const SizedBox(height: 16),

            // 4. YAN YANA KARTLAR: Gelişim ve Form
            Row(
              children: [
                Expanded(child: StrengthProgressCard(progress: _progress)),
                const SizedBox(width: 16),
                Expanded(
                  child: WeightFormCard(
                    firstWeight: _firstWeight,
                    latestWeight: _latestWeight,
                    targetWeight: _targetWeight,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Haftalık Aktivite',
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
            const SizedBox(height: 16),

            // 6. SON ANTRENMANLAR
            ..._buildRecentSessions(),
          ],
        ),
      ),
    );
  }

  /// Son antrenmanlar. Kullanıcının kaydettiği bir antrenmanı geri
  /// bulabildiği TEK yer burası — düzenleme ve silme de buradan yapılıyor.
  List<Widget> _buildRecentSessions() {
    if (_recentSessions.isEmpty) return const [];

    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Son Antrenmanlar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: _openHistory,
            child: const Padding(
              // Dokunma alanını büyütmek için görünmez pay
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Tümünü Gör',
                style: TextStyle(
                  color: AppColors.volt,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      for (final session in _recentSessions) ...[
        RecentSessionTile(
          session: session,
          onTap: () => _openSessionForEditing(session),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
    ];
  }

  /// Tüm geçmiş listesine gider. Dönüşte veriler tazelenir: geçmişten bir
  /// antrenman düzenlenmiş ya da silinmiş olabilir.
  Future<void> _openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkoutHistoryPage()),
    );
    if (!mounted) return;
    await _loadUserData();
  }

  /// Antrenmanı düzenleme ekranında açar. Dönüşte her şeyi yeniden yüklüyoruz:
  /// silme ya da düzenleme, bu sayfadaki gelişim oranını, seriyi ve haftalık
  /// barı doğrudan etkiliyor.
  ///
  /// Diğer sekmeler (İstatistik, Profil) kendiliğinden tazeleniyor — sekme
  /// değiştirince State'leri yeniden kuruluyor ve verilerini baştan okuyorlar.
  Future<void> _openSessionForEditing(WorkoutSession session) async {
    if (session.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutPage(editSessionId: session.id),
      ),
    );
    if (!mounted) return;
    await _loadUserData();
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
}
