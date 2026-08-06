import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

// 1. Antrenman Veri Modeli (Şimdilik Sahte Veriler İçin)
class _WorkoutInfo {
  final String title;
  final String tag;
  final String duration;
  final String intensity;
  final Color placeholderColor;
  final String imageUrl;

  const _WorkoutInfo({
    required this.title,
    required this.tag,
    required this.duration,
    required this.intensity,
    required this.placeholderColor,
    required this.imageUrl,
  });
}

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  // Varsayılan aktif filtre
  String _selectedFilter = 'All';

  // Üst menüdeki filtre seçenekleri
  final List<String> _filters = ['All', 'Strength', 'Cardio', 'Flexibility'];

  // 2. Mock (Sahte) Antrenman Listesi
  final List<_WorkoutInfo> _allWorkouts = [
    const _WorkoutInfo(
      title: 'Power Hypertrophy',
      tag: 'STRENGTH',
      duration: '45 mins',
      intensity: 'Advanced',
      placeholderColor: Color(0xFF16181A),
      imageUrl:
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1000&auto=format&fit=crop', // Ağır demir
    ),
    const _WorkoutInfo(
      title: 'Vicious HIIT Shred',
      tag: 'CARDIO',
      duration: '25 mins',
      intensity: 'High Intensity',
      placeholderColor: Color(0xFF1E2124),
      imageUrl:
          'https://images.unsplash.com/photo-1518611012118-696072aa579a?q=80&w=1000&auto=format&fit=crop', // Koşu / Ter
    ),
    const _WorkoutInfo(
      title: 'Deep Core Recovery',
      tag: 'FLEXIBILITY',
      duration: '20 mins',
      intensity: 'Beginner',
      placeholderColor: Color(0xFF231B15),
      imageUrl:
          'https://images.unsplash.com/photo-1518310383802-640c2de311b2?q=80&w=1000&auto=format&fit=crop', // Esneme / Yoga
    ),
    const _WorkoutInfo(
      title: '5x5 Heavy Barbell',
      tag: 'STRENGTH',
      duration: '60 mins',
      intensity: 'Expert',
      placeholderColor: Color(0xFF1A1A1A),
      imageUrl:
          'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?q=80&w=1000&auto=format&fit=crop', // Barbell / Crossfit
    ),
    const _WorkoutInfo(
      title: 'Sprint Intervals',
      tag: 'CARDIO',
      duration: '15 mins',
      intensity: 'Maximum',
      imageUrl:
          'https://images.unsplash.com/photo-1461896836934-ffe607ba8211?q=80&w=1000&auto=format&fit=crop', // Atletizm / Pist
      placeholderColor: Color(0xFF2A2424),
    ),
    const _WorkoutInfo(
      title: 'Dynamic Yoga Flow',
      tag: 'FLEXIBILITY',
      duration: '30 mins',
      intensity: 'Intermediate',
      imageUrl:
          'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=1000&auto=format&fit=crop', // Meditasyon / Poz
      placeholderColor: Color(0xFF15201A),
    ),
    const _WorkoutInfo(
      title: 'Push-Pull Power',
      tag: 'STRENGTH',
      duration: '50 mins',
      intensity: 'Advanced',
      imageUrl:
          'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?q=80&w=1000&auto=format&fit=crop', // Dumbbell / Rack
      placeholderColor: Color(0xFF1C1822),
    ),
    const _WorkoutInfo(
      title: 'Metabolic Engine',
      tag: 'CARDIO',
      duration: '35 mins',
      intensity: 'High Intensity',
      imageUrl:
          'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?q=80&w=1000&auto=format&fit=crop', // Halat / Kardiyo
      placeholderColor: Color(0xFF221818),
    ),
    const _WorkoutInfo(
      title: 'Upper Body Armor',
      tag: 'STRENGTH',
      duration: '40 mins',
      intensity: 'Intermediate',
      imageUrl:
          'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?q=80&w=1000&auto=format&fit=crop', // Üst vücut
      placeholderColor: Color(0xFF181C22),
    ),
    const _WorkoutInfo(
      title: 'Joint Mobility',
      tag: 'FLEXIBILITY',
      duration: '15 mins',
      intensity: 'Beginner',
      imageUrl:
          'https://images.unsplash.com/photo-1506126613408-eca07ce68773?q=80&w=1000&auto=format&fit=crop', // Doğa / Hareket
      placeholderColor: Color(0xFF182221),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // 3. Seçili Filtreye Göre Listeyi Ekrana Basmadan Önce Süzme (Filtreleme) Mantığı
    final filteredWorkouts = _selectedFilter == 'All'
        ? _allWorkouts
        : _allWorkouts
            .where((w) => w.tag == _selectedFilter.toUpperCase())
            .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Workouts',
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4. Dinamik Filtre Butonları
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isActive = filter == _selectedFilter;

                return GestureDetector(
                  onTap: () {
                    // Butona basıldığında UI'ı günceller
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.volt : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.volt : AppColors.stroke,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          color:
                              isActive ? Colors.black : AppColors.textSecondary,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w600,
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

          // 5. Filtrelenmiş Kartları Ekrana Çizme
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: filteredWorkouts.length,
              itemBuilder: (context, index) {
                final workout = filteredWorkouts[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _WorkoutCard(
                    title: workout.title,
                    tag: workout.tag,
                    duration: workout.duration,
                    intensity: workout.intensity,
                    placeholderColor: workout.placeholderColor,
                    imageUrl: workout.imageUrl,
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

// Görselli Antrenman Kartı Şablonu (Değişmedi, aynı tasarımı koruyoruz)
class _WorkoutCard extends StatelessWidget {
  final String title;
  final String tag;
  final String duration;
  final String intensity;
  final Color placeholderColor;
  final String imageUrl;

  const _WorkoutCard({
    required this.title,
    required this.tag,
    required this.duration,
    required this.intensity,
    required this.placeholderColor,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: placeholderColor,
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
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
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.bookmark_border,
                          color: Colors.white, size: 20),
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
                        fontSize: 22,
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
                              fontSize: 13,
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
