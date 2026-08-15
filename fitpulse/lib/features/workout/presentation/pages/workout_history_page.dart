import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/core/utils/turkish_date.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';
import 'package:fitpulse/data/models/workout_model.dart';
import 'package:fitpulse/features/homepage/presentation/widgets/recent_session_tile.dart';
import 'active_workout_page.dart';

/// Tüm antrenman geçmişi: en yeniden eskiye, ay başlıklarıyla bölünmüş,
/// kaydırdıkça yüklenen liste.
///
/// Ana sayfadaki "Son Antrenmanlar" 5 kayıtla sınırlı; daha eski bir kaydı
/// görmenin, düzeltmenin ya da silmenin tek yolu bu sayfa. Satıra dokunmak
/// aynı düzenleme ekranını açtığı için silme/düzenleme akışları ve çıkış
/// onayı burada da aynen geçerli.
class WorkoutHistoryPage extends StatefulWidget {
  const WorkoutHistoryPage({super.key});

  @override
  State<WorkoutHistoryPage> createState() => _WorkoutHistoryPageState();
}

class _WorkoutHistoryPageState extends State<WorkoutHistoryPage> {
  static const int _pageSize = 30;

  final WorkoutDao _workoutDao = WorkoutDao();
  final ScrollController _scrollController = ScrollController();

  final List<WorkoutSession> _sessions = [];
  bool _hasMore = true;
  bool _isLoading = false;
  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Sona 400 px kala sonraki sayfayı iste; kullanıcı yükleme anını görmesin
    if (_scrollController.position.extentAfter < 400) _loadMore();
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    _isLoading = true;

    final page = await _workoutDao.getSessions(
      limit: _pageSize,
      offset: _sessions.length,
    );
    if (!mounted) return;

    setState(() {
      _sessions.addAll(page);
      // Eksik sayfa geldiyse dip görülmüş demektir
      _hasMore = page.length == _pageSize;
      _initialLoaded = true;
      _isLoading = false;
    });
  }

  /// Düzenleme/silme dönüşünde liste baştan yüklenir: kayıt silinmiş ya da
  /// tarihi değişip başka aya taşınmış olabilir; yüklenmiş sayfaları yamamak
  /// yerine sıfırdan okumak hem kısa hem hatasız.
  Future<void> _reload() async {
    setState(() {
      _sessions.clear();
      _hasMore = true;
      _initialLoaded = false;
    });
    await _loadMore();
  }

  Future<void> _openSession(WorkoutSession session) async {
    if (session.id == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActiveWorkoutPage(editSessionId: session.id),
      ),
    );
    if (!mounted) return;
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Antrenman Geçmişi',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (!_initialLoaded) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.volt));
    }
    if (_sessions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'Henüz kayıtlı antrenmanın yok.\nİlk antrenmanını kaydettiğinde burada görünecek.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
      );
    }

    // Liste, oturumlar ve araya giren ay başlıklarından oluşan düz bir
    // widget dizisine açılıyor; ayrım her ayın İLK kaydından önce yapılır.
    final entries = _buildEntries();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      itemCount: entries.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= entries.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child:
                Center(child: CircularProgressIndicator(color: AppColors.volt)),
          );
        }
        return entries[index];
      },
    );
  }

  List<Widget> _buildEntries() {
    final widgets = <Widget>[];
    int? lastMonthKey;

    for (final session in _sessions) {
      final date = DateTime.parse(session.date);
      final monthKey = date.year * 100 + date.month;

      if (monthKey != lastMonthKey) {
        lastMonthKey = monthKey;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 10),
          child: Text(
            '${turkishMonths[date.month - 1]} ${date.year}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ));
      }

      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: RecentSessionTile(
          session: session,
          onTap: () => _openSession(session),
        ),
      ));
    }
    return widgets;
  }
}
