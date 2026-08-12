import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Program kartlarının görselleri.
///
/// Kartlar eskiden Unsplash CDN'ine doğrudan link veriyordu. Bu üç sorun
/// üretiyordu: release build'de INTERNET izni olmadığı için hiçbir görsel
/// yüklenmiyordu, kullanıcının kendi şablonlarında görsel hiç yoktu (boş URL
/// NetworkImage'ı patlatıp detay sayfasını çökertiyordu), ve üçüncü taraf
/// URL'lerinin kalıcılığı garanti değildi.
///
/// Şimdi iki katman var:
///   1. Hazır şablonların fotoğrafı uygulamayla birlikte geliyor (asset).
///   2. Fotoğrafı olmayan her program — kullanıcının kendi şablonları —
///      etiketinden türetilen bir renk geçişi ve ikon alıyor.
/// Her iki durumda da ağ erişimi gerekmiyor.
abstract class ProgramVisuals {
  /// Hazır şablonların gömülü fotoğrafları.
  ///
  /// Fotoğraflar Unsplash'ten indirildi ve uygulamaya gömüldü; atıfları
  /// [photoCredits] altında, Profil > Krediler ekranında gösteriliyor.
  static const Map<String, String> _photoByTitle = {
    'Power Hypertrophy': 'assets/images/programs/power_hypertrophy.jpg',
    'Vicious HIIT Shred': 'assets/images/programs/vicious_hiit.jpg',
    'Deep Core Recovery': 'assets/images/programs/deep_core.jpg',
    '5x5 Heavy Barbell': 'assets/images/programs/heavy_barbell.jpg',
    'Sprint Intervals': 'assets/images/programs/sprint_intervals.jpg',
  };

  /// Programın gömülü fotoğrafı; yoksa `null` (o zaman gradyan kullanılır).
  static String? photoAsset(String title) => _photoByTitle[title];

  static bool hasPhoto(String title) => _photoByTitle.containsKey(title);

  // Etiket -> (üst renk, alt renk, ikon)
  static const Map<String, (Color, Color, IconData)> _byTag = {
    'STRENGTH': (Color(0xFF1F2E10), Color(0xFF0B1206), Icons.fitness_center),
    'CARDIO': (Color(0xFF3A1A12), Color(0xFF14080A), Icons.bolt),
    'FLEXIBILITY': (
      Color(0xFF12283A),
      Color(0xFF07131E),
      Icons.self_improvement
    ),
    // Kullanıcının kendi şablonları kas grubu etiketi alıyor
    'GÖĞÜS': (Color(0xFF2B1630), Color(0xFF100818), Icons.fitness_center),
    'SIRT': (Color(0xFF13263A), Color(0xFF07111E), Icons.rowing),
    'OMUZ': (Color(0xFF1B2140), Color(0xFF090C1C), Icons.accessibility_new),
    'KOL': (Color(0xFF33220F), Color(0xFF150E06), Icons.sports_martial_arts),
    'BACAK': (Color(0xFF102E28), Color(0xFF061512), Icons.directions_run),
    'CORE': (Color(0xFF2E2410), Color(0xFF141005), Icons.shield_outlined),
  };

  static const (Color, Color, IconData) _fallback =
      (Color(0xFF1B1F27), Color(0xFF0A0D12), Icons.fitness_center);

  static (Color, Color, IconData) _resolve(String tag) =>
      _byTag[tag.toUpperCase()] ?? _fallback;

  /// Fotoğrafsız programların kart zemini.
  static LinearGradient gradient(String tag) {
    final (top, bottom, _) = _resolve(tag);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [top, bottom],
    );
  }

  /// Etiketi anlatan ikon.
  static IconData icon(String tag) => _resolve(tag).$3;

  /// Kartın zeminini çizer: fotoğrafı varsa fotoğraf, yoksa gradyan + filigran.
  static Widget background(String title, String tag) {
    final asset = photoAsset(title);
    if (asset != null) {
      return Image.asset(asset, fit: BoxFit.cover);
    }
    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient(tag)),
      child: Center(
        child: Icon(icon(tag), size: 96, color: AppColors.volt.withValues(alpha: 0.10)),
      ),
    );
  }

  /// Gömülü fotoğrafların kaynakları.
  ///
  /// Unsplash License atıf zorunlu tutmuyor ama fotoğrafçıya kredi vermek
  /// doğrusu; Profil > Krediler ekranında gösteriliyor.
  ///
  /// [photographer] alanları HENÜZ DOLDURULMADI: elimizde yalnızca fotoğrafların
  /// indirildiği CDN adresleri var ve CDN adresinden fotoğrafçı adı türetilemez.
  /// unsplash.com'da [sourceId] ile arayıp isimleri buraya yazmak gerekiyor.
  static const List<({String program, String photographer, String sourceId})>
      photoCredits = [
    (
      program: 'Power Hypertrophy',
      photographer: '',
      sourceId: 'photo-1534438327276-14e5300c3a48'
    ),
    (
      program: 'Vicious HIIT Shred',
      photographer: '',
      sourceId: 'photo-1518611012118-696072aa579a'
    ),
    (
      program: 'Deep Core Recovery',
      photographer: '',
      sourceId: 'photo-1518310383802-640c2de311b2'
    ),
    (
      program: '5x5 Heavy Barbell',
      photographer: '',
      sourceId: 'photo-1517838277536-f5f99be501cd'
    ),
    (
      program: 'Sprint Intervals',
      photographer: '',
      sourceId: 'photo-1461896836934-ffe607ba8211'
    ),
  ];
}
