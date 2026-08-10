import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/workout_model.dart';
import 'package:fitpulse/features/workout/presentation/pages/active_workout_page.dart';
import 'package:fitpulse/features/workout/presentation/pages/workout_detail_page.dart';
import 'package:fitpulse/core/services/user_preferences.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  String _userName = 'Şampiyon';
  String _userImage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Kullanıcı adını ve resmini hafızadan çekiyoruz
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
            // 1. HEADER: Dinamik Karşılama Alanı
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hoş Geldin,',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName, // Artık statik değil, senin adın yazacak
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.stroke, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 24,
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
            const SizedBox(height: 32),

            // 2. HERO BUTON: Boş Antrenman Başlat
            GestureDetector(
              onTap: () {
                // İŞTE BURASI: Menü kaldırıldı, direkt kayıt ekranına uçuruyoruz!
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActiveWorkoutPage(
                      workoutTitle: 'Boş Antrenman',
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.volt,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.volt.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Boş Antrenman',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Hemen serbest ağırlığa geç',
                          style: TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    Icon(Icons.add_circle_outline,
                        color: Colors.black, size: 36),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 3. KAYITLI ŞABLONLAR BAŞLIĞI
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Taslaklarım',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. DİNAMİK TASLAK KARTLARI
            FutureBuilder<List<WorkoutProgram>>(
              future: WorkoutDao().getDraftWorkouts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.volt));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Text(
                        'Henüz taslak antrenman eklemedin.\nAna sayfadan favorileyebilirsin!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ),
                  );
                }

                final drafts = snapshot.data!;
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: drafts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final draft = drafts[index];
                    return GestureDetector(
                      onTap: () {
                        // Taslak detayına gider, oradaki buton da direkt kayıt ekranına atar
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WorkoutDetailPage(workout: draft),
                          ),
                        );
                      },
                      child: _TemplateCard(
                        title: draft.title,
                        tag: draft.tag,
                        duration: draft.duration,
                        intensity: draft.intensity,
                        placeholderColor: Color(draft.placeholderColor),
                        imageUrl: draft.imageUrl,
                        onToggle: () async {
                          final dao = WorkoutDao();
                          final exercises =
                              await dao.getExercisesForProgram(draft.id!);
                          await dao.toggleDraftWorkout(draft, exercises);
                          setState(() {}); // UI'ı yenilemek için
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Taslak Kartı Bileşeni
class _TemplateCard extends StatelessWidget {
  final String title;
  final String tag;
  final String duration;
  final String intensity;
  final Color placeholderColor;
  final String imageUrl;
  final VoidCallback onToggle;

  const _TemplateCard({
    required this.title,
    required this.tag,
    required this.duration,
    required this.intensity,
    required this.placeholderColor,
    required this.imageUrl,
    required this.onToggle,
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
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onToggle,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bookmark,
                            color: AppColors.volt, size: 20),
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
