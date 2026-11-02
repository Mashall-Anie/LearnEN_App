import 'package:sqflite/sqflite.dart';

import '../../models/user_profile.dart';

class UserRepository {
  UserRepository(this._db);

  final Database _db;

  Future<List<UserProfile>> getAll() async {
    final rows = await _db.query('users', orderBy: 'last_active_at DESC, id ASC');
    return rows.map(UserProfile.fromMap).toList();
  }

  Future<UserProfile?> getById(int id) async {
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : UserProfile.fromMap(rows.first);
  }

  Future<UserProfile> create(UserProfile user) async {
    final id = await _db.insert('users', user.toMap()..remove('id'));
    return user.copyWith(id: id);
  }

  Future<void> update(UserProfile user) =>
      _db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);

  Future<void> touch(int id, DateTime at) =>
      _db.update('users', {'last_active_at': at.toIso8601String()}, where: 'id = ?', whereArgs: [id]);

  /// Xóa người dùng – các bảng con được xóa theo nhờ ON DELETE CASCADE.
  Future<void> delete(int id) => _db.delete('users', where: 'id = ?', whereArgs: [id]);
}
