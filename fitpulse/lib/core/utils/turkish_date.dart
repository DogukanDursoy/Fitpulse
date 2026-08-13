/// Tarihlerin Türkçe kısa biçimi.
///
/// Projede `intl` bağımlılığı yok; ay adları elle tutuluyor. Liste birden fazla
/// ekranda gerektiği için tek yerde toplandı, aksi halde kopyaları zamanla
/// birbirinden ayrılır.
library;

const List<String> turkishShortMonths = [
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
  'Ara',
];

/// "12 Eki" — tarih bu yıla aitse yıl yazılmaz, eski kayıtlarda yazılır
/// ("12 Eki 2025"), böylece geçen yılın rekoru bu yılınmış gibi görünmez.
String formatShortDate(DateTime date, {DateTime? now}) {
  final label = '${date.day} ${turkishShortMonths[date.month - 1]}';
  final today = now ?? DateTime.now();
  return date.year == today.year ? label : '$label ${date.year}';
}
