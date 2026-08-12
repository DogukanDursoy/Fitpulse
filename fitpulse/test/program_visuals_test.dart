import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fitpulse/core/theme/program_visuals.dart';
import 'package:fitpulse/core/widgets/user_avatar.dart';
import 'package:fitpulse/data/local/database_helper.dart';
import 'package:fitpulse/data/local/daos/workout_dao.dart';

/// Görsel katmanının ağdan koptuğunu doğrular.
///
/// Kart görselleri Unsplash CDN'ine, avatarlar da api.dicebear.com'a doğrudan
/// link veriyordu. Release build'de INTERNET izni olmadığı için hiçbiri
/// yüklenmiyordu; kullanıcının kendi şablonlarında image_url boş kaldığı için
/// de detay sayfası çöküyordu. Artık ikisi de koddan çiziliyor.
///
/// Bu testler bilerek widget çizmiyor: sqflite'ın gerçek async G/Ç'si Flutter'ın
/// sahte test saatiyle uyuşmuyor ve pumpAndSettle sonsuz dönen bir spinner'da
/// 10 dakika bekliyor. Kontrol edilecek mantık zaten saf fonksiyonlarda.
void main() {
  group('program görselleri', () {
    test('her etiket için gradyan ve ikon üretilir', () {
      const tags = [
        'STRENGTH',
        'CARDIO',
        'FLEXIBILITY',
        // Kullanıcı şablonlarının kas grubu etiketleri
        'GÖĞÜS',
        'SIRT',
        'OMUZ',
        'KOL',
        'BACAK',
        'CORE',
      ];
      for (final tag in tags) {
        expect(ProgramVisuals.gradient(tag).colors, hasLength(2),
            reason: '$tag için gradyan yok');
        expect(ProgramVisuals.icon(tag), isA<IconData>());
      }
    });

    test('tanınmayan etiket varsayılana düşer, çökmez', () {
      for (final tag in ['', 'ANTRENMAN', 'bilinmeyen', 'çok garip bir tag']) {
        expect(ProgramVisuals.gradient(tag).colors, hasLength(2));
        expect(ProgramVisuals.icon(tag), isA<IconData>());
      }
    });

    test('etiket büyük/küçük harften bağımsız çözülür', () {
      expect(ProgramVisuals.icon('strength'), ProgramVisuals.icon('STRENGTH'));
      expect(ProgramVisuals.icon('Bacak'), ProgramVisuals.icon('BACAK'));
    });
  });

  group('kullanıcı avatarı', () {
    test('baş harfler isimden türetilir', () {
      expect(UserAvatar.initialsFor('Doğukan'), 'D');
      expect(UserAvatar.initialsFor('Doğukan Dursoy'), 'DD');
      expect(UserAvatar.initialsFor('  ali  veli  '), 'AV');
      expect(UserAvatar.initialsFor('Şampiyon'), 'Ş');
    });

    test('boş isim çökmez', () {
      expect(UserAvatar.initialsFor(''), '?');
      expect(UserAvatar.initialsFor('   '), '?');
    });
  });

  group('tohum verisi', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    const dbName = 'program_visuals_test.db';

    setUp(() async {
      await DatabaseHelper.resetForTesting(databaseName: dbName);
      await deleteDatabase(join(await getDatabasesPath(), dbName));
    });

    tearDownAll(() async {
      await DatabaseHelper.resetForTesting();
    });

    // Release build'de INTERNET izni yok; tohum verisi dış URL taşırsa
    // kartlar yayınlanan uygulamada görselsiz kalır.
    test('hazır şablonlar dış görsel URL\'i taşımıyor', () async {
      final dao = WorkoutDao();
      await dao.seedWorkoutPrograms();

      final programs = await dao.getAllPrograms();
      expect(programs, hasLength(5));
      for (final program in programs) {
        expect(program.imageUrl, isEmpty,
            reason: '${program.title} hâlâ dış URL taşıyor');
      }
    });

    // Fotoğraflar artık uygulamaya gömülü. Bir şablonun karşılığı eksikse o
    // kart yayınlanan uygulamada sessizce gradyana düşer — testle yakalıyoruz.
    test('her hazır şablonun gömülü fotoğrafı var', () async {
      final dao = WorkoutDao();
      await dao.seedWorkoutPrograms();

      for (final program in await dao.getAllPrograms()) {
        expect(ProgramVisuals.photoAsset(program.title), isNotNull,
            reason: '${program.title} için gömülü fotoğraf tanımlı değil');
        expect(ProgramVisuals.photoAsset(program.title),
            startsWith('assets/images/programs/'));
      }
    });

    test('her fotoğrafın kredi kaydı var', () async {
      final dao = WorkoutDao();
      await dao.seedWorkoutPrograms();

      final credited =
          ProgramVisuals.photoCredits.map((c) => c.program).toSet();
      for (final program in await dao.getAllPrograms()) {
        expect(credited, contains(program.title),
            reason: '${program.title} Krediler ekranında görünmüyor');
      }
    });

    // Kullanıcının kendi şablonlarının fotoğrafı yok; gradyana düşmeli
    test('kullanıcı şablonu fotoğrafsız kalır, gradyan alır', () {
      expect(ProgramVisuals.photoAsset('Omuz Antrenmanı'), isNull);
      expect(ProgramVisuals.hasPhoto('Omuz Antrenmanı'), isFalse);
      expect(ProgramVisuals.gradient('OMUZ').colors, hasLength(2));
    });
  });
}
