import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kullanıcının profil görseli.
///
/// Avatarlar eskiden api.dicebear.com'dan çekiliyordu; bu hem release build'de
/// INTERNET izni olmadığı için çalışmıyordu, hem de üçüncü taraf bir ücretsiz
/// servise bağımlılık yaratıyordu. Artık isimden türetilen bir baş harf
/// rozeti çiziliyor: ağ yok, asset yok, lisans sorusu yok.
///
/// Kullanıcı ileride galeriden fotoğraf seçerse [imagePath] o dosyayı gösterir;
/// dosya okunamıyorsa sessizce baş harfe düşer.
class UserAvatar extends StatelessWidget {
  final String name;
  final String? imagePath;
  final double radius;

  const UserAvatar({
    super.key,
    required this.name,
    this.imagePath,
    this.radius = 24,
  });

  /// Ada göre sabit bir renk: aynı isim her ekranda aynı rengi alır.
  static Color _colorFor(String name) {
    const palette = [
      Color(0xFF3B6EA5),
      Color(0xFF7A4FA3),
      Color(0xFFA3564F),
      Color(0xFF2F7F6B),
      Color(0xFF8A6D2F),
      Color(0xFF4F5FA3),
    ];
    if (name.isEmpty) return palette.first;
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7FFFFFFF;
    }
    return palette[hash % palette.length];
  }

  /// İlk iki kelimenin baş harfleri ("Doğukan Dursoy" -> "DD").
  static String initialsFor(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first.characters.first.toUpperCase();
    return (words[0].characters.first + words[1].characters.first)
        .toUpperCase();
  }

  // Yerel dosya yalnızca gerçekten varsa gösterilir; yoksa baş harfe düşeriz
  File? get _localImage {
    final path = imagePath?.trim();
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http')) return null; // eski DiceBear kayıtları
    final uri = Uri.tryParse(path);
    final file =
        File(uri != null && uri.scheme == 'file' ? uri.toFilePath() : path);
    return file.existsSync() ? file : null;
  }

  @override
  Widget build(BuildContext context) {
    final file = _localImage;
    if (file != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage: FileImage(file),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: _colorFor(name),
      child: Text(
        initialsFor(name),
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.72,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
