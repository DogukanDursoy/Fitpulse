import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fitpulse/data/local/exercise_catalog.dart';
import 'package:fitpulse/features/stats/presentation/widgets/muscle_heatmap.dart';

// SVG asset'i gerçek dosyadan okunduğu için pumpAndSettle yerine runAsync
// kullanıyoruz; ayrıca yükleme göstergesi sonsuz animasyon olduğundan
// pumpAndSettle zaten hiçbir zaman oturmaz.
Future<void> _pumpHeatmap(
    WidgetTester tester, Map<String, double> volumes) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          // Gerçek kullanımdaki gibi kaydırılabilir bir listenin içinde:
          // yükseklik serbest, genişlik sınırlı.
          body: ListView(children: [MuscleHeatmap(volumes: volumes)]),
        ),
      ),
    );
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump();
    }
  });
}

void main() {
  testWidgets('kas haritası boyanmış SVG ile hatasız çizilir',
      (WidgetTester tester) async {
    await _pumpHeatmap(tester, {
      'Göğüs': 4200,
      'Ön Omuz': 2800,
      'Arka Kol': 1600,
      'Kanat': 900,
    });

    expect(tester.takeException(), isNull);
    // Yükleme bittiyse SVG çizilmiş ve etiketler görünür demektir
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('ÖN'), findsOneWidget);
    expect(find.text('ARKA'), findsOneWidget);
  });

  testWidgets('veri yokken harita ham haliyle çizilir',
      (WidgetTester tester) async {
    await _pumpHeatmap(tester, const {});
    expect(tester.takeException(), isNull);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  test('ısı skalası mavi ile kırmızı arasında ilerler', () {
    expect(MuscleHeatmapColors.heatHex(0), '#2563eb');
    expect(MuscleHeatmapColors.heatHex(1), '#ef4444');
    // Orta nokta tema rengi volt
    expect(MuscleHeatmapColors.heatHex(0.5), '#ccff00');
  });

  test('kas -> SVG eşleştirmesinde kimlik tekrarı yok', () {
    final all = MuscleGroups.svgPaths.values.expand((ids) => ids).toList();
    expect(all.length, all.toSet().length);
  });
}
