import 'package:flutter/material.dart';

/// Rozetlerin hesabına giren ham sayılar.
///
/// Hepsi mevcut kayıtlardan türetiliyor; rozetler için ayrı bir tablo YOK.
/// Bu bilinçli: rozet durumu veritabanında saklansaydı, kullanıcı bir
/// antrenmanı sildiğinde hak etmediği rozet üstünde kalırdı. Türetilmiş
/// olduğu için kendi kendini düzeltiyor.
///
/// Bedeli: "az önce şu rozeti kazandın" anı ve kazanma tarihi yok. İkisi de
/// sonradan, bu yapıyı bozmadan eklenebilir.
class AchievementStats {
  /// Haftalık hedefin üst üste tutturulduğu hafta sayısı
  final int weeklyGoalStreak;

  /// Tüm zamanların toplam tonajı (kg)
  final double totalVolume;

  /// Kaydedilmiş antrenman sayısı
  final int sessionCount;

  /// EN İYİ haftada dokunulan farklı kas grubu sayısı.
  /// Geçmişe bakılıyor, o yüzden hiç azalmıyor.
  final int bestWeekMuscleGroups;

  /// Rekoru olan farklı compound hareket sayısı
  final int recordedCompoundLifts;

  const AchievementStats({
    this.weeklyGoalStreak = 0,
    this.totalVolume = 0,
    this.sessionCount = 0,
    this.bestWeekMuscleGroups = 0,
    this.recordedCompoundLifts = 0,
  });
}

/// Tek bir rozetin o anki durumu.
class Achievement {
  final String title;
  final IconData icon;

  /// 0 = henüz kazanılmadı, 1..[maxTier] = kazanılan kademe
  final int tier;
  final int maxTier;

  /// Kazanıldıysa ulaşılan değer ("50 antrenman"), kazanılmadıysa hedefe
  /// ne kadar kaldığı ("3/10 antrenman").
  final String label;

  const Achievement({
    required this.title,
    required this.icon,
    required this.tier,
    required this.maxTier,
    required this.label,
  });

  bool get isEarned => tier > 0;
  bool get isMaxed => tier == maxTier;
}

/// Bir ölçütün kademe eşikleri ve nasıl yazıldığı.
class _Badge {
  final String title;
  final IconData icon;
  final List<num> thresholds;
  final String Function(num value) format;

  const _Badge(this.title, this.icon, this.thresholds, this.format);

  Achievement evaluate(num value) {
    var tier = 0;
    for (final threshold in thresholds) {
      if (value >= threshold) tier++;
    }

    // Kazanılmadıysa bir sonraki eşiği göster; en üst kademedeyse ulaşılan
    // değeri. Aradaki kademelerde de hedef göstermek ilerlemeyi görünür tutuyor.
    final label = tier == thresholds.length
        ? format(value)
        : '${format(value)} / ${format(thresholds[tier])}';

    return Achievement(
      title: title,
      icon: icon,
      tier: tier,
      maxTier: thresholds.length,
      label: label,
    );
  }
}

String _plainCount(num value) => value.round().toString();

/// 800 -> "800 kg", 12400 -> "12.4 ton", 120000 -> "120 ton"
///
/// Ondalık yalnızca 100 tonun altında: erken aşamada 0.1 tonluk fark görünür
/// olsun ama üç haneli sayılar "120.0 ton" diye şişmesin.
String _tonnage(num value) {
  if (value < 1000) return '${value.round()} kg';
  final tons = value / 1000;
  return '${tons.toStringAsFixed(tons < 100 ? 1 : 0)} ton';
}

/// Rozetler ve eşikleri.
///
/// Eşikler kabaca "birkaç hafta / birkaç ay / bir yıla yakın" düzeninde:
/// ilki yeni başlayanın birkaç haftada görebileceği, sonuncusu gerçekten
/// emek isteyen bir yerde dursun diye.
final List<_Badge> _badges = [
  _Badge('Seri', Icons.local_fire_department, const [2, 4, 12],
      (value) => '${_plainCount(value)} hafta'),
  // Tek const olan bu: diğerlerinin biçimlendiricisi lambda, const olamıyor
  const _Badge(
      'Tonaj', Icons.fitness_center, [10000, 50000, 100000], _tonnage),
  _Badge('Sadakat', Icons.event_available, const [10, 50, 100],
      (value) => '${_plainCount(value)} antrenman'),
  _Badge('Denge', Icons.donut_large, const [4, 5, 6],
      (value) => '${_plainCount(value)} kas grubu'),
  _Badge('Güç', Icons.trending_up, const [1, 3, 6],
      (value) => '${_plainCount(value)} hareket'),
];

/// Ham sayılardan rozet listesini üretir. Saf fonksiyon — veritabanına
/// dokunmuyor, o yüzden doğrudan test edilebiliyor.
List<Achievement> buildAchievements(AchievementStats stats) {
  final values = <num>[
    stats.weeklyGoalStreak,
    stats.totalVolume,
    stats.sessionCount,
    stats.bestWeekMuscleGroups,
    stats.recordedCompoundLifts,
  ];

  final result = [
    for (var i = 0; i < _badges.length; i++) _badges[i].evaluate(values[i]),
  ];

  // Kazanılanlar öne, aralarında ileri kademe önce; kazanılmayanlar arkada
  // ama silinmiyor — hedefi görmek kazanılmış rozet kadar değerli.
  result.sort((a, b) => b.tier.compareTo(a.tier));
  return result;
}

/// "Denge" rozetinin en üst kademesi "tüm kas gruplarına dokun" demek, yani
/// eşiği kategori sayısıyla aynı olmak zorunda. Kategori listesi büyürse
/// rozetin üst kademesi sessizce ulaşılabilir kalır; test bunu yakalıyor.
int get balanceBadgeTopThreshold => _badges[3].thresholds.last.toInt();
