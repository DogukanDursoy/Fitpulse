# GainFit — Play yayın süreci devam notları

> Bu dosya Claude'un (ve Doğukan'ın) süreç notudur: geliştirici hesabı
> onaylandığında kaldığımız yerden buradan devam edilir.
> Son güncelleme: 15 Ağustos 2026.

## Şu anki durum (15.08.2026)

- ✅ Teknik hazırlık bitti: kimlik `com.dogukandursoy.gainfit`, ad GainFit,
  ikonlar, imzalama, güncel imzalı paket:
  `fitpulse/build/app/outputs/bundle/release/app-release.aab`
- ✅ Gizlilik politikası yayında:
  https://dogukandursoy.github.io/Fitpulse/privacy-policy.html
- ✅ Mağaza metinleri ve görseller hazır: bu klasördeki
  `PLAY_STORE_LISTING.md`, `icon_512.png`, `feature_graphic.png`
- ⬜ Geliştirici hesabı: **başvuru/onay bekleniyor** (25$, kimlik doğrulama)
- ⬜ Ekran görüntüleri: Doğukan telefondan alacak (2-6 dikey)
- ⬜ Anahtar yedeği: `android/upload-keystore.jks` + `android/key.properties`
  repo DIŞI bir yere kopyalanacak (sorulduğunda teyit et!)

## Hesap onaylanınca yapılacaklar (sırayla)

1. **Yedek teyidi:** keystore + key.properties yedeklendi mi? Yedeklenmediyse
   önce o.
2. **Paket tazeliği:** Son commit'ten sonra kod değiştiyse `.aab`'yi yeniden al:
   `flutter build appbundle` (cwd: fitpulse/). Sürüm değişecekse önce
   pubspec.yaml `version: 1.0.0+1` → build numarasını artır (+2, +3...);
   Play aynı versionCode'u ikinci kez kabul etmez.
3. **Konsolda uygulama oluştur:** Ad GainFit, dil Türkçe, tür Uygulama,
   Ücretsiz.
4. **Mağaza kaydı:** `PLAY_STORE_LISTING.md`'deki metinleri ve bu klasördeki
   görselleri forma gir. Kategori: Sağlık ve Fitness.
5. **Uygulama içeriği formları:** gizlilik politikası URL'i (yukarıda),
   reklam YOK, Veri güvenliği = hiçbir veri toplanmıyor/paylaşılmıyor
   (cevaplar PLAY_STORE_LISTING.md'de), içerik derecelendirme anketi,
   hedef kitle 13+. Sağlık uygulaması beyanı sorulursa: veriler yalnızca
   cihazda, paylaşım yok.
6. **Kapalı test kanalı:** `.aab`'yi yükle, testçi e-posta listesini ekle
   (bireysel hesap şartı: konsolun yazdığı sayıda testçi — ~12-20 — ve
   **14 gün kesintisiz** kayıtlı kalmaları gerek), katılım linkini dağıt.
7. **14 gün sonra:** konsoldan üretim erişimi başvurusu → onaylanınca aynı
   `.aab` ile üretim sürümü aç → Google incelemesi (1-7 gün) → yayın.

## Bilinmesi gerekenler / tuzaklar

- `applicationId` mağazaya İLK yüklemeden sonra kalıcılaşır; değiştirme
  fikri varsa son an ilk yüklemeden öncesidir.
- Keystore kaybolursa: Play Console → upload key reset süreci (günler sürer).
  Parola `android/key.properties` içinde.
- `key.properties` olmayan makinede release debug anahtarına düşer — Play'e
  yüklenecek paket MUTLAKA bu makinede (veya key kopyalanmış makinede)
  derlenmeli. İmza kontrolü:
  `apksigner verify --print-certs <apk>` → SHA-256
  `9eec9424b402ea8ff12a8cc28407057712ce913db9b5e5e56b5aefbe66f8460c` olmalı.
- Testçiler uygulamayı Play'den indirir (APK elden dağıtılmaz); katılım
  linkine tıklayıp kabul etmeleri şart.
- Ekran görüntüsü minimumu 2; telefon ekran görüntüleri 16:9-9:16 aralığında
  olmalı, çerçeve/süs zorunlu değil.

## İlgili dosya konumları

| Ne | Nerede |
| --- | --- |
| İmzalı paket (.aab) | `fitpulse/build/app/outputs/bundle/release/app-release.aab` |
| Keystore + parola | `fitpulse/android/upload-keystore.jks`, `fitpulse/android/key.properties` (repoda YOK) |
| Mağaza metinleri | `fitpulse/store/PLAY_STORE_LISTING.md` |
| Görseller | `fitpulse/store/icon_512.png`, `fitpulse/store/feature_graphic.png` |
| Gizlilik politikası kaynağı | `docs/privacy-policy.html` (GitHub Pages: main → /docs) |
| İkon kaynağı | `fitpulse/assets/icon/` (üretim: `dart run flutter_launcher_icons`) |
