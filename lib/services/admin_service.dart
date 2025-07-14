import 'package:sqflite/sqflite.dart';
import 'database_service.dart';


class AdminService {
  final DatabaseService _databaseService = DatabaseService();


  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final Database db = await _databaseService.database;
    return await db.query('users', where: 'isApproved = 0');
  }


  Future<bool> approveUser(int userId) async {
    final Database db = await _databaseService.database;
    final int updatedRows = await db.update(
      'users',
      {'isApproved': 1},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return updatedRows > 0;
  }


  Future<bool> rejectUser(int userId) async {
    final Database db = await _databaseService.database;
    final int deletedRows = await db.delete(
      'users',
      where: 'id = ? AND isApproved = 0',
      whereArgs: [userId],
    );
    return deletedRows > 0;
  }
}



