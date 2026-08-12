import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fitpulse/core/theme/app_theme.dart';
import 'package:fitpulse/data/local/exercise_catalog.dart';

/// Isı skalası: mavi -> camgöbeği -> volt -> turuncu -> kırmızı.
///
/// Haritadaki boyama ile istatistik ekranındaki skala çubuğu ve kas kartları
/// aynı fonksiyondan beslenir; skala değişirse üçü birden değişir.
abstract class MuscleHeatmapColors {
  static const List<List<int>> ramp = [
    [37, 99, 235], // #2563EB  düşük
    [6, 182, 212], // #06B6D4
    [204, 255, 0], // #CCFF00  tema rengi
    [245, 158, 11], // #F59E0B
    [239, 68, 68], // #EF4444  yüksek
  ];

  /// [t] 0..1 aralığında ısı oranı
  static String heatHex(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (ramp.length - 1);
    final index = scaled.floor().clamp(0, ramp.length - 2);
    final local = scaled - index;

    final from = ramp[index];
    final to = ramp[index + 1];
    final rgb = List.generate(
      3,
      (i) => (from[i] + (to[i] - from[i]) * local).round().clamp(0, 255),
    );

    return '#${rgb.map((c) => c.toRadixString(16).padLeft(2, '0')).join()}';
  }
}

/// Haftalık kas yoğunluğu haritası.
///
/// Tek SVG dosyasında ön ve arka model yan yana durduğu için ön/arka geçişine
/// gerek yok. Kas grubunun haftalık hacmi, o haftanın en yoğun kasına oranlanır
/// (0 -> mavi, 1 -> kırmızı) ve ilgili path'lerin fill değeri metin üzerinde
/// değiştirilerek boyanır.
class MuscleHeatmap extends StatefulWidget {
  /// Kas grubu adı -> haftalık hacim (kg)
  final Map<String, double> volumes;

  const MuscleHeatmap({super.key, required this.volumes});

  @override
  State<MuscleHeatmap> createState() => _MuscleHeatmapState();
}

class _MuscleHeatmapState extends State<MuscleHeatmap> {
  static const String _assetPath = 'assets/images/anatomy_muscle_map_v5.svg';

  // 73 KB'lık dosyayı her hafta değişiminde diskten okumamak için tek sefer yükle
  static Future<String>? _rawSvgFuture;

  String? _rawSvg;
  String? _paintedSvg;

  @override
  void initState() {
    super.initState();
    _rawSvgFuture ??= rootBundle.loadString(_assetPath);
    _rawSvgFuture!.then((svg) {
      if (!mounted) return;
      setState(() {
        _rawSvg = svg;
        _paintedSvg = _paint(svg, widget.volumes);
      });
    });
  }

  @override
  void didUpdateWidget(covariant MuscleHeatmap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_rawSvg != null && !_sameVolumes(oldWidget.volumes, widget.volumes)) {
      _paintedSvg = _paint(_rawSvg!, widget.volumes);
    }
  }

  bool _sameVolumes(Map<String, double> a, Map<String, double> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  String _paint(String svg, Map<String, double> volumes) {
    if (volumes.isEmpty) return svg;

    final maxVolume = volumes.values.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxVolume <= 0) return svg;

    var result = svg;
    volumes.forEach((muscle, volume) {
      final paths = MuscleGroups.svgPaths[muscle];
      if (paths == null || volume <= 0) return;

      // Çalışılan her kas en az bir miktar görünür olsun diye 0.12'lik taban
      final ratio = 0.12 + (volume / maxVolume) * 0.88;
      final hex = MuscleHeatmapColors.heatHex(ratio);
      final opacity = (0.45 + ratio * 0.5).toStringAsFixed(2);

      for (final id in paths) {
        result = _applyStyle(result, id, hex, opacity);
      }
    });

    return result;
  }

  // İlgili path etiketinin fill / fill-opacity / stroke değerlerini değiştirir.
  // Path'ler self-closing olduğu ve 'd' verisi '/' içermediği için '/>' güvenli bir sınır.
  static String _applyStyle(
      String svg, String id, String hex, String opacity) {
    final start = svg.indexOf('id="$id"');
    if (start == -1) return svg;

    final end = svg.indexOf('/>', start);
    if (end == -1) return svg;

    final painted = svg
        .substring(start, end)
        .replaceFirst(RegExp(r'fill="[^"]*"'), 'fill="$hex"')
        .replaceFirst(RegExp(r'fill-opacity="[^"]*"'), 'fill-opacity="$opacity"')
        .replaceFirst(RegExp(r'stroke="[^"]*"'), 'stroke="$hex"');

    return svg.replaceRange(start, end, painted);
  }

  @override
  Widget build(BuildContext context) {
    if (_paintedSvg == null) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: AppColors.volt)),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 927 / 869, // SVG'nin kendi viewBox oranı
          child: SvgPicture.string(
            _paintedSvg!,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 8),
        // Toggle kalktığı için hangi modelin ne olduğunu buradan belirtiyoruz
        const Row(
          children: [
            Expanded(
              child: Text('ÖN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
            ),
            Expanded(
              child: Text('ARKA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5)),
            ),
          ],
        ),
      ],
    );
  }
}
