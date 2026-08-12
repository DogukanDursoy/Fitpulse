import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/local/daos/workout_dao.dart';
import '../widgets/muscle_heatmap.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final WorkoutDao _workoutDao = WorkoutDao();

  late DateTime _weekStart; // Görüntülenen haftanın pazartesisi
  Map<String, double> _volumes = {};
  bool _isLoading = true;

  static const List<String> _months = [
    'Oca',
    'Şub',
    'Mar',
    'Nis',
    'May',
    'Haz',
    'Tem',
    'Ağu',
    'Eyl',
    'Eki',
    'Kas',
    'Ara'
  ];

  @override
  void initState() {
    super.initState();
    _weekStart = WorkoutDao.weekStart(DateTime.now());
    _loadWeek();
  }

  Future<void> _loadWeek() async {
    setState(() => _isLoading = true);
    // Vücut ağırlıklı hareketlerin (barfiks, dips, şınav) hacme dönüşmesi için
    // güncel kiloya ihtiyacımız var.
    final bodyWeight = await _workoutDao.getLatestWeight() ?? 0;
    final volumes = await _workoutDao.getMuscleVolumes(
      _weekStart,
      _weekStart.add(const Duration(days: 7)),
      bodyWeight: bodyWeight,
    );
    if (!mounted) return;
    setState(() {
      _volumes = volumes;
      _isLoading = false;
    });
  }

  void _shiftWeek(int weeks) {
    setState(() {
      _weekStart = _weekStart.add(Duration(days: 7 * weeks));
    });
    _loadWeek();
  }

  bool get _isCurrentWeek =>
      _weekStart == WorkoutDao.weekStart(DateTime.now());

  String get _weekLabel {
    final end = _weekStart.add(const Duration(days: 6));
    final startText = '${_weekStart.day} ${_months[_weekStart.month - 1]}';
    final endText = '${end.day} ${_months[end.month - 1]}';
    return '$startText - $endText';
  }

  // 4200.0 -> "4.200"
  String _formatVolume(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Sıralı kas listesi (hacme göre azalan)
    final ranked = _volumes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVolume = ranked.isEmpty ? 0.0 : ranked.first.value;

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
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _isLoading ? null : _loadWeek,
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.volt,
          backgroundColor: AppColors.surface,
          onRefresh: _loadWeek,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 1. TARİH SEÇİCİ BAR
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.stroke, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _shiftWeek(-1),
                      icon: const Icon(Icons.chevron_left,
                          color: AppColors.textSecondary),
                    ),
                    Column(
                      children: [
                        Text(
                          _weekLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_isCurrentWeek)
                          const Text(
                            'Bu hafta',
                            style: TextStyle(
                              color: AppColors.volt,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                    IconButton(
                      // Gelecek haftaya gitmenin anlamı yok
                      onPressed: _isCurrentWeek ? null : () => _shiftWeek(1),
                      icon: Icon(
                        Icons.chevron_right,
                        color: _isCurrentWeek
                            ? AppColors.stroke
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. KAS HARİTASI
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.stroke, width: 1),
                ),
                child: Column(
                  children: [
                    MuscleHeatmap(volumes: _volumes),
                    const SizedBox(height: 20),

                    // Düşük - Yüksek Renk Skalası Çubuğu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              // Haritadaki skalanın birebir aynısı
                              colors: List.generate(
                                5,
                                (i) => _hexToColor(
                                    MuscleHeatmapColors.heatHex(i / 4)),
                              ),
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

              // 3. EN ÇOK ÇALIŞAN KASLAR
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

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                      child:
                          CircularProgressIndicator(color: AppColors.volt)),
                )
              else if (ranked.isEmpty)
                _buildEmptyState()
              else
                ...List.generate(
                  ranked.length > 6 ? 6 : ranked.length,
                  (index) {
                    final entry = ranked[index];
                    final ratio = entry.value / maxVolume;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildMuscleStatCard(
                        '${index + 1}',
                        entry.key,
                        'Haftalık Hacim: ${_formatVolume(entry.value)} kg',
                        '${(ratio * 100).round()}%',
                        _hexToColor(
                            MuscleHeatmapColors.heatHex(0.12 + ratio * 0.88)),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _hexToColor(String hex) =>
      Color(int.parse(hex.substring(1), radix: 16) | 0xFF000000);

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stroke, width: 1),
      ),
      child: const Column(
        children: [
          Icon(Icons.insights, color: AppColors.textSecondary, size: 32),
          SizedBox(height: 12),
          Text(
            'Bu hafta kayıtlı antrenman yok',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Bir antrenman kaydettiğinde kaslarının haftalık yükü burada renklenecek.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
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
