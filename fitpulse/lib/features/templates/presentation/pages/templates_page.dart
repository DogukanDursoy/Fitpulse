import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/theme/program_visuals.dart';
import 'package:fitpulse/core/widgets/user_avatar.dart';
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
  final WorkoutDao _workoutDao = WorkoutDao();

  String _userName = 'Şampiyon';
  String _userImage = '';

  // Future build içinde yaratılmıyor: aksi halde klavye açılması, ekran
  // döndürme gibi alakasız her yeniden çizim de veritabanına gidiyordu.
  // Liste tazelemesi artık niyetli — _refreshTemplates() ile.
  late Future<List<WorkoutProgram>> _templatesFuture =
      _workoutDao.getSavedPrograms();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _refreshTemplates() {
    // Ok gövdesi (=>) atanan Future'ı geri döndürüyordu ve setState bunu
    // hata sayıyor; istisna, listenin tazelenmesini yarıda kesiyordu.
    // Blok gövde hiçbir şey döndürmez.
    setState(() {
      _templatesFuture = _workoutDao.getSavedPrograms();
    });
  }

  // Kullanıcı adını ve resmini hafızadan çekiyoruz
  Future<void> _loadUserData() async {
    final data = await UserPreferences().getUserInfo();
    if (!mounted) return;
    setState(() {
      _userName = data['name'] ?? 'Şampiyon';
      _userImage = data['image'] ?? '';
    });
  }

  // Kendi şablonunu silmek geri alınamaz, o yüzden onay soruyoruz.
  // Antrenman geçmişi silinmez: foreign key SET NULL sayesinde o şablonla
  // yapılmış oturumlar kalır, sadece programla bağlantıları kopar.
  Future<void> _confirmDeleteTemplate(WorkoutProgram template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Şablonu sil',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          '"${template.title}" şablonu silinecek. '
          'Bu şablonla yaptığın antrenmanlar geçmişinde kalmaya devam eder.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _workoutDao.deleteUserTemplate(template.id!);
    if (!mounted) return;
    _refreshTemplates();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${template.title}" silindi.'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
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
                  child: UserAvatar(
                    name: _userName,
                    imagePath: _userImage,
                    radius: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 2. HERO BUTON: Boş Antrenman Başlat
            GestureDetector(
              onTap: () async {
                // İŞTE BURASI: Menü kaldırıldı, direkt kayıt ekranına uçuruyoruz!
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActiveWorkoutPage(
                      workoutTitle: 'Boş Antrenman',
                    ),
                  ),
                );
                // Antrenman şablon olarak da kaydedilmiş olabilir
                if (!mounted) return;
                _refreshTemplates();
              },
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.volt,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.volt.withValues(alpha: 0.2),
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
              future: _templatesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppColors.volt));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30.0),
                      child: Text(
                        'Henüz taslağın yok.\nAntrenman sekmesinden bir şablonu favorile\nya da kaydettiğin antrenmanı şablon olarak sakla.',
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
                    // Kullanıcının kendi şablonu mu, yoksa favorilenmiş hazır
                    // şablon mu: ilki silinir, ikincisi favoriden çıkarılır.
                    final isOwnTemplate = draft.isDraft == 1;

                    return GestureDetector(
                      onTap: () async {
                        // Taslak detayına gider, oradaki buton da direkt kayıt ekranına atar
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                WorkoutDetailPage(workout: draft),
                          ),
                        );
                        // Detayda favoriden çıkarılmış olabilir
                        if (!mounted) return;
                        _refreshTemplates();
                      },
                      child: _TemplateCard(
                        title: draft.title,
                        tag: draft.tag,
                        duration: draft.duration,
                        intensity: draft.intensity,
                        placeholderColor: Color(draft.placeholderColor),
                        isOwnTemplate: isOwnTemplate,
                        onToggle: () async {
                          if (isOwnTemplate) {
                            await _confirmDeleteTemplate(draft);
                          } else {
                            await _workoutDao.toggleFavorite(draft.id!);
                            if (!mounted) return;
                            _refreshTemplates();
                          }
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

  /// Kullanıcının kendi oluşturduğu şablon mu: öyleyse ikon "sil",
  /// değilse "favoriden çıkar" anlamına gelir.
  final bool isOwnTemplate;
  final VoidCallback onToggle;

  const _TemplateCard({
    required this.title,
    required this.tag,
    required this.duration,
    required this.intensity,
    required this.placeholderColor,
    required this.isOwnTemplate,
    required this.onToggle,
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
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.8),
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
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            isOwnTemplate
                                ? Icons.delete_outline
                                : Icons.bookmark,
                            color: isOwnTemplate
                                ? Colors.redAccent
                                : AppColors.volt,
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
