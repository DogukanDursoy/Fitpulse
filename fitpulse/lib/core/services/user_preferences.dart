import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  static const _keyOnboarding = 'has_completed_onboarding';
  static const _keyName = 'user_name';
  static const _keyWeight = 'user_weight';
  static const _keyHeight = 'user_height';
  static const _keyLevel = 'user_level';
  static const _keyGender = 'user_gender';
  static const _keyGoal = 'user_weekly_goal';
  static const _keyImage = 'user_image_path';

  Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboarding) ?? false;
  }

  Future<void> setCompletedOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboarding, value);
  }

  // Cinsiyete göre çizgifilmsel ve sade vector avatarlar atıyoruz
  Future<void> saveDetailedUserInfo({
    required String name,
    required String weight,
    required String height,
    required String level,
    required String gender,
    required String weeklyGoal,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // DiceBear üzerinden çizgifilmsel, modern ve sade vector avatar linkleri (PNG formatında)
    String defaultAvatar = gender == 'Kadın'
        ? 'https://api.dicebear.com/7.x/avataaars/png?seed=Aylin&backgroundColor=ffdfbf'
        : 'https://api.dicebear.com/7.x/avataaars/png?seed=Sumpay&backgroundColor=b6e3f4';

    await prefs.setString(_keyName, name);
    await prefs.setString(_keyWeight, weight);
    await prefs.setString(_keyHeight, height);
    await prefs.setString(_keyLevel, level);
    await prefs.setString(_keyGender, gender);
    await prefs.setString(_keyGoal, weeklyGoal);
    await prefs.setString(_keyImage, defaultAvatar);
  }

  Future<void> saveUserInfo(String name, String imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    if (imagePath.isNotEmpty) {
      await prefs.setString(_keyImage, imagePath);
    }
  }

  // Profil sayfasından toplu güncelleme yapmak için
  Future<void> updateProfileSettings({
    required String name,
    required String height,
    required String weeklyGoal,
    required String weight,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyHeight, height);
    await prefs.setString(_keyGoal, weeklyGoal);
    await prefs.setString(_keyWeight, weight);
    // Kilonun anlık görünümü burada güncellenir, geçmişi ise SQLite'ta tutulur.
  }

  Future<Map<String, String>> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName) ?? 'Şampiyon',
      'weight': prefs.getString(_keyWeight) ?? '75',
      'height': prefs.getString(_keyHeight) ?? '175',
      'level': prefs.getString(_keyLevel) ?? 'Orta',
      'gender': prefs.getString(_keyGender) ?? 'Erkek',
      'goal': prefs.getString(_keyGoal) ?? '4',
      'image': prefs.getString(_keyImage) ??
          'https://api.dicebear.com/7.x/avataaars/png?seed=Sumpay&backgroundColor=b6e3f4',
    };
  }
}
