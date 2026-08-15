import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/program_visuals.dart';
import '../../../../data/models/workout_model.dart';
import '../../../../data/local/daos/workout_dao.dart';
// ActiveWorkoutPage'i import etmeyi unutmuyoruz!
import 'active_workout_page.dart';

class WorkoutDetailPage extends StatefulWidget {
  final WorkoutProgram workout;

  const WorkoutDetailPage({super.key, required this.workout});

  @override
  State<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends State<WorkoutDetailPage> {
  // Yer imi ikonunun anlık hali; sayfaya girerken kayıtlı durumdan başlar
  late bool _isSaved = widget.workout.isSaved;

  // Future build içinde değil burada kuruluyor: aksi halde her yeniden çizimde
  // (örneğin yer imine basıldığında) yeni bir veritabanı sorgusu başlıyor.
  late final Future<List<ProgramExercise>> _exercisesFuture =
      WorkoutDao().getExercisesForProgram(widget.workout.id!);

  @override
  Widget build(BuildContext context) {
    final workout = widget.workout;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300.0,
            pinned: true,
            backgroundColor: Color(workout.placeholderColor),
            actions: [
              IconButton(
                icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: _isSaved ? AppColors.volt : Colors.white, size: 28),
                onPressed: () async {
                  final isAdded =
                      await WorkoutDao().toggleFavorite(workout.id!);
                  if (!mounted) return;
                  setState(() => _isSaved = isAdded);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isAdded
                              ? 'Antrenman "Taslaklarım" bölümüne eklendi!'
                              : 'Antrenman taslaklardan kaldırıldı!',
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: AppColors.volt,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                workout.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Fotoğrafı olan şablonlarda gömülü görsel, olmayanlarda
                  // etiketten türetilen gradyan; ikisi de ağa gitmiyor
                  ProgramVisuals.background(workout.title, workout.tag),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(Icons.schedule, workout.duration),
                      _buildStatColumn(Icons.show_chart, workout.intensity),
                      _buildStatColumn(Icons.category, workout.tag),
                    ],
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Hareketler',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<ProgramExercise>>(
                    future: _exercisesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator(
                                color: AppColors.volt));
                      } else if (snapshot.hasError) {
                        return const Text(
                            'Egzersizler yüklenirken hata oluştu.',
                            style: TextStyle(color: Colors.white));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text(
                            'Bu program için henüz egzersiz eklenmemiş.',
                            style: TextStyle(color: Colors.white54));
                      }

                      final exercises = snapshot.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: exercises.length,
                        itemBuilder: (context, index) {
                          final exercise = exercises[index];
                          return _buildMockExerciseCard(
                            exercise.exerciseName,
                            '${exercise.sets} Set',
                            '${exercise.reps} Tekrar',
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ElevatedButton(
            // İŞTE BURASI: Doğrudan ActiveWorkoutPage'e uçuyoruz!
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActiveWorkoutPage(
                    workoutTitle: workout.title, // Şablonun adını yolladık
                    programId: workout.id, // hareketler bu id'den yüklenecek
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.volt,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'ANTRENMANA BAŞLA',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AppColors.volt, size: 28),
        const SizedBox(height: 8),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMockExerciseCard(String name, String sets, String reps) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.stroke.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stroke.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                sets,
                style: const TextStyle(
                  color: AppColors.volt,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                reps,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
