import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/teacher_model.dart';
import '../models/student_model.dart';
import 'database_service.dart';


class AuthService {
  final DatabaseService _databaseService = DatabaseService();


  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }


  Future<void> signOut() async {
    try {
      
      
      


      
      
      


      print('Usuário deslogado com sucesso'); 
    } catch (e) {
      print('Erro ao deslogar: $e'); 
      throw Exception('Falha ao deslogar');
    }
  }


  Future<User?> registerUser({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    final db = await _databaseService.database;


    
    final existingUser = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );


    if (existingUser.isNotEmpty) {
      throw Exception('Email já cadastrado');
    }


    final hashedPassword = _hashPassword(password);


    
    final userId = await db.insert('users', {
      'name': name,
      'email': email,
      'password': hashedPassword,
      'phone': phone,
      'type': type,
      'isApproved': 0,
    });


    return await getUserById(userId);
  }


  Future<User?> login(String email, String password) async {
    final db = await _databaseService.database;
    final hashedPassword = _hashPassword(password);


    try {
      final result = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, hashedPassword],
      );


      if (result.isEmpty) {
        return null;
      }


      final user = await getUserById(result.first['id'] as int);


      if (user != null && !user.isApproved) {
        throw Exception('Seu cadastro ainda não foi aprovado');
      }
      return user;
    } catch (e) {
      print('Erro no login: $e');
      rethrow;
    }
  }


  Future<User?> getUserById(int id) async {
    final db = await _databaseService.database;


    final userData = await db.query('users', where: 'id = ?', whereArgs: [id]);


    if (userData.isEmpty) return null;


    final userMap = userData.first;
    final type = userMap['type'] as String;


    if (type == 'teacher') {
      return Teacher.fromMap(userMap);
    } else if (type == 'student') {
      final studentData = await db.query(
        'students',
        where: 'userId = ?',
        whereArgs: [id],
      );


      if (studentData.isNotEmpty) {
        return Student.fromMap({...userMap, ...studentData.first});
      }
    }


    return User.fromMap(userMap);
  }
}



