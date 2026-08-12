/// Kullanıcının elle girdiği ölçüleri (kilo, boy, haftalık hedef) çözer ve
/// makul aralıkta olup olmadıklarını doğrular.
///
/// Neden ortak bir yer: `double.tryParse` Türkçe klavyeden gelen "72,5" gibi
/// girdileri çözemez ve null döner. Çağrı yerlerindeki `?? 0` / `?? 75` gibi
/// varsayılanlar bu null'u sessizce anlamsız bir sayıya çevirip kilo geçmişine,
/// hacim hesabına ve e1RM'e taşıyordu. Parse ve doğrulama tek noktada toplandı
/// ki her ekran aynı kuralı uygulasın.
library;

/// Ondalık ayırıcı olarak hem virgül hem nokta kabul edilir.
/// Çözülemeyen girdide `null` döner — çağıran taraf varsayılana düşmek yerine
/// kullanıcıyı uyarmalıdır.
double? parseDecimalInput(String? raw) {
  final text = raw?.trim().replaceAll(',', '.');
  if (text == null || text.isEmpty) return null;
  final value = double.tryParse(text);
  if (value == null || !value.isFinite) return null;
  return value;
}

// Doğrulama aralıkları: amaç tıbbi kesinlik değil, saçma girdiyi (0, eksi
// değer, parmak kayması sonucu 750) veritabanına sokmamak.
const double minWeightKg = 20;
const double maxWeightKg = 400;
const double minHeightCm = 80;
const double maxHeightCm = 260;
const int minWeeklyGoal = 1;
const int maxWeeklyGoal = 7;

/// Geçerli bir kilo değeri ya da `null`.
double? parseWeightKg(String? raw) {
  final value = parseDecimalInput(raw);
  if (value == null || value < minWeightKg || value > maxWeightKg) return null;
  return value;
}

/// Geçerli bir boy değeri ya da `null`.
double? parseHeightCm(String? raw) {
  final value = parseDecimalInput(raw);
  if (value == null || value < minHeightCm || value > maxHeightCm) return null;
  return value;
}

/// Haftada kaç gün antrenman hedefi; 1-7 dışındaki her şey `null`.
int? parseWeeklyGoal(String? raw) {
  final value = parseDecimalInput(raw);
  if (value == null || value != value.roundToDouble()) return null;
  final days = value.toInt();
  if (days < minWeeklyGoal || days > maxWeeklyGoal) return null;
  return days;
}

// --- Form doğrulayıcıları (TextFormField.validator ile birebir uyumlu) ---

String? validateWeight(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Kilonu gir';
  if (parseWeightKg(raw) == null) {
    return '${minWeightKg.toInt()}-${maxWeightKg.toInt()} kg arası bir sayı gir';
  }
  return null;
}

String? validateHeight(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Boyunu gir';
  if (parseHeightCm(raw) == null) {
    return '${minHeightCm.toInt()}-${maxHeightCm.toInt()} cm arası bir sayı gir';
  }
  return null;
}

String? validateWeeklyGoal(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Haftalık hedefini gir';
  if (parseWeeklyGoal(raw) == null) {
    return 'Haftada $minWeeklyGoal-$maxWeeklyGoal gün arası bir sayı gir';
  }
  return null;
}

/// Hedef kilo boş bırakılabilir; girildiyse kilo kurallarına tabidir.
String? validateOptionalTargetWeight(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return validateWeight(raw);
}

/// Doğrulanmış sayıyı kayıt için tek biçime sokar ("72,5" -> "72.5"),
/// böylece SharedPreferences'a her zaman geri okunabilir bir metin yazılır.
String formatMeasurement(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : value.toString();
