import 'package:sqflite/sqflite.dart';
import '../database_helper.dart';
import '../../models/user_model.dart';

class UserDao {
  final dbHelper = DatabaseHelper.instance;

  // Yeni kullanıcı oluştur
  Future<int> createUser(User user) async {
    final db = await dbHelper.database;
    return await db.insert('Users', user.toMap());
  }

  // Kullanıcı kilosunu güncellediğinde tarihçeye ekle
  Future<int> addMetricsHistory(UserMetricsHistory metrics) async {
    final db = await dbHelper.database;
    return await db.insert('UserMetricsHistory', metrics.toMap());
  }

  // ANA SAYFA: Hedef Barı için en güncel kilo/yağ oranını getir
  Future<UserMetricsHistory?> getLatestMetrics(int userId) async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'UserMetricsHistory',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
      limit: 1, // Sadece en son girilen güncel veriyi çeker
    );

    if (maps.isNotEmpty) {
      return UserMetricsHistory.fromMap(maps.first);
    }
    return null;
  }
}
