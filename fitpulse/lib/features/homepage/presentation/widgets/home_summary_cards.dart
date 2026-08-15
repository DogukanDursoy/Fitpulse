import 'package:flutter/material.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/data/models/workout_model.dart';

/// Ana sayfadaki üç özet kartı. HomePage'den ayrıldılar: hepsi salt
/// gösterim — veriyi parametre olarak alırlar, kendileri sorgu açmazlar.

// HAFTALIK HEDEF VE SERİ KARTI
//
// Adım sayacının yerini aldı. Halka bu haftanın hedefe göre doluluğu,
// sağdaki büyük sayı ise üst üste kaç haftadır hedefin tutturulduğu.
class WeeklyStreakCard extends StatelessWidget {
  /// Bu hafta antrenman yapılan gün sayısı
  final int done;
  final int weeklyGoal;

  /// Haftalık hedefin üst üste kaç haftadır tutturulduğu
  final int streak;

  const WeeklyStreakCard({
    super.key,
    required this.done,
    required this.weeklyGoal,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final goal = weeklyGoal > 0 ? weeklyGoal : 1;
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
                  streak > 0 ? '$streak HAFTALIK SERİ' : 'Seri Bekliyor',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  streak > 0
                      ? 'Üst üste $streak haftadır haftalık hedefini tutturuyorsun.'
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
}

// GELİŞİM KARTI: son 14 gün ile önceki 14 günün compound e1RM kıyası.
class StrengthProgressCard extends StatelessWidget {
  final StrengthProgress? progress;

  const StrengthProgressCard({super.key, required this.progress});

  /// Karttaki yüzdenin neyi ölçtüğünü anlatan, kapatılabilir bilgi kutusu.
  /// Formül kullanıcıya görünmeyen kararlar içeriyor (en iyi set, iki dönemde
  /// de yapılmış hareketler); sayının güveni bu kararların bilinmesine bağlı.
  void _showInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Gelişim nasıl hesaplanır?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'Son 14 gün, ondan önceki 14 günle karşılaştırılır.\n\n'
          'Her bileşik hareket (squat, bench, deadlift gibi) için dönemin '
          'en iyi setinden tahmini tek tekrar maksimumun (e1RM) hesaplanır; '
          'girdiğin kilo, tekrar ve RPE birlikte değerlendirilir.\n\n'
          'Yalnızca iki dönemde de yaptığın hareketler kıyaslanır — program '
          'değiştirmek sonucu bozmaz. Yüzde, bu hareketlerdeki değişimlerin '
          'ortalamasıdır; karttaki "x harekete göre" notu kıyasa kaç hareketin '
          'girdiğini söyler.\n\n'
          'Dinlenme (deload) haftalarında yüzdenin düşmesi normaldir.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat',
                style: TextStyle(
                    color: AppColors.volt, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      subtitle = '${progress!.comparedLifts} harekete göre';
    }

    return GestureDetector(
      onTap: () => _showInfo(context),
      child: _SummaryCardShell(
        label: 'GELİŞİM',
        showInfoHint: true,
        icon: Icon(
          isDown ? Icons.trending_down : Icons.trending_up,
          color: isUp ? AppColors.volt : AppColors.textSecondary,
          size: 18,
        ),
        value: hasResult
            ? '${percent >= 0 ? '+' : '−'}%${percent.abs().toStringAsFixed(1)}'
            : '—',
        valueColor: isUp ? AppColors.volt : Colors.white,
        caption: hasResult ? 'son 14 günde' : subtitle,
        footnote: hasResult ? subtitle : null,
      ),
    );
  }
}

// FORM KARTI: başlangıç kilosundan hedef kiloya giden yolun ne kadarı bitti.
//
// Yön sorununu bu formül kendiliğinden çözüyor: kilo vermek de almak da
// "hedefe yaklaşmak" olarak ölçülüyor, ayrıca bir hedef türü sormaya gerek yok.
class WeightFormCard extends StatelessWidget {
  final double? firstWeight;
  final double? latestWeight;
  final double? targetWeight;

  const WeightFormCard({
    super.key,
    required this.firstWeight,
    required this.latestWeight,
    required this.targetWeight,
  });

  static String _formatWeight(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final first = firstWeight;
    final latest = latestWeight;
    final target = targetWeight;

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

    return _SummaryCardShell(
      label: 'FORM',
      icon: Icon(
        reached ? Icons.emoji_events : Icons.flag_outlined,
        color: completion != null && completion > 0
            ? AppColors.volt
            : AppColors.textSecondary,
        size: 18,
      ),
      value: value,
      valueColor: reached ? AppColors.volt : Colors.white,
      caption: caption,
      footnote: hasWeights
          ? (hasTarget
              ? '${_formatWeight(latest)} → ${_formatWeight(target)} kg hedef'
              : '${_formatWeight(first)} → ${_formatWeight(latest)} kg')
          : null,
    );
  }
}

/// Gelişim ve Form kartlarının ortak iskeleti: etiket + ikon, büyük değer,
/// açıklama ve isteğe bağlı dipnot. İki kartın görsel dili buradan tek
/// noktadan yönetiliyor.
class _SummaryCardShell extends StatelessWidget {
  final String label;
  final Widget icon;
  final String value;
  final Color valueColor;
  final String caption;
  final String? footnote;

  /// Etiketin yanına küçük bir (i) koyar: kartın dokununca bilgi
  /// göstereceğinin tek görünür işareti bu.
  final bool showInfoHint;

  const _SummaryCardShell({
    required this.label,
    required this.icon,
    required this.value,
    required this.valueColor,
    required this.caption,
    this.footnote,
    this.showInfoHint = false,
  });

  @override
  Widget build(BuildContext context) {
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
              Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (showInfoHint) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.info_outline,
                        color: AppColors.textSecondary, size: 13),
                  ],
                ],
              ),
              icon,
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
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
          if (footnote != null) ...[
            const SizedBox(height: 2),
            Text(
              footnote!,
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
}
