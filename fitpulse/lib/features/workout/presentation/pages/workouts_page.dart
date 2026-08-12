import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart'; // Kendi proje yapına göre yolu düzeltmen gerekebilir
import '../../../../core/theme/program_visuals.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/workout_model.dart';
import 'package:fitpulse/features/workout/presentation/pages/workout_detail_page.dart'; // Veya kendi tam klasör yolun

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  // Veritabanı motorumuz
  final WorkoutDao _workoutDao = WorkoutDao();

  // Veritabanından gelecek gerçek listeyi tutacağımız değişken
  List<WorkoutProgram> _allWorkouts = [];

  // Veriler yüklenirken ekranda dönecek loading animasyonu için
  bool _isLoading = true;

  // Varsayılan aktif filtre
  String _selectedFilter = 'All';

  // Üst menüdeki filtre seçenekleri
  final List<String> _filters = ['All', 'Strength', 'Cardio', 'Flexibility'];

  @override
  void initState() {
    super.initState();
    _loadWorkoutsFromDB();
  }

  // Sayfa açıldığında SQLite'a gidip verileri çeken fonksiyon
  Future<void> _loadWorkoutsFromDB() async {
    final programs = await _workoutDao.getAllPrograms();
    if (!mounted) return;
    setState(() {
      _allWorkouts = programs;
      _isLoading = false; // Veri geldi, loading'i kapat
    });
  }

  @override
  Widget build(BuildContext context) {
    // Seçili Filtreye Göre Listeyi Ekrana Basmadan Önce Süzme (Filtreleme) Mantığı
    final filteredWorkouts = _selectedFilter == 'All'
        ? _allWorkouts
        : _allWorkouts
            .where((w) => w.tag.toUpperCase() == _selectedFilter.toUpperCase())
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Workouts',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search,
                color: AppColors.textPrimary, size: 28),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          // Veri çekilirken ortada spinner dönsün
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.volt))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dinamik Filtre Butonları
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _filters.length,
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isActive = filter == _selectedFilter;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedFilter = filter;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color:
                                isActive ? AppColors.volt : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  isActive ? AppColors.volt : AppColors.stroke,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isActive
                                    ? Colors.black
                                    : AppColors.textSecondary,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Filtrelenmiş Kartları Ekrana Çizme
                // Filtrelenmiş Kartları Ekrana Çizme
                Expanded(
                  child: filteredWorkouts.isEmpty
                      ? const Center(
                          child: Text(
                            'Bu kategoriye ait antrenman bulunamadı.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: filteredWorkouts.length,
                          itemBuilder: (context, index) {
                            final workout = filteredWorkouts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          WorkoutDetailPage(workout: workout),
                                    ),
                                  );
                                  // Detayda favorilenmiş olabilir
                                  await _loadWorkoutsFromDB();
                                },
                                child: _WorkoutCard(
                                  title: workout.title,
                                  tag: workout.tag,
                                  duration: workout.duration,
                                  intensity: workout.intensity,
                                  placeholderColor:
                                      Color(workout.placeholderColor),
                                  isSaved: workout.isSaved,
                                  // İŞTE BURAYA KAYDETME MANTIĞINI EKLİYORUZ
                                  onSave: () async {
                                    // true = eklendi, false = kaldırıldı
                                    final isAdded = await _workoutDao
                                        .toggleFavorite(workout.id!);

                                    // Bayrak değişti; ikonun dolu/boş hali için
                                    // listeyi tazeliyoruz
                                    await _loadWorkoutsFromDB();

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isAdded
                                                ? 'Antrenman "Taslaklarım" bölümüne eklendi!'
                                                : 'Antrenman taslaklardan kaldırıldı!',
                                            style: const TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          backgroundColor: AppColors.volt,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

// Görselli Antrenman Kartı Şablonu
// Görselli Antrenman Kartı Şablonu
class _WorkoutCard extends StatelessWidget {
  final String title;
  final String tag;
  final String duration;
  final String intensity;
  final Color placeholderColor;
  final bool isSaved; // Taslaklarımda mı — ikonun dolu/boş halini belirler
  final VoidCallback
      onSave; // YENİ: Kaydet butonuna basıldığında çalışacak fonksiyon

  const _WorkoutCard({
    required this.title,
    required this.tag,
    required this.duration,
    required this.intensity,
    required this.placeholderColor,
    required this.isSaved,
    required this.onSave, // YENİ EKLENDİ
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Hazır şablonlarda gömülü fotoğraf, kendi şablonlarında gradyan
          Positioned.fill(child: ProgramVisuals.background(title, tag)),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.volt,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // YENİ: İkonu tıklanabilir yaptık ve onSave'i bağladık
                    GestureDetector(
                      onTap: onSave,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? AppColors.volt : Colors.white,
                            size: 20),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.show_chart,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          intensity,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
